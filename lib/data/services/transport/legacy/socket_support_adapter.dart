import 'dart:async';

import '../../socket_support.dart'
    show RoomServerHandle, RoomClientHandle;
import '../game/game_transport.dart' show HostGameTransport, ClientGameTransport;
import '../protocol/room_message.dart';

// ═══════════════════════════════════════════════════════════════
// Phase 0 适配器：让新 transport/ 层兼容旧的 RoomServerHandle /
// RoomClientHandle 接口，保持所有现有 UI 代码零改动。
//
// 删除时机：Phase 2，当 UI 层直接使用 GameTransport 时移除。
// ═══════════════════════════════════════════════════════════════

/// 将 [HostGameTransport] 适配为旧的 [RoomServerHandle] 接口。
///
/// UI（CreateRoomPage, AdventurePage 等）通过 [RoomSession] 使用
/// [RoomServerHandle] 接口，不感知底层是 WebSocket 还是 WebRTC。
class ServerHandleAdapter implements RoomServerHandle {
  ServerHandleAdapter(this._transport) {
    _sub = _transport.messages.listen((msg) {
      _messageController.add(msg.toLegacyString());
    });
  }

  final HostGameTransport _transport;
  late final StreamSubscription<RoomMessage> _sub;

  final StreamController<String> _messageController =
      StreamController<String>.broadcast();

  @override
  bool get isActive => _transport.connected;

  @override
  Stream<String> get messages => _messageController.stream;

  @override
  void broadcast(String message) {
    final msg = RoomMessage.fromLegacyString(message);
    _transport.broadcast(msg);
  }

  @override
  void updateHostRole(String role) {
    // Phase 0: Host role 由上层 RoomSession 管理
    // Phase 1+: 可通过信令通道同步到 DO
  }

  @override
  void updateHostSaveName(String name) {
    // Phase 0: 存档名通过 broadcast host_save_changed 同步
    // Phase 1+: 可通过信令通道同步到 DO
  }

  @override
  void kickClient(String name) {
    _transport.kickPlayer(name);
  }

  @override
  Future<void> close() async {
    await _sub.cancel();
    await _transport.close();
    await _messageController.close();
  }

  /// 暴露内部 GameTransport 供 RoomSession 高级用法
  HostGameTransport get transport => _transport;
}

/// 将 [ClientGameTransport] 适配为旧的 [RoomClientHandle] 接口。
///
/// UI（JoinRoomPage, AdventurePage 等）通过 [RoomSession] 使用
/// [RoomClientHandle] 接口，不感知底层传输。
class ClientHandleAdapter implements RoomClientHandle {
  ClientHandleAdapter(this._transport) {
    _sub = _transport.messages.listen((msg) {
      _messageController.add(msg.toLegacyString());
    });
  }

  final ClientGameTransport _transport;
  late final StreamSubscription<RoomMessage> _sub;

  final StreamController<String> _messageController =
      StreamController<String>.broadcast();

  @override
  bool get isConnected => _transport.connected;

  @override
  Stream<String> get messages => _messageController.stream;

  @override
  void send(String message) {
    final msg = RoomMessage.fromLegacyString(message);
    _transport.send(msg);
  }

  @override
  Future<void> close() async {
    await _sub.cancel();
    await _transport.close();
    await _messageController.close();
  }

  /// 暴露内部 GameTransport 供 RoomSession 高级用法
  ClientGameTransport get transport => _transport;
}
