import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../lib/data/services/transport/webrtc/peer_connection_manager.dart';
import '../../lib/data/services/transport/webrtc/ice_config.dart';
import '../../lib/data/services/transport/protocol/room_message.dart';
import '../../lib/data/services/transport/protocol/signal_message.dart';
import '../../lib/data/services/transport/signaling/websocket_signaling.dart';

// ═══════════════════════════════════════════════════════════════
// Phase 1B — Cloudflare DO + WebRTC DataChannel 真实链路测试
//
// 验证完整链路：
//   HTTP /createRoom → WebSocket auth → SDP/ICE 信令 → DataChannel OPEN → RoomMessage
//
// 运行：
//   flutter run -t test/transport/cloudflare_signaling_test.dart -d windows
// ═══════════════════════════════════════════════════════════════

const workerHost = 'signal.roll-and-roll.com';
const workerUrl = 'https://$workerHost';

void main() => runApp(const CloudflareSignalingApp());

class CloudflareSignalingApp extends StatefulWidget {
  const CloudflareSignalingApp({super.key});
  @override
  State<CloudflareSignalingApp> createState() => _CloudflareSignalingAppState();
}

class _CloudflareSignalingAppState extends State<CloudflareSignalingApp> {
  final List<_Step> _steps = [];
  bool _running = false;
  String _status = 'Idle';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        appBar: AppBar(
          title: const Text('Cloudflare DO + WebRTC Smoke'),
          backgroundColor: const Color(0xFF16213E),
        ),
        body: Column(
          children: [
            _statusBar(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _steps.length,
                itemBuilder: (_, i) => _buildTile(_steps[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF0F3460),
      child: Row(
        children: [
          const Icon(Icons.cloud, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_status,
                style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
          ElevatedButton.icon(
            onPressed: _running ? null : _runTest,
            icon: _running
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.play_arrow),
            label: Text(_running ? 'Running...' : 'Run Test'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(_Step step) {
    final icon = step.passed == null
        ? Icons.schedule
        : step.passed! ? Icons.check_circle : Icons.error;
    final color = step.passed == null
        ? Colors.orange
        : step.passed! ? Colors.green : Colors.red;
    return Card(
      color: const Color(0xFF16213E),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: ListTile(
        leading: Icon(icon, color: color, size: 28),
        title: Text(step.title,
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: step.detail.isNotEmpty
            ? Text(step.detail,
                style: TextStyle(color: Colors.white.withAlpha(179), fontSize: 12))
            : null,
      ),
    );
  }

  void _add(String title, String detail) {
      debugPrint('  ➤ $title  $detail');
      setState(() => _steps.add(_Step(title: title, detail: detail)));
    }

  void _mark(int i, bool ok, String detail) {
      final icon = ok ? '✅' : '❌';
      debugPrint('    $icon $detail');
      setState(() => _steps[i] = _steps[i].copyWith(passed: ok, detail: detail));
    }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ════════════ TEST ════════════
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Future<void> _runTest() async {
    setState(() { _running = true; _steps.clear(); _status = 'Connecting...'; });

    HttpClient? http;
    WebSocketSignaling? hostSig, playerSig;
    PeerConnectionManager? hostMgr, clientMgr;
    String? roomId;
    String playerId = '';
    final hostIce = <Map<String, dynamic>>[];
    final clientIce = <Map<String, dynamic>>[];
    final clientMessages = <RoomMessage>[];
    StreamSubscription? clientMsgSub, hostMsgSub;

    try {
      // ── Step 1: HTTP 创建房间 ──
      _add('Step 1', 'POST /createRoom');
      http = HttpClient();
      final req = await http.postUrl(Uri.parse('$workerUrl/createRoom'));
      final resp = await req.close().timeout(const Duration(seconds: 15));
      final body = await resp.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;

      if (data['success'] != true) throw Exception('createRoom: $body');
      roomId = data['roomId'] as String;
      _mark(0, true, 'Room: $roomId');

      // ── Step 2: Host WebSocket auth ──
      _add('Step 2', 'Host → wss://$workerHost/room/$roomId');
      hostSig = WebSocketSignaling(
        workerUrl: workerUrl, roomId: roomId, role: 'host', name: 'GM');
      final hostAuthOk = Completer<void>();
      hostSig.signals.listen((s) { if (s.type == SignalMessage.authOk) hostAuthOk.complete(); });
      await hostSig.connect().timeout(const Duration(seconds: 15));
      await hostAuthOk.future.timeout(const Duration(seconds: 10));
      _mark(1, true, 'Host auth_ok');

      // ── Step 3: Player WebSocket auth ──
      _add('Step 3', 'Player → wss://$workerHost/room/$roomId');
      playerSig = WebSocketSignaling(
        workerUrl: workerUrl, roomId: roomId, role: 'player', name: 'Tester');
      final playerAuthOk = Completer<void>();
      final playerJoinedOk = Completer<void>();
      StreamSubscription? hostJoinSub;
      playerSig.signals.listen((s) {
        if (s.type == SignalMessage.authOk) {
          playerId = (s.payload['playerId'] as String?) ?? '';
          playerAuthOk.complete();
        }
      });
      hostJoinSub = hostSig.signals.listen((s) {
        if (s.type == 'player_joined') playerJoinedOk.complete();
      });
      await playerSig.connect().timeout(const Duration(seconds: 15));
      await playerAuthOk.future.timeout(const Duration(seconds: 10));
      await playerJoinedOk.future.timeout(const Duration(seconds: 10));
      await hostJoinSub.cancel();
      _mark(2, true, 'Player: $playerId');

      // ── Step 4: Host createOffer → DO → Player acceptAnswer ──
      _add('Step 4', 'SDP exchange via DO');

      // Host side
      final hSig = hostSig;
      hostMgr = PeerConnectionManager(
        label: 'cf_host',
        iceConfig: IceConfig.defaultConfig,
        onSignal: (sig) {
          if (sig['type'] == 'iceCandidate') {
            hostIce.add(sig);
            hSig.sendSignal(SignalMessage(
              type: SignalMessage.iceCandidate,
              payload: {
                'from': 'host',
                'playerId': playerId,
                'candidate': sig['candidate'],
                'sdpMid': sig['sdpMid'],
                'sdpMLineIndex': sig['sdpMLineIndex'],
              },
            ));
          }
        },
      );
      final offer = await hostMgr.createOffer().timeout(const Duration(seconds: 20));
      hSig.sendSignal(SignalMessage.createOffer(sdp: offer.sdp!, targetPlayerId: playerId));

      // Player receives offer
      final offerReceived = Completer<RTCSessionDescription>();
      final pSig = playerSig;
      final playerSigSub = pSig.signals.listen((s) {
        if (s.type == SignalMessage.offer) {
          final sdp = s.payload['sdp'] as String?;
          if (sdp != null && !offerReceived.isCompleted) {
            offerReceived.complete(RTCSessionDescription(sdp, 'offer'));
          }
        }
      });
      final remoteOffer = await offerReceived.future.timeout(const Duration(seconds: 15));
      await playerSigSub.cancel();

      // Player creates answer
      final cMgr = PeerConnectionManager(
        label: 'cf_player',
        iceConfig: IceConfig.defaultConfig,
        onSignal: (sig) {
          if (sig['type'] == 'iceCandidate') {
            clientIce.add(sig);
            pSig.sendSignal(SignalMessage(
              type: SignalMessage.iceCandidate,
              payload: {
                'from': 'player',
                'candidate': sig['candidate'],
                'sdpMid': sig['sdpMid'],
                'sdpMLineIndex': sig['sdpMLineIndex'],
              },
            ));
          }
        },
      );
      clientMgr = cMgr;
      clientMsgSub = cMgr.messages.listen(clientMessages.add);
      final clientConnOk = Completer<void>();
      cMgr.onConnectionChanged.listen((ok) {
        if (ok && !clientConnOk.isCompleted) clientConnOk.complete();
      });

      final answer = await cMgr.acceptOffer(remoteOffer).timeout(const Duration(seconds: 20));
      pSig.sendSignal(SignalMessage.createAnswer(sdp: answer.sdp!));

      // Host receives answer
      final answerReceived = Completer<void>();
      final hMgr = hostMgr;
      final hostSigSub = hSig.signals.listen((s) {
        if (s.type == SignalMessage.answer) {
          final sdp = s.payload['sdp'] as String?;
          if (sdp != null && !answerReceived.isCompleted) {
            hMgr.setRemoteAnswer(RTCSessionDescription(sdp, 'answer'));
            answerReceived.complete();
          }
        }
      });
      await answerReceived.future.timeout(const Duration(seconds: 15));
      _mark(3, true, 'Offer/Answer exchanged');

      // ── Step 5: ICE exchange via DO ──
      _add('Step 5', 'ICE candidates via DO');

      // Listen for player→host ICE through DO
      final cMgr2 = clientMgr;
      final hMgr2 = hostMgr;
      final iceRelaySub = hSig.signals.listen((s) {
        if (s.type == SignalMessage.iceCandidate && s.payload['from'] == 'player') {
          cMgr2.addRemoteCandidate(RTCIceCandidate(
            s.payload['candidate'] as String,
            s.payload['sdpMid'] as String?,
            s.payload['sdpMLineIndex'] as int?,
          ));
        }
      });

      // Wait for ICE gathering
      await Future.delayed(const Duration(seconds: 3));

      // Manually relay any ICE that was buffered
      for (final ice in hostIce) {
        cMgr2.addRemoteCandidate(RTCIceCandidate(
          ice['candidate'] as String,
          ice['sdpMid'] as String?,
          ice['sdpMLineIndex'] as int?,
        ));
      }
      for (final ice in clientIce) {
        hMgr2.addRemoteCandidate(RTCIceCandidate(
          ice['candidate'] as String,
          ice['sdpMid'] as String?,
          ice['sdpMLineIndex'] as int?,
        ));
      }

      await iceRelaySub.cancel();
      await hostSigSub.cancel();
      _mark(4, true, 'Host ICE: ${hostIce.length}, Client ICE: ${clientIce.length}');

      // ── Step 6: DataChannel OPEN ──
      _add('Step 6', 'DataChannel OPEN');

      hostMsgSub = hostMgr.onConnectionChanged.listen((ok) {
        if (ok) _mark(5, true, 'DataChannel OPEN');
      });

      await clientConnOk.future.timeout(const Duration(seconds: 30),
        onTimeout: () => throw Exception('DataChannel OPEN timeout (check STUN)'));
      _mark(5, hostMgr.connected && clientMgr.connected,
          'Host: ${hostMgr.connected}, Client: ${clientMgr.connected}');

      // ── Step 7: Chat Host→Client ──
      _add('Step 7', 'RoomMessage(chat) Host → Client');

      final chatMsg = RoomMessage.create(
        type: RoomMessage.chat, senderId: 'host',
        payload: {'text': 'Hello via Cloudflare DO!'},
      );
      hostMgr.send(chatMsg);
      await Future.delayed(const Duration(milliseconds: 800));
      final chatRecv = clientMessages.where((m) => m.messageId == chatMsg.messageId).toList();
      final chatOk = chatRecv.isNotEmpty &&
          chatRecv.first.type == RoomMessage.chat &&
          chatRecv.first.payload['text'] == 'Hello via Cloudflare DO!';
      _mark(6, chatOk, chatOk ? 'Received: "${chatRecv.first.payload['text']}"' : 'FAILED');

      // ── Step 8: Dice ──
      _add('Step 8', 'RoomMessage(dice) Host → Client');

      final diceMsg = RoomMessage.create(
        type: RoomMessage.dice, senderId: 'host',
        payload: {'expression': '1d20+5', 'total': 18, 'rolls': [13]},
      );
      hostMgr.send(diceMsg);
      await Future.delayed(const Duration(milliseconds: 500));
      final diceRecv = clientMessages.where((m) => m.messageId == diceMsg.messageId).toList();
      final diceOk = diceRecv.isNotEmpty && diceRecv.first.payload['total'] == 18;
      _mark(7, diceOk, diceOk ? '1d20+5 = 18' : 'FAILED');

      // ── Step 9: Client → Host ──
      _add('Step 9', 'RoomMessage Client → Host');

      final hostMessages = <RoomMessage>[];
      final hostMsgListener = hostMgr.messages.listen(hostMessages.add);
      final clientChat = RoomMessage.create(
        type: RoomMessage.chat, senderId: playerId,
        payload: {'text': 'Hello back, GM!'},
      );
      clientMgr.send(clientChat);
      await Future.delayed(const Duration(milliseconds: 500));
      final hostRecv = hostMessages.where((m) => m.messageId == clientChat.messageId).toList();
      await hostMsgListener.cancel();
      _mark(8, hostRecv.isNotEmpty,
          hostRecv.isNotEmpty ? 'Bidirectional OK' : 'FAILED');

      // ── Result ──
      final allOk = chatOk && diceOk && hostRecv.isNotEmpty && clientMgr.connected;
      setState(() => _status = allOk
          ? '✅ ALL PASSED — Cloudflare DO + WebRTC'
          : '❌ Check failed steps');

    } catch (e, stack) {
      _add('ERROR', '$e');
      _mark(_steps.length - 1, false, '');
      setState(() => _status = '❌ $e');
      debugPrint('$e\n$stack');
    } finally {
      await hostMsgSub?.cancel();
      await clientMsgSub?.cancel();
      await hostSig?.close();
      await playerSig?.close();
      await hostMgr?.close();
      await clientMgr?.close();
      http?.close();
      setState(() => _running = false);
    }
  }
}

class _Step {
  final String title;
  final String detail;
  final bool? passed;
  const _Step({required this.title, this.detail = '', this.passed});
  _Step copyWith({bool? passed, String? detail}) =>
      _Step(title: title, detail: detail ?? this.detail, passed: passed);
}
