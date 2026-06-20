import 'package:flutter_test/flutter_test.dart';

import 'package:roll_and_roll/data/services/transport/protocol/signal_message.dart';
import 'package:roll_and_roll/data/services/transport/signaling/memory_signaling.dart';

/// Phase 1A: MemorySignaling 单元测试。
///
/// 验证配对信令的消息路由、连接生命周期、以及 offer/answer/ICE
/// 信令消息的完整转发流程。

void main() {
  // ═══════════════════════════════════════════════════════════════
  // MemorySignaling 配对与消息路由
  // ═══════════════════════════════════════════════════════════════

  group('MemorySignalingPair', () {
    test('creates paired host and player instances', () {
      final pair = MemorySignalingPair.create();

      expect(pair.host.role, 'host');
      expect(pair.player.role, 'player');
      expect(pair.host.connected, false);
      expect(pair.player.connected, false);
    });

    test('connect() sets connected=true on both sides', () async {
      final pair = MemorySignalingPair.create();
      await pair.connect();

      expect(pair.host.connected, true);
      expect(pair.player.connected, true);

      await pair.close();
    });

    test('close() sets connected=false on both sides', () async {
      final pair = MemorySignalingPair.create();
      await pair.connect();
      await pair.close();

      expect(pair.host.connected, false);
      expect(pair.player.connected, false);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 单向消息路由
  // ═══════════════════════════════════════════════════════════════

  group('MemorySignaling message routing', () {
    test('host → player: signal arrives on player.signals', () async {
      final pair = MemorySignalingPair.create();
      await pair.connect();

      final received = <SignalMessage>[];
      final sub = pair.player.signals.listen(received.add);

      final sig = SignalMessage.createOffer(sdp: 'v=0...', targetPlayerId: 'p1');
      await pair.host.sendSignal(sig);

      // Allow microtask to propagate
      await Future.delayed(Duration.zero);

      expect(received.length, 1);
      expect(received[0].type, SignalMessage.offer);
      expect(received[0].payload['sdp'], 'v=0...');
      expect(received[0].payload['targetPlayerId'], 'p1');

      await sub.cancel();
      await pair.close();
    });

    test('player → host: signal arrives on host.signals', () async {
      final pair = MemorySignalingPair.create();
      await pair.connect();

      final received = <SignalMessage>[];
      final sub = pair.host.signals.listen(received.add);

      final sig = SignalMessage.createAnswer(sdp: 'v=0...');
      await pair.player.sendSignal(sig);

      await Future.delayed(Duration.zero);

      expect(received.length, 1);
      expect(received[0].type, SignalMessage.answer);
      expect(received[0].payload['sdp'], 'v=0...');

      await sub.cancel();
      await pair.close();
    });

    test('multiple messages arrive in order', () async {
      final pair = MemorySignalingPair.create();
      await pair.connect();

      final received = <SignalMessage>[];
      final sub = pair.player.signals.listen(received.add);

      await pair.host.sendSignal(SignalMessage.createOffer(sdp: 'offer1'));
      await pair.host.sendSignal(
        SignalMessage.createIceCandidate(
          candidate: 'candidate:1',
          sdpMid: '0',
          sdpMLineIndex: 0,
        ),
      );
      await pair.host.sendSignal(
        SignalMessage.createIceCandidate(
          candidate: 'candidate:2',
          sdpMid: '0',
          sdpMLineIndex: 0,
        ),
      );

      await Future.delayed(Duration.zero);

      expect(received.length, 3);
      expect(received[0].type, SignalMessage.offer);
      expect(received[1].type, SignalMessage.iceCandidate);
      expect(received[2].type, SignalMessage.iceCandidate);

      await sub.cancel();
      await pair.close();
    });

    test('sendSignal before connect is no-op', () async {
      final pair = MemorySignalingPair.create();
      // 不调用 connect()

      final received = <SignalMessage>[];
      pair.player.signals.listen(received.add);

      await pair.host.sendSignal(SignalMessage.createOffer(sdp: 'v=0...'));

      await Future.delayed(Duration.zero);

      expect(received, isEmpty);
    });

    test('sendSignal after close is no-op', () async {
      final pair = MemorySignalingPair.create();
      await pair.connect();
      await pair.close();

      final received = <SignalMessage>[];
      pair.player.signals.listen(received.add);

      await pair.host.sendSignal(SignalMessage.createOffer(sdp: 'v=0...'));

      await Future.delayed(Duration.zero);

      expect(received, isEmpty);
    });

    test('bidirectional: messages flow both ways simultaneously', () async {
      final pair = MemorySignalingPair.create();
      await pair.connect();

      final hostReceived = <SignalMessage>[];
      final playerReceived = <SignalMessage>[];
      final hostSub = pair.host.signals.listen(hostReceived.add);
      final playerSub = pair.player.signals.listen(playerReceived.add);

      await pair.host.sendSignal(SignalMessage.createOffer(sdp: 'offer'));
      await pair.player.sendSignal(SignalMessage.createAnswer(sdp: 'answer'));
      await pair.host.sendSignal(
        SignalMessage.createIceCandidate(
          candidate: 'c:1',
          sdpMid: '0',
          sdpMLineIndex: 0,
        ),
      );

      await Future.delayed(Duration.zero);

      expect(playerReceived.length, 2); // offer + iceCandidate
      expect(hostReceived.length, 1); // answer

      await hostSub.cancel();
      await playerSub.cancel();
      await pair.close();
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 完整信令流模拟：Host ↔ Player WebRTC 信令
  // ═══════════════════════════════════════════════════════════════

  group('Full WebRTC signaling flow (offer → answer → ICE)', () {
    test('simulates complete signaling exchange', () async {
      final pair = MemorySignalingPair.create();
      await pair.connect();

      final hostReceived = <SignalMessage>[];
      final playerReceived = <SignalMessage>[];
      final hostSub = pair.host.signals.listen(hostReceived.add);
      final playerSub = pair.player.signals.listen(playerReceived.add);

      // Phase 1: Host creates offer for Player
      await pair.host.sendSignal(
        SignalMessage.createOffer(sdp: 'host-sdp-offer', targetPlayerId: 'p1'),
      );

      await Future.delayed(Duration.zero);
      expect(playerReceived.length, 1);
      expect(playerReceived[0].type, SignalMessage.offer);

      // Phase 2: Player responds with answer
      await pair.player.sendSignal(SignalMessage.createAnswer(sdp: 'player-sdp-answer'));

      await Future.delayed(Duration.zero);
      expect(hostReceived.length, 1);
      expect(hostReceived[0].type, SignalMessage.answer);

      // Phase 3: ICE candidates exchange
      await pair.host.sendSignal(
        SignalMessage.createIceCandidate(
          candidate: 'host-candidate-1',
          sdpMid: '0',
          sdpMLineIndex: 0,
          targetPlayerId: 'p1',
        ),
      );
      await pair.player.sendSignal(
        SignalMessage.createIceCandidate(
          candidate: 'player-candidate-1',
          sdpMid: '0',
          sdpMLineIndex: 0,
        ),
      );

      await Future.delayed(Duration.zero);

      expect(playerReceived.length, 2); // offer + host ICE
      expect(hostReceived.length, 2); // answer + player ICE
      expect(playerReceived[1].type, SignalMessage.iceCandidate);
      expect(hostReceived[1].type, SignalMessage.iceCandidate);

      // Phase 4: Player sends ready signal
      await pair.player.sendSignal(
        SignalMessage.createPlayerReady(isReady: true),
      );

      await Future.delayed(Duration.zero);
      expect(hostReceived.length, 3);
      expect(hostReceived[2].type, SignalMessage.playerReady);
      expect(hostReceived[2].payload['isReady'], true);

      // Phase 5: Heartbeat
      await pair.host.sendSignal(SignalMessage.createHeartbeat());
      await pair.player.sendSignal(SignalMessage.createHeartbeat());

      await Future.delayed(Duration.zero);
      expect(playerReceived.length, 3);
      expect(hostReceived.length, 4);

      // Phase 6: Leave
      await pair.player.sendSignal(SignalMessage.createLeave());

      await Future.delayed(Duration.zero);
      expect(hostReceived.last.type, SignalMessage.leave);

      await hostSub.cancel();
      await playerSub.cancel();
      await pair.close();
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // SignalMessage ↔ raw WebRTC signal bridge
  // ═══════════════════════════════════════════════════════════════

  group('SignalMessage ↔ raw WebRTC signal bridge', () {
    /// Simulates the bridge layer that:
    /// 1. Listens to WebRTC onLocalSignal → wraps into SignalMessage
    /// 2. Listens to SignalingTransport.signals → unwraps to raw signal

    test('raw offer → SignalMessage → raw offer survives', () {
      final rawOffer = <String, dynamic>{
        'type': 'offer',
        'sdp': 'v=0\r\no=- ...',
        'targetPlayerId': 'p1',
      };

      // Wrap
      final sig = SignalMessage(
        type: rawOffer['type'] as String,
        payload: Map<String, dynamic>.from(rawOffer)..remove('type'),
      );

      // Unwrap
      final unwrapped = <String, dynamic>{
        'type': sig.type,
        ...sig.payload,
      };

      expect(unwrapped['type'], 'offer');
      expect(unwrapped['sdp'], 'v=0\r\no=- ...');
      expect(unwrapped['targetPlayerId'], 'p1');
    });

    test('raw answer → SignalMessage → raw answer survives', () {
      final rawAnswer = <String, dynamic>{
        'type': 'answer',
        'sdp': 'v=0\r\no=- ...',
      };

      final sig = SignalMessage(
        type: rawAnswer['type'] as String,
        payload: Map<String, dynamic>.from(rawAnswer)..remove('type'),
      );

      final unwrapped = <String, dynamic>{
        'type': sig.type,
        ...sig.payload,
      };

      expect(unwrapped['type'], 'answer');
      expect(unwrapped['sdp'], 'v=0\r\no=- ...');
    });

    test('raw ICE candidate → SignalMessage → raw ICE candidate survives', () {
      final rawIce = <String, dynamic>{
        'type': 'iceCandidate',
        'candidate': 'candidate:xxx 1 udp ...',
        'sdpMid': '0',
        'sdpMLineIndex': 0,
        'targetPlayerId': 'p1',
      };

      final sig = SignalMessage(
        type: rawIce['type'] as String,
        payload: Map<String, dynamic>.from(rawIce)..remove('type'),
      );

      final unwrapped = <String, dynamic>{
        'type': sig.type,
        ...sig.payload,
      };

      expect(unwrapped['type'], 'iceCandidate');
      expect(unwrapped['candidate'], 'candidate:xxx 1 udp ...');
      expect(unwrapped['sdpMid'], '0');
      expect(unwrapped['sdpMLineIndex'], 0);
      expect(unwrapped['targetPlayerId'], 'p1');
    });
  });
}
