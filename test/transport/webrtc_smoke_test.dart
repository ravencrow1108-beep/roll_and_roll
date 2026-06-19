import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:roll_and_roll/data/services/transport/webrtc/peer_connection_manager.dart';
import 'package:roll_and_roll/data/services/transport/webrtc/ice_config.dart';
import 'package:roll_and_roll/data/services/transport/protocol/room_message.dart';

// ═══════════════════════════════════════════════════════════════
// Phase 1A — Windows Desktop WebRTC loopback smoke test.
//
// 目标：
//   验证真实 RTCPeerConnection + DataChannel + RoomMessage 链路。
//
// 运行方式：
//   flutter run -t test/transport/webrtc_smoke_test.dart -d windows
//
// 不依赖：
//   - Cloudflare Worker
//   - Durable Object
//   - socket_support.dart
//   - 任何 UI 页面
// ═══════════════════════════════════════════════════════════════

void main() {
  runApp(const WebRTCSmokeApp());
}

class WebRTCSmokeApp extends StatefulWidget {
  const WebRTCSmokeApp({super.key});

  @override
  State<WebRTCSmokeApp> createState() => _WebRTCSmokeAppState();
}

class _WebRTCSmokeAppState extends State<WebRTCSmokeApp> {
  final List<_StepResult> _steps = [];
  bool _running = false;
  String _status = 'Idle — press "Run Test"';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        appBar: AppBar(
          title: const Text('WebRTC Loopback Smoke Test'),
          centerTitle: true,
          backgroundColor: const Color(0xFF16213E),
        ),
        body: Column(
          children: [
            // Status bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF0F3460),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white70),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _running ? null : _runSmokeTest,
                    icon: _running
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(_running ? 'Running...' : 'Run Test'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Step list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _steps.length,
                itemBuilder: (context, i) => _StepTile(step: _steps[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Smoke test
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> _runSmokeTest() async {
    setState(() {
      _running = true;
      _steps.clear();
      _status = 'Initializing...';
    });

    PeerConnectionManager? hostMgr;
    PeerConnectionManager? clientMgr;

    // Collect host-side ICE candidates
    final hostIceCandidates = <Map<String, dynamic>>[];
    // Collect client-side ICE candidates
    final clientIceCandidates = <Map<String, dynamic>>[];
    // Client received messages
    final clientMessages = <RoomMessage>[];
    // Host received messages
    final hostMessages = <RoomMessage>[];

    StreamSubscription? clientMsgSub;
    StreamSubscription? hostMsgSub;

    try {
      // ── Step 1: Initialize WebRTC ──
      _addStep('Step 1', 'Initialize flutter_webrtc',
          'Checking platform support...');
      await Future.delayed(const Duration(milliseconds: 100));

      // flutter_webrtc may need initialization on some platforms
      _markStep(0, true, 'Platform ready');

      // ── Step 2: Create Host PeerConnectionManager ──
      _addStep('Step 2', 'Create Host PeerConnection + DataChannel',
          'Creating offer...');

      hostMgr = PeerConnectionManager(
        label: 'smoke_host',
        iceConfig: IceConfig.defaultConfig,
        onSignal: (signal) {
          if (signal['type'] == 'iceCandidate') {
            hostIceCandidates.add(signal);
          }
        },
      );

      final offer = await hostMgr.createOffer().timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('Host createOffer timed out'),
          );

      final offerLen = offer.sdp?.length ?? 0;
      _markStep(1, true, 'Offer created ($offerLen chars SDP)');

      // ── Step 3: Create Client PeerConnectionManager ──
      _addStep('Step 3', 'Create Client PeerConnection',
          'Setting remote description + creating answer...');

      clientMgr = PeerConnectionManager(
        label: 'smoke_client',
        iceConfig: IceConfig.defaultConfig,
        onSignal: (signal) {
          if (signal['type'] == 'iceCandidate') {
            clientIceCandidates.add(signal);
          }
        },
      );

      // Listen to client messages
      clientMsgSub = clientMgr.messages.listen((msg) {
        clientMessages.add(msg);
      });

      // Track client connection state
      final clientConnected = Completer<void>();
      clientMgr.onConnectionChanged.listen((connected) {
        if (connected && !clientConnected.isCompleted) {
          clientConnected.complete();
        }
      });

      final answer = await clientMgr.acceptOffer(offer).timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('Client acceptOffer timed out'),
          );

      final answerLen = answer.sdp?.length ?? 0;
      _markStep(2, true, 'Answer created ($answerLen chars SDP)');

      // ── Step 4: Set remote answer on Host ──
      _addStep('Step 4', 'Host setRemoteDescription(answer)',
          'Completing SDP handshake...');

      await hostMgr.setRemoteAnswer(answer).timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('setRemoteAnswer timed out'),
          );

      _markStep(3, true, 'Remote description set on host');

      // ── Step 5: Exchange ICE candidates ──
      _addStep('Step 5', 'Exchange ICE candidates',
          'Gathering and exchanging candidates...');

      // Wait briefly for ICE candidates to be generated
      await Future.delayed(const Duration(seconds: 2));

      // Add all host candidates to client
      for (final ice in hostIceCandidates) {
        await clientMgr.addRemoteCandidate(
          RTCIceCandidate(
            ice['candidate'] as String,
            ice['sdpMid'] as String?,
            ice['sdpMLineIndex'] as int?,
          ),
        );
      }

      // Add all client candidates to host
      for (final ice in clientIceCandidates) {
        await hostMgr.addRemoteCandidate(
          RTCIceCandidate(
            ice['candidate'] as String,
            ice['sdpMid'] as String?,
            ice['sdpMLineIndex'] as int?,
          ),
        );
      }

      _markStep(4, true,
          'ICE exchanged: host=${hostIceCandidates.length}, client=${clientIceCandidates.length}');

      // ── Step 6: Wait for DataChannel OPEN ──
      _addStep('Step 6', 'Wait for DataChannel OPEN',
          'Waiting for connection...');

      // Host-side DataChannel should open
      final hostConnected = Completer<void>();
      final hostConnSub = hostMgr.onConnectionChanged.listen((connected) {
        if (connected && !hostConnected.isCompleted) {
          hostConnected.complete();
        }
      });

      // Listen to host messages
      hostMsgSub = hostMgr.messages.listen((msg) {
        hostMessages.add(msg);
      });

      try {
        await clientConnected.future.timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw Exception(
            'DataChannel did not open within 20s. '
            'Check that STUN is reachable (stun.l.google.com:19302).',
          ),
        );
      } finally {
        await hostConnSub.cancel();
      }

      // Give host side a moment too
      if (!hostMgr.connected) {
        await hostConnected.future.timeout(
          const Duration(seconds: 3),
          onTimeout: () => null, // host might open slightly after client
        );
      }

      final clientOpen = clientMgr.connected;
      final hostOpen = hostMgr.connected;

      _markStep(5, clientOpen && hostOpen,
          'Host: ${hostOpen ? 'OPEN' : 'NOT OPEN'}, Client: ${clientOpen ? 'OPEN' : 'NOT OPEN'}');

      if (!clientOpen) {
        throw Exception('Client DataChannel did not reach OPEN state');
      }

      // ── Step 7: Send chat message Host → Client ──
      _addStep('Step 7', 'Send RoomMessage(chat) Host → Client',
          'Sending chat message...');

      final chatMsg = RoomMessage.create(
        type: RoomMessage.chat,
        senderId: 'host',
        payload: {'text': 'Hello from host!', 'isSystem': false},
      );

      await hostMgr.send(chatMsg);

      // Wait for client to receive
      await Future.delayed(const Duration(milliseconds: 500));

      final received = clientMessages
          .where((m) => m.messageId == chatMsg.messageId)
          .toList();
      final chatOk = received.length == 1 &&
          received[0].type == RoomMessage.chat &&
          received[0].payload['text'] == 'Hello from host!';

      _markStep(6, chatOk,
          chatOk ? 'Client received: "${received[0].payload['text']}"' : 'Client did NOT receive chat message');

      // ── Step 8: Send dice message Host → Client ──
      _addStep('Step 8', 'Send RoomMessage(dice) Host → Client',
          'Sending dice roll...');

      final diceMsg = RoomMessage.create(
        type: RoomMessage.dice,
        senderId: 'host',
        payload: {
          'expression': '2d6+3',
          'total': 10,
          'rolls': [4, 3],
        },
      );

      await hostMgr.send(diceMsg);
      await Future.delayed(const Duration(milliseconds: 500));

      final diceReceived = clientMessages
          .where((m) => m.messageId == diceMsg.messageId)
          .toList();
      final diceOk = diceReceived.length == 1 &&
          diceReceived[0].type == RoomMessage.dice &&
          diceReceived[0].payload['total'] == 10;

      _markStep(7, diceOk,
          diceOk ? 'Client received dice: 2d6+3 = 10' : 'Client did NOT receive dice message');

      // ── Step 9: Send message Client → Host ──
      _addStep('Step 9', 'Send RoomMessage(chat) Client → Host',
          'Testing bidirectional...');

      final clientChatMsg = RoomMessage.create(
        type: RoomMessage.chat,
        senderId: 'player1',
        payload: {'text': 'Hello back from client!'},
      );

      await clientMgr.send(clientChatMsg);
      await Future.delayed(const Duration(milliseconds: 500));

      final hostReceived = hostMessages
          .where((m) => m.messageId == clientChatMsg.messageId)
          .toList();
      final bidirOk = hostReceived.length == 1 &&
          hostReceived[0].type == RoomMessage.chat &&
          hostReceived[0].payload['text'] == 'Hello back from client!';

      _markStep(8, bidirOk,
          bidirOk ? 'Host received client message' : 'Bidirectional FAILED');

      // ── Step 10: Payload integrity ──
      _addStep('Step 10', 'Payload integrity check',
          'Verifying serialization...');

      // The full wire path: RoomMessage.toJson → jsonEncode → DataChannel → jsonDecode → RoomMessage.fromJson
      // Already validated in transport_test.dart; smoke test confirms it works over real DataChannel
      final firstChat = clientMessages.firstWhere(
        (m) => m.type == RoomMessage.chat,
      );
      final payloadOk = firstChat.version == 1 &&
          firstChat.messageId.isNotEmpty &&
          firstChat.timestamp > 0 &&
          firstChat.senderId == 'host';

      _markStep(9, payloadOk,
          'Envelope: v=${firstChat.version}, sender=${firstChat.senderId}, id=${firstChat.messageId.substring(0, 12)}...');

      // ── Final summary ──
      final allPassed = chatOk && diceOk && bidirOk && payloadOk && clientOpen;

      _addStep('RESULT', allPassed ? 'ALL TESTS PASSED' : 'SOME TESTS FAILED',
          allPassed
              ? 'WebRTC DataChannel + RoomMessage loopback verified'
              : 'Check failed steps above');

      _markStep(10, allPassed, '');

      setState(() {
        _status = allPassed ? '✅ ALL PASSED' : '❌ FAILURES DETECTED';
      });
    } catch (e, stack) {
      _addStep('ERROR', 'Unexpected error', '$e');
      _markStep(_steps.length - 1, false, '');
      setState(() {
        _status = '❌ ERROR: $e';
      });
      debugPrint('Smoke test error: $e\n$stack');
    } finally {
      await clientMsgSub?.cancel();
      await hostMsgSub?.cancel();
      await clientMgr?.close();
      await hostMgr?.close();
      setState(() => _running = false);
    }
  }

  void _addStep(String label, String title, String detail) {
    setState(() {
      _steps.add(_StepResult(
        label: label,
        title: title,
        detail: detail,
        passed: null,
      ));
    });
  }

  void _markStep(int index, bool passed, String detail) {
    setState(() {
      if (index < _steps.length) {
        _steps[index] = _steps[index].copyWith(passed: passed, detail: detail);
      }
    });
  }
}

// ─────────────────────────────────────────────────────────────
// Result model
// ─────────────────────────────────────────────────────────────

enum StepState { pending, pass, fail }

class _StepResult {
  final String label;
  final String title;
  final String detail;
  final bool? passed; // null = pending

