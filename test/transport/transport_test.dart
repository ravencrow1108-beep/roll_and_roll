import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:roll_and_roll/data/services/transport/protocol/room_message.dart';
import 'package:roll_and_roll/data/services/transport/protocol/signal_message.dart';

/// Comprehensive transport protocol serialization tests.
///
/// Covers:
/// 1. RoomMessage Phase 2 wire format (toJson/fromJson)
/// 2. RoomMessage Phase 0 legacy format (toLegacy/fromLegacy)
/// 3. Round-trip identity for all message types
/// 4. Payload field isolation (no leakage between type/from/payload)
/// 5. SignalMessage wire format

void main() {
  // ═══════════════════════════════════════════════════════════════
  // Phase 2 wire format: RoomMessage.toJson() ↔ RoomMessage.fromJson()
  // This is what WebRTC DataChannel uses.
  // ═══════════════════════════════════════════════════════════════

  group('RoomMessage Phase 2 wire format (toJson/fromJson)', () {
    test('full round-trip preserves all envelope fields', () {
      final original = RoomMessage(
        version: 1,
        messageId: 'msg-001',
        timestamp: 1718700000000,
        type: RoomMessage.chat,
        senderId: 'alice',
        payload: {'text': 'Hello!'},
      );

      final json = original.toJson();
      final restored = RoomMessage.fromJson(json);

      expect(restored.version, 1);
      expect(restored.messageId, 'msg-001');
      expect(restored.timestamp, 1718700000000);
      expect(restored.type, RoomMessage.chat);
      expect(restored.senderId, 'alice');
      expect(restored.payload['text'], 'Hello!');
    });

    test('jsonEncode → jsonDecode path (actual DataChannel wire)', () {
      // This is the exact path PeerConnectionManager.send() uses:
      //   jsonEncode(message.toJson()) → DataChannel → jsonDecode → RoomMessage.fromJson()
      final original = RoomMessage.create(
        type: RoomMessage.dice,
        senderId: 'player1',
        payload: {
          'expression': '2d6+3',
          'total': 10,
          'rolls': [4, 3],
        },
      );

      final wire = jsonEncode(original.toJson());
      expect(wire, isA<String>());
      expect(wire, contains('"type":"dice"'));

      final decoded = jsonDecode(wire) as Map<String, dynamic>;
      final restored = RoomMessage.fromJson(decoded);

      expect(restored.type, original.type);
      expect(restored.senderId, original.senderId);
      expect(restored.payload, original.payload);
      expect(restored.messageId, original.messageId);
    });

    test('empty payload survives round-trip', () {
      final original = RoomMessage.create(
        type: RoomMessage.hostSettingUp,
        senderId: 'host',
        payload: {},
      );

      final restored = RoomMessage.fromJson(original.toJson());
      expect(restored.payload, isEmpty);
    });

    test('nested payload structures preserved', () {
      final original = RoomMessage.create(
        type: RoomMessage.membersList,
        senderId: 'host',
        payload: {
          'members': [
            {
              'name': 'GM',
              'role': '主持',
              'characters': [
                {'name': 'NPC1', 'hp': 20},
              ],
            },
            {
              'name': 'P1',
              'role': '玩家',
              'isReady': true,
            },
          ],
        },
      );

      final wire = jsonEncode(original.toJson());
      final restored = RoomMessage.fromJson(
        jsonDecode(wire) as Map<String, dynamic>,
      );

      final members = restored.payload['members'] as List;
      expect(members.length, 2);
      expect((members[0] as Map)['name'], 'GM');
      expect(
        ((members[0] as Map)['characters'] as List)[0],
        {'name': 'NPC1', 'hp': 20},
      );
    });

    test('all 31 message type constants serialize correctly', () {
      final types = [
        RoomMessage.chat,
        RoomMessage.dice,
        RoomMessage.mapUpdate,
        RoomMessage.tokenMove,
        RoomMessage.tokenPlace,
        RoomMessage.playerReady,
        RoomMessage.playerCancelReady,
        RoomMessage.memberJoined,
        RoomMessage.memberLeft,
        RoomMessage.membersList,
        RoomMessage.adventureStarted,
        RoomMessage.startAdventure,
        RoomMessage.characterCreate,
        RoomMessage.characterUpdate,
        RoomMessage.positionUpdate,
        RoomMessage.hostSaveChanged,
        RoomMessage.roleChange,
        RoomMessage.returnToRoom,
        RoomMessage.kicked,
        RoomMessage.hostDisconnected,
        RoomMessage.hostLeaving,
        RoomMessage.hostMigrated,
        RoomMessage.nameTaken,
        RoomMessage.hostSettingUp,
        RoomMessage.requestMembers,
        RoomMessage.voiceData,
        RoomMessage.voiceJoin,
        RoomMessage.voiceLeave,
      ];

      for (final type in types) {
        final msg = RoomMessage.create(
          type: type,
          senderId: 'test',
          payload: {'key': 'value'},
        );
        final restored = RoomMessage.fromJson(msg.toJson());
        expect(restored.type, type, reason: 'type "$type" should survive');
      }
    });

    test('fromJson handles missing fields gracefully', () {
      // Minimum viable message
      final restored = RoomMessage.fromJson(<String, dynamic>{
        'type': 'chat',
      });
      expect(restored.type, 'chat');
      expect(restored.version, 1);
      expect(restored.senderId, '');
      expect(restored.payload, isEmpty);
      expect(restored.messageId, isNotEmpty); // auto-generated
      expect(restored.timestamp, greaterThan(0)); // auto-generated
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Phase 0 legacy format: RoomMessage.fromLegacy() ↔ toLegacy()
  // This is what the Adapter layer uses.
  // ═══════════════════════════════════════════════════════════════

  group('RoomMessage Phase 0 legacy format (fromLegacy/toLegacy)', () {
    test('fromLegacy(Map) and fromLegacyString(String) produce same result', () {
      final map = <String, dynamic>{
        'type': 'chat_message',
        'from': 'p1',
        'text': 'hello',
      };
      final raw = jsonEncode(map);

      final fromMap = RoomMessage.fromLegacy(map);
      final fromString = RoomMessage.fromLegacyString(raw);

      expect(fromMap.type, fromString.type);
      expect(fromMap.senderId, fromString.senderId);
      expect(fromMap.payload, fromString.payload);
    });

    test('toLegacy() and toLegacyString() produce equivalent data', () {
      final msg = RoomMessage.create(
        type: RoomMessage.chat,
        senderId: 'p1',
        payload: {'text': 'hello'},
      );

      final map = msg.toLegacy();
      final decoded = jsonDecode(msg.toLegacyString()) as Map<String, dynamic>;

      expect(map, decoded);
    });

    test('payload cannot override type or from in toLegacy', () {
      // A malicious or buggy payload that contains 'type' or 'from'
      final msg = RoomMessage.create(
        type: RoomMessage.chat,
        senderId: 'real_sender',
        payload: {
          'text': 'hello',
          'type': 'fake_type', // should NOT override output
          'from': 'fake_sender', // should NOT override output
        },
      );

      final legacy = msg.toLegacy();

      // type and from must reflect the envelope, not payload
      expect(legacy['type'], 'chat_message'); // mapped back to legacy
      expect(legacy['from'], 'real_sender');
      // payload fields still present
      expect(legacy['text'], 'hello');
    });

    test('fromLegacy extracts name as fallback for from', () {
      // member_joined messages use 'name' not 'from'
      final map = <String, dynamic>{
        'type': 'member_joined',
        'name': 'NewPlayer',
        'role': '玩家',
      };

      final msg = RoomMessage.fromLegacy(map);

      expect(msg.senderId, 'NewPlayer');
      expect(msg.payload['name'], 'NewPlayer');
      expect(msg.payload['role'], '玩家');
    });

    test('fromLegacy prefers from over name when both present', () {
      final map = <String, dynamic>{
        'type': 'chat_message',
        'from': 'alice',
        'name': 'bob',
        'text': 'hi',
      };

      final msg = RoomMessage.fromLegacy(map);

      expect(msg.senderId, 'alice'); // 'from' takes priority
      expect(msg.payload['name'], 'bob'); // still in payload
    });

    test('legacy round-trip is identity for complex messages', () {
      final original = <String, dynamic>{
        'type': 'adventure_started',
        'from': 'GM',
        'map': {
          'name': 'Dungeon',
          'width': 30,
          'height': 20,
          'tiles': [
            {'x': 0, 'y': 0, 'terrain': 'stone'},
          ],
        },
        'positions': [
          {'name': 'P1', 'x': 0.1, 'y': 0.2},
        ],
      };

      final msg = RoomMessage.fromLegacy(original);
      final back = msg.toLegacy();

      expect(back['type'], 'adventure_started');
      expect(back['from'], 'GM');
      expect((back['map'] as Map)['name'], 'Dungeon');
      expect((back['positions'] as List).length, 1);
    });

    test('every legacy type in the map round-trips correctly', () {
      // Test every entry in _legacyTypeMap
      final testCases = <String, Map<String, dynamic>>{
        'chat_message': {'from': 'p1', 'text': 'hi'},
        'dice_result': {'from': 'p1', 'expression': '1d20', 'total': 15},
        'adventure_started': {'from': 'GM', 'map': {}},
        'start_adventure': {'from': 'GM', 'saveFileName': 'test'},
        'position_update': {
          'from': 'p1',
          'positions': [
            {'name': 'p1', 'x': 0.5, 'y': 0.5},
          ],
        },
        'character_create': {
          'from': 'p1',
          'character': {'name': 'Hero'},
        },
        'character_update': {
          'from': 'p1',
          'character': {'name': 'Hero', 'hp': 5},
        },
        'player_ready': {'from': 'p1', 'name': 'p1'},
        'player_cancel_ready': {'from': 'p1', 'name': 'p1'},
        'member_joined': {'name': 'NewGuy', 'role': '玩家'},
        'member_left': {'name': 'OldGuy'},
        'members_list': {
          'members': [
            {'name': 'GM', 'role': '主持'},
          ],
        },
        'host_save_changed': {'from': 'GM', 'saveFileName': 'new.sav'},
        'host_setting_up': {},
        'role_change': {'name': 'p1', 'role': '主持'},
        'return_to_room': {},
        'kicked': {'message': 'bye'},
        'host_disconnected': {'code': 1006},
        'name_taken': {'message': 'taken'},
        'voice_data': {'from': 'p1', 'data': 'AAAA'},
        'voice_join': {'from': 'p1'},
        'voice_leave': {'from': 'p1'},
      };

      for (final entry in testCases.entries) {
        final map = <String, dynamic>{'type': entry.key, ...entry.value};
        final msg = RoomMessage.fromLegacy(map);
        final back = msg.toLegacy();
        expect(back['type'], entry.key,
            reason: '"${entry.key}" should round-trip through legacy');
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Payload isolation: envelope fields must not leak into payload
  // and vice versa.
  // ═══════════════════════════════════════════════════════════════

  group('Payload isolation', () {
    test('fromLegacy: type and from are NOT in payload', () {
      final map = <String, dynamic>{
        'type': 'chat_message',
        'from': 'alice',
        'text': 'hello',
      };

      final msg = RoomMessage.fromLegacy(map);

      // payload must not contain type or from
      expect(msg.payload.containsKey('type'), false);
      expect(msg.payload.containsKey('from'), false);
      expect(msg.payload['text'], 'hello');
    });

    test('toLegacy: envelope fields are correct, not from payload', () {
      final msg = RoomMessage.create(
        type: RoomMessage.chat,
        senderId: 'alice',
        payload: {'text': 'hello', 'type': 'evil'},
      );

      final legacy = msg.toLegacy();

      expect(legacy['type'], 'chat_message'); // real mapped type
      expect(legacy['from'], 'alice'); // real sender
      expect(legacy['text'], 'hello'); // payload field
      // The evil 'type' from payload must NOT appear as the top-level type
      expect(legacy['type'], isNot('evil'));
    });

    test('toJson: all fields are at expected locations', () {
      final msg = RoomMessage.create(
        type: RoomMessage.chat,
        senderId: 'alice',
        payload: {'text': 'hello'},
      );

      final json = msg.toJson();

      // Envelope fields at top level
      expect(json['type'], 'chat');
      expect(json['senderId'], 'alice');
      expect(json['version'], 1);

      // Payload is nested
      expect(json['payload'], isA<Map>());
      expect((json['payload'] as Map)['text'], 'hello');
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // SignalMessage wire format
  // ═══════════════════════════════════════════════════════════════

  group('SignalMessage wire format', () {
    test('all factory constructors produce valid JSON', () {
      final messages = [
        SignalMessage.createAuth(token: 'tok', role: 'host'),
        SignalMessage.createOffer(sdp: 'v=0...', targetPlayerId: 'p1'),
        SignalMessage.createAnswer(sdp: 'v=0...'),
        SignalMessage.createIceCandidate(
          candidate: 'candidate:...',
          sdpMid: '0',
          sdpMLineIndex: 0,
        ),
        SignalMessage.createHeartbeat(),
        SignalMessage.createPlayerReady(isReady: true),
        SignalMessage.createLeave(),
      ];

      for (final sig in messages) {
        final json = sig.toJson();
        expect(json, isA<Map<String, dynamic>>());
        expect(json['type'], sig.type);
        // All must be valid JSON
        expect(() => jsonEncode(json), returnsNormally);
      }
    });

    test('auth round-trip with playerId', () {
      final sig = SignalMessage.createAuth(
        token: 'secret',
        role: 'player',
        playerId: 'uuid-123',
      );
      final wire = jsonEncode(sig.toJson());
      final restored =
          SignalMessage.fromJson(jsonDecode(wire) as Map<String, dynamic>);

      expect(restored.type, SignalMessage.auth);
      expect(restored.payload['token'], 'secret');
      expect(restored.payload['role'], 'player');
      expect(restored.payload['playerId'], 'uuid-123');
    });

    test('offer with and without targetPlayerId', () {
      final withTarget = SignalMessage.createOffer(
        sdp: 'sdp',
        targetPlayerId: 'p1',
      );
      expect(withTarget.payload['targetPlayerId'], 'p1');

      final withoutTarget = SignalMessage.createOffer(sdp: 'sdp');
      expect(withoutTarget.payload['targetPlayerId'], isNull);
    });
  });
}
