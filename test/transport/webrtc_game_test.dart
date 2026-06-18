import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../lib/data/services/transport/protocol/room_message.dart';
import '../../lib/data/services/transport/webrtc/ice_config.dart';
import '../../lib/data/services/transport/webrtc/webrtc_game.dart';

void main() {
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // DataChannel Payload 序列化 (Phase 1A 核心)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  group('RoomMessage ↔ DataChannel payload round-trip', () {
    /// 模拟 DataChannel 传输：JSON encode → JSON decode 路径
    /// PeerConnectionManager.send() 的实际路径：
    ///   RoomMessage.toJson() → jsonEncode → RTCDataChannelMessage(text)
    /// PeerConnectionManager._setupDataChannel() 的接收路径：
    ///   RTCDataChannelMessage.text → jsonDecode → RoomMessage.fromJson()

    String serialize(RoomMessage msg) => jsonEncode(msg.toJson());
    RoomMessage deserialize(String payload) =>
        RoomMessage.fromJson(jsonDecode(payload) as Map<String, dynamic>);

    test('chat message survives DataChannel payload encoding', () {
      final original = RoomMessage.create(
        type: RoomMessage.chat,
        senderId: 'player1',
        payload: {'text': 'Hello WebRTC!', 'portrait': 'base64abc'},
      );

      final wire = serialize(original);
      final restored = deserialize(wire);

      expect(restored.type, RoomMessage.chat);
      expect(restored.senderId, 'player1');
      expect(restored.payload['text'], 'Hello WebRTC!');
      expect(restored.payload['portrait'], 'base64abc');
    });

    test('dice message survives DataChannel payload encoding', () {
      final original = RoomMessage.create(
        type: RoomMessage.dice,
        senderId: 'player2',
        payload: {
          'expression': '1d20+5',
          'total': 18,
          'rolls': [13],
        },
      );

      final restored = deserialize(serialize(original));

      expect(restored.type, RoomMessage.dice);
      expect(restored.payload['expression'], '1d20+5');
      expect(restored.payload['total'], 18);
      expect(restored.payload['rolls'], [13]);
    });

    test('position_update with nested array survives', () {
      final original = RoomMessage.create(
        type: RoomMessage.positionUpdate,
        senderId: 'host',
        payload: {
          'positions': [
            {'name': 'P1', 'x': 0.1, 'y': 0.2},
            {'name': 'P2', 'x': 0.9, 'y': 0.8},
          ],
        },
      );

      final restored = deserialize(serialize(original));
      final positions = restored.payload['positions'] as List;
      expect(positions.length, 2);
      expect(positions[0], {'name': 'P1', 'x': 0.1, 'y': 0.2});
    });

    test('map_update with large payload survives', () {
      final original = RoomMessage.create(
        type: RoomMessage.mapUpdate,
        senderId: 'host',
        payload: {
          'url': 'https://r2.example.com/maps/test.png',
          'name': 'Dungeon Level 1',
          'width': 30,
          'height': 20,
          'unit': '米',
          'tiles': List.generate(10, (i) => {'id': i, 'type': 'floor'}),
        },
      );

      final restored = deserialize(serialize(original));
      expect(restored.type, RoomMessage.mapUpdate);
      expect(restored.payload['name'], 'Dungeon Level 1');
      expect((restored.payload['tiles'] as List).length, 10);
    });

    test('messageId and timestamp are preserved', () {
      final original = RoomMessage(
        version: 1,
        messageId: 'test-uuid-12345',
        timestamp: 1718700000000,
        type: RoomMessage.chat,
        senderId: 'p1',
        payload: {'text': 'hi'},
      );

      final restored = deserialize(serialize(original));

      expect(restored.version, 1);
      expect(restored.messageId, 'test-uuid-12345');
      expect(restored.timestamp, 1718700000000);
    });

    test('simulates multi-player broadcast path', () {
      // Host generates a message and broadcasts to all players
      final hostMsg = RoomMessage.create(
        type: RoomMessage.memberJoined,
        senderId: 'host',
        payload: {'name': 'NewPlayer', 'role': '玩家'},
      );

      // Each player's DataChannel receives the same payload
      final wire = serialize(hostMsg);
      final player1View = deserialize(wire);
      final player2View = deserialize(wire);
      final player3View = deserialize(wire);

      // All players see identical data
      expect(player1View.type, RoomMessage.memberJoined);
      expect(player2View.type, RoomMessage.memberJoined);
      expect(player3View.type, RoomMessage.memberJoined);
      expect(player1View.payload, player2View.payload);
      expect(player2View.payload, player3View.payload);
    });
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ICE 配置
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  group('IceConfig', () {
    test('default config contains Chinese and Google STUN', () {
      final config = IceConfig.defaultConfig;
      final servers = config['iceServers'] as List<dynamic>;
      // 5 entries: Xiaomi, Tencent, Bilibili, Google x2
      expect(servers.length, 5);

      // Collect all URLs
      final allUrls = <String>{};
      for (final s in servers) {
        final urls = (s as Map<String, dynamic>)['urls'];
        if (urls is String) {
          allUrls.add(urls);
        }
      }

      // 国内 STUN
      expect(allUrls.contains('stun:stun.miwifi.com:3478'), true);
      expect(allUrls.contains('stun:stun.qq.com:3478'), true);
      expect(allUrls.contains('stun:stun.chat.bilibili.com:3478'), true);

      // 国际兜底
      expect(allUrls.any((u) => u.contains('stun.l.google.com')), true);
    });

    test('default config uses all transport policy', () {
      expect(IceConfig.defaultConfig['iceTransportPolicy'], 'all');
    });

    test('withTurn adds TURN alongside STUN', () {
      final turn = TurnServer(
        urls: ['turn:example.com:3478'],
        username: 'user',
        credential: 'pass',
      );
      final config = IceConfig.withTurn(turn);
      final servers = config['iceServers'] as List<dynamic>;
      // 5 STUN + 1 TURN
      expect(servers.length, 6);
    });
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 传输类型验证
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  group('Transport identity', () {
    test('HostWebRTCGameTransport is identified as host', () {
      final transport = HostWebRTCGameTransport();
      expect(transport.isHost, true);
      expect(transport.connected, false);
      transport.close();
    });

    test('ClientWebRTCGameTransport is identified as client', () {
      final transport = ClientWebRTCGameTransport();
      expect(transport.isHost, false);
      expect(transport.connected, false);
      transport.close();
    });
  });
}
