import 'dart:async';
import 'dart:convert';

import '../../socket_support.dart' show RoomServerHandle, RoomClientHandle;
import '../protocol/room_message.dart';
import '../game/game_transport.dart';

/// WebSocket 实现的 Host 端游戏传输（Phase 0）。
///
/// 包装现有的 [RoomServerHandle]（由 platform socket 实现提供），
/// 线上格式保持旧协议不变，内部使用 [RoomMessage] 作为内存表示。
///
/// Phase 0 中 [sendToPlayer] 退化为 broadcast（旧 WebSocket 不支持定向发送）。
/// Phase 2 的 WebRTC 实现将真正支持定向发送。
class WebSocketHostGameTransport extends HostGameTransport {
  WebSocketHostGameTransport(this._server);

  /// 底层旧接口句柄（IoRoomServerHandle 或 Web 桩）
  final RoomServerHandle _server;
  StreamSubscription<String>? _sub;

  final StreamController<RoomMessage> _messageController =
      StreamController<RoomMessage>.broadcast();
  final StreamController<String> _playerConnectedController =
      StreamController<String>.broadcast();
  final StreamController<String> _playerDisconnectedController =
      StreamController<String>.broadcast();

  bool _connected = false;

  @override
  bool get connected => _connected;

  @override
  Stream<RoomMessage> get messages => _messageController.stream;

  @override
  Stream<String> get onPlayerConnected => _playerConnectedController.stream;

  @override
  Stream<String> get onPlayerDisconnected =>
      _playerDisconnectedController.stream;

  @override
  Map<String, bool> get playerConnectionStates => {};

  @override
  Future<void> connect() async {
    _connected = true;
    _sub = _server.messages.listen((raw) {
      try {
        final msg = RoomMessage.fromLegacyString(raw);
        _messageController.add(msg);

        // 检测 player_joined / player_left 事件并转发到专用流
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final legacyType = decoded['type'] as String? ?? '';
        if (legacyType == 'member_joined') {
          _playerConnectedController.add(decoded['name'] as String? ?? '');
        } else if (legacyType == 'member_left') {
          _playerDisconnectedController.add(decoded['name'] as String? ?? '');
        }
      } catch (_) {
        // 无法解析的消息静默丢弃（保持与旧行为一致）
      }
    });
  }

  @override
  Future<void> broadcast(RoomMessage message) async {
    _server.broadcast(message.toLegacyString());
  }

  @override
  Future<void> sendToPlayer(String playerId, RoomMessage message) async {
    // Phase 0: 旧 WebSocket server 不支持定向发送，退化为广播
    // Phase 2: WebRTC 实现将真正定向发送
    _server.broadcast(message.toLegacyString());
  }

  @override
  Future<void> kickPlayer(String playerId) async {
    _server.kickClient(playerId);
  }

  @override
  Future<void> close() async {
    _connected = false;
    await _sub?.cancel();
    _sub = null;
    await _server.close();
    await _messageController.close();
    await _playerConnectedController.close();
    await _playerDisconnectedController.close();
  }
}

/// WebSocket 实现的 Player 端游戏传输（Phase 0）。
///
/// 包装现有的 [RoomClientHandle]（由 platform socket 实现提供），
/// 线上格式保持旧协议不变，内部使用 [RoomMessage] 作为内存表示。
class WebSocketClientGameTransport extends ClientGameTransport {
  /// 使用已有句柄构造（推荐：先由 PlatformSocketSupport 建立连接）
  WebSocketClientGameTransport(this._handle);

  /// 底层旧接口句柄（IoRoomClientHandle 或 WebRoomClientHandle）
  final RoomClientHandle _handle;
  StreamSubscription<String>? _sub;

  final StreamController<RoomMessage> _messageController =
      StreamController<RoomMessage>.broadcast();

  bool _connected = false;

  @override
  bool get connected => _connected;

  @override
  Stream<RoomMessage> get messages => _messageController.stream;

  @override
  Future<void> connect() async {
    _connected = true;
    _sub = _handle.messages.listen((raw) {
      try {
        _messageController.add(RoomMessage.fromLegacyString(raw));
      } catch (_) {
        // 无法解析静默丢弃
      }
    });
  }

  @override
  Future<void> send(RoomMessage message) async {
    _handle.send(message.toLegacyString());
  }

  @override
  Future<void> close() async {
    _connected = false;
    await _sub?.cancel();
    _sub = null;
    await _handle.close();
    await _messageController.close();
  }
}