  const _StepResult({
    required this.label,
    required this.title,
    required this.detail,
    this.passed,
  });

  _StepResult copyWith({bool? passed, String? detail}) => _StepResult(
        label: label,
        title: title,
        detail: detail ?? this.detail,
        passed: passed,
      );

  StepState get state =>
      passed == null ? StepState.pending : (passed! ? StepState.pass : StepState.fail);
}

// ─────────────────────────────────────────────────────────────
// Step tile widget
// ─────────────────────────────────────────────────────────────

class _StepTile extends StatelessWidget {
  final _StepResult step;
  const _StepTile({required this.step});

  @override
  Widget build(BuildContext context) {
    final icon = switch (step.state) {
      StepState.pending => Icons.schedule,
      StepState.pass => Icons.check_circle,
      StepState.fail => Icons.error,
    };
    final color = switch (step.state) {
      StepState.pending => Colors.orange,
      StepState.pass => Colors.green,
      StepState.fail => Colors.red,
    };

    return Card(
      color: const Color(0xFF16213E),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: ListTile(
        leading: Icon(icon, color: color, size: 28),
        title: Text(
          step.title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        subtitle: step.detail.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  step.detail,
                  style: TextStyle(
                    color: Colors.white.withAlpha(179),
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              )
            : null,
        trailing: Text(
          step.label,
          style: TextStyle(
            color: Colors.white.withAlpha(102),
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
