import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:roll_and_roll/data/services/transport/protocol/room_message.dart';
import 'package:roll_and_roll/data/services/transport/protocol/signal_message.dart';

void main() {
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // RoomMessage: 构造
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  group('RoomMessage construction', () {
    test('create() auto-generates messageId and timestamp', () {
      final msg = RoomMessage.create(
        type: RoomMessage.chat,
        senderId: 'player1',
        payload: {'text': 'hello'},
      );

      expect(msg.version, 1);
      expect(msg.messageId, isNotEmpty);
      expect(msg.timestamp, greaterThan(0));
      expect(msg.type, RoomMessage.chat);
      expect(msg.senderId, 'player1');
      expect(msg.payload, {'text': 'hello'});
    });

    test('messageId is unique across instances', () {
      final ids = List.generate(
        100,
        (_) =>
            RoomMessage.create(
              type: RoomMessage.chat,
              senderId: 'test',
              payload: {},
            ).messageId,
      );
      expect(ids.toSet().length, 100);
    });
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // RoomMessage: Phase 2 序列化
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  group('RoomMessage toJson / fromJson', () {
    test('chat message round-trip', () {
      final original = RoomMessage(
        version: 1,
        messageId: 'test-id-001',
        timestamp: 1718700000000,
        type: RoomMessage.chat,
        senderId: 'player1',
        payload: {'text': 'hello', 'portrait': 'base64...'},
      );

      final json = original.toJson();
      final restored = RoomMessage.fromJson(json);

      expect(restored.version, original.version);
      expect(restored.messageId, original.messageId);
      expect(restored.timestamp, original.timestamp);
      expect(restored.type, original.type);
      expect(restored.senderId, original.senderId);
      expect(restored.payload, original.payload);
    });

    test('dice message round-trip', () {
      final original = RoomMessage.create(
        type: RoomMessage.dice,
        senderId: 'player2',
        payload: {
          'expression': '2d6+3',
          'total': 10,
          'rolls': [4, 3],
        },
      );

      final restored = RoomMessage.fromJson(original.toJson());
      expect(restored.type, RoomMessage.dice);
      expect(restored.payload['expression'], '2d6+3');
      expect(restored.payload['total'], 10);
    });

    test('fromJson handles missing version/messageId/timestamp', () {
      final restored = RoomMessage.fromJson(<String, dynamic>{
        'type': 'chat',
        'senderId': 'p1',
        'payload': <String, dynamic>{},
      });
      expect(restored.version, 1);
      expect(restored.messageId, isNotEmpty);
      expect(restored.timestamp, greaterThan(0));
    });
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // RoomMessage: legacy 兼容 (Phase 0 核心)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  group('RoomMessage legacy protocol compatibility', () {
    // ── 类型不变消息 ──

    test('chat_message ↔ chat round-trip preserves type', () {
      final legacy = jsonEncode({
        'type': 'chat_message',
        'from': '张三',
        'text': 'hello',
        'isSystem': false,
      });

      final msg = RoomMessage.fromLegacyString(legacy);
      final back = msg.toLegacyString();
      final decoded = jsonDecode(back) as Map<String, dynamic>;

      expect(decoded['type'], 'chat_message');
      expect(decoded['from'], '张三');
      expect(decoded['text'], 'hello');
    });

    test('member_joined round-trip preserves type and fields', () {
      final legacy = jsonEncode({
        'type': 'member_joined',
        'name': '李四',
        'role': '玩家',
      });

      final msg = RoomMessage.fromLegacyString(legacy);
      final back = msg.toLegacyString();
      final decoded = jsonDecode(back) as Map<String, dynamic>;

      expect(decoded['type'], 'member_joined');
      expect(decoded['name'], '李四');
      expect(decoded['role'], '玩家');
    });

    test('member_left round-trip preserves type', () {
      final legacy = jsonEncode({
        'type': 'member_left',
        'name': '王五',
      });

      final msg = RoomMessage.fromLegacyString(legacy);
      final back = msg.toLegacyString();
      final decoded = jsonDecode(back) as Map<String, dynamic>;

      expect(decoded['type'], 'member_left');
      expect(decoded['name'], '王五');
    });

    test('players_list round-trip preserves complex payload', () {
      final legacy = jsonEncode({
        'type': 'members_list',
        'members': [
          {'name': 'GM', 'role': '主持', 'isReady': true},
          {'name': 'P1', 'role': '玩家', 'isReady': false},
        ],
      });

      final msg = RoomMessage.fromLegacyString(legacy);
      final back = msg.toLegacyString();
      final decoded = jsonDecode(back) as Map<String, dynamic>;

      expect(decoded['type'], 'members_list');
      expect((decoded['members'] as List).length, 2);
    });

    test('player_ready round-trip preserves name', () {
      final legacy = jsonEncode({
        'type': 'player_ready',
        'name': '赵六',
      });

      final msg = RoomMessage.fromLegacyString(legacy);
      final back = msg.toLegacyString();
      final decoded = jsonDecode(back) as Map<String, dynamic>;

      expect(decoded['type'], 'player_ready');
      expect(decoded['name'], '赵六');
    });

    test('host_disconnected round-trip ', () {
      final legacy = jsonEncode({
        'type': 'host_disconnected',
        'code': 1006,
        'reason': 'connection lost',
      });

      final msg = RoomMessage.fromLegacyString(legacy);
      final back = msg.toLegacyString();
      final decoded = jsonDecode(back) as Map<String, dynamic>;

      expect(decoded['type'], 'host_disconnected');
      expect(decoded['code'], 1006);
    });

    // ── adventure_started / start_adventure 必须保持分离 ──

    test('adventure_started preserves type as adventure_started', () {
      final legacy = jsonEncode({
        'type': 'adventure_started',
        'map': {'name': 'Test Map', 'width': 20, 'height': 20},
        'positions': [
          {'name': 'P1', 'x': 0.5, 'y': 0.5},
        ],
      });

      final msg = RoomMessage.fromLegacyString(legacy);
      final back = msg.toLegacyString();
      final decoded = jsonDecode(back) as Map<String, dynamic>;

      // Must remain adventure_started — receivers check for this
      expect(decoded['type'], 'adventure_started');
      expect(decoded['map'], isNotNull);
      expect(decoded['positions'], isNotNull);
    });

    test('start_adventure preserves type as start_adventure', () {
      final legacy = jsonEncode({
        'type': 'start_adventure',
        'from': 'GM',
        'role': '主持',
        'saveFileName': 'test.sav',
      });

      final msg = RoomMessage.fromLegacyString(legacy);
      final back = msg.toLegacyString();
      final decoded = jsonDecode(back) as Map<String, dynamic>;

      // Must remain start_adventure — receivers check for this
      expect(decoded['type'], 'start_adventure');
      expect(decoded['from'], 'GM');
      expect(decoded['saveFileName'], 'test.sav');
    });

    test('adventure_started and start_adventure do NOT collide', () {
      final advStarted = RoomMessage.fromLegacyString(
        jsonEncode({'type': 'adventure_started', 'map': {}}),
      );
      final startAdv = RoomMessage.fromLegacyString(
        jsonEncode({'type': 'start_adventure', 'from': 'GM'}),
      );

      // Internal types must differ
      expect(advStarted.type, isNot(startAdv.type));

      // Legacy output must also differ
      final advBack = jsonDecode(advStarted.toLegacyString());
      final startBack = jsonDecode(startAdv.toLegacyString());
      expect(advBack['type'], 'adventure_started');
      expect(startBack['type'], 'start_adventure');
    });

    // ── request_members 必须透传 ──

    test('request_members passes through unchanged', () {
      final legacy = jsonEncode({'type': 'request_members'});
      final msg = RoomMessage.fromLegacyString(legacy);
      final back = msg.toLegacyString();
      final decoded = jsonDecode(back) as Map<String, dynamic>;

      // Must remain request_members — server handler checks for it
      expect(decoded['type'], 'request_members');
    });

    // ── character_create 必须映射 ──

    test('character_create round-trip preserves type', () {
      final legacy = jsonEncode({
        'type': 'character_create',
        'character': {'name': 'Hero', 'hp': 10},
        'from': 'P1',
      });

      final msg = RoomMessage.fromLegacyString(legacy);
      final back = msg.toLegacyString();
      final decoded = jsonDecode(back) as Map<String, dynamic>;

      expect(decoded['type'], 'character_create');
      expect(decoded['character'], isNotNull);
    });

    // ── host_setting_up 必须映射 ──

    test('host_setting_up round-trip preserves type', () {
      final legacy = jsonEncode({'type': 'host_setting_up'});
      final msg = RoomMessage.fromLegacyString(legacy);
      final back = msg.toLegacyString();
      final decoded = jsonDecode(back) as Map<String, dynamic>;

      expect(decoded['type'], 'host_setting_up');
    });

    // ── voice messages ──

    test('voice_data round-trip preserves base64 data', () {
      final legacy = jsonEncode({
        'type': 'voice_data',
        'from': 'P1',
        'data': 'AAAA',
      });

      final msg = RoomMessage.fromLegacyString(legacy);
      final back = msg.toLegacyString();
      final decoded = jsonDecode(back) as Map<String, dynamic>;

      expect(decoded['type'], 'voice_data');
      expect(decoded['from'], 'P1');
      expect(decoded['data'], 'AAAA');
    });

    // ── position_update (含深嵌套 payload) ──

    test('position_update round-trip preserves nested array', () {
      final legacy = jsonEncode({
        'type': 'position_update',
        'positions': [
          {'name': 'P1', 'x': 0.1, 'y': 0.2},
          {'name': 'P2', 'x': 0.9, 'y': 0.8},
        ],
      });

      final msg = RoomMessage.fromLegacyString(legacy);
      final back = msg.toLegacyString();
      final decoded = jsonDecode(back) as Map<String, dynamic>;

      expect(decoded['type'], 'position_update');
      final positions = decoded['positions'] as List;
      expect(positions.length, 2);
      expect(positions[0], {'name': 'P1', 'x': 0.1, 'y': 0.2});
    });

    // ── 无 from 字段的消息 ──

    test('message without "from" field works', () {
      final legacy = jsonEncode({'type': 'return_to_room'});
      final msg = RoomMessage.fromLegacyString(legacy);
      final back = msg.toLegacyString();
      final decoded = jsonDecode(back) as Map<String, dynamic>;

      expect(decoded['type'], 'return_to_room');
      // 'from' is added as empty string — benign for receivers
      expect(decoded['from'], '');
    });

    // ── 未知类型透传 ──

    test('unknown type passes through unchanged', () {
      final legacy = jsonEncode({
        'type': 'future_type_v99',
        'customField': 42,
      });
      final msg = RoomMessage.fromLegacyString(legacy);
      final back = msg.toLegacyString();
      final decoded = jsonDecode(back) as Map<String, dynamic>;

      // Fallback: _legacyTypeMap[type] ?? type → keeps original
      expect(decoded['type'], 'future_type_v99');
      expect(decoded['customField'], 42);
    });
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // SignalMessage
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  group('SignalMessage', () {
    test('createAuth factory', () {
      final sig = SignalMessage.createAuth(
        token: 'secret123',
        role: 'host',
      );
      expect(sig.type, SignalMessage.auth);
      expect(sig.payload['token'], 'secret123');
      expect(sig.payload['role'], 'host');
    });

    test('createOffer factory with optional targetPlayerId', () {
      final withTarget = SignalMessage.createOffer(
        sdp: 'v=0...',
        targetPlayerId: 'uuid-1',
      );
      expect(withTarget.type, SignalMessage.offer);
      expect(withTarget.payload['targetPlayerId'], 'uuid-1');

      final withoutTarget = SignalMessage.createOffer(sdp: 'v=0...');
      expect(withoutTarget.payload['targetPlayerId'], isNull);
    });

    test('createIceCandidate factory', () {
      final sig = SignalMessage.createIceCandidate(
        candidate: 'candidate:...',
        sdpMid: '0',
        sdpMLineIndex: 0,
      );
      expect(sig.type, SignalMessage.iceCandidate);
      expect(sig.payload['candidate'], 'candidate:...');
      expect(sig.payload['sdpMid'], '0');
      expect(sig.payload['sdpMLineIndex'], 0);
    });

    test('serialization round-trip', () {
      final original = SignalMessage.createAuth(
        token: 'tok',
        role: 'player',
        playerId: 'id123',
      );
      final restored = SignalMessage.fromJson(original.toJson());
      expect(restored.type, original.type);
      expect(restored.payload['token'], 'tok');
      expect(restored.payload['playerId'], 'id123');
    });

    test('createHeartbeat has empty payload', () {
      final sig = SignalMessage.createHeartbeat();
      expect(sig.type, SignalMessage.heartbeat);
      expect(sig.payload, isEmpty);
    });
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 完整数据流模拟
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  group('End-to-end legacy ↔ RoomMessage ↔ legacy', () {
    test('simulates host broadcast → adapter → wire → adapter → player', () {
      // Host UI 发送（旧格式）
      final hostMessage = jsonEncode({
        'type': 'chat_message',
        'from': 'GM',
        'text': 'Roll for initiative!',
        'isSystem': false,
      });

      // ServerHandleAdapter.broadcast() path:
      final msg = RoomMessage.fromLegacyString(hostMessage);
      // → transport sends → wire →
      // → ClientHandleAdapter receives:
      final received = msg.toLegacyString();

      // Player UI 收到
      final decoded = jsonDecode(received) as Map<String, dynamic>;
      expect(decoded['type'], 'chat_message');
      expect(decoded['from'], 'GM');
      expect(decoded['text'], 'Roll for initiative!');
    });

    test('simulates dice roll full path', () {
      final hostMessage = jsonEncode({
        'type': 'dice_result',
        'from': 'P1',
        'expression': '1d20+5',
        'total': 18,
        'rolls': [13],
      });

      final msg = RoomMessage.fromLegacyString(hostMessage);
      final received = msg.toLegacyString();
      final decoded = jsonDecode(received) as Map<String, dynamic>;

      expect(decoded['type'], 'dice_result');
      expect(decoded['from'], 'P1');
      expect(decoded['total'], 18);
    });
  });
}
