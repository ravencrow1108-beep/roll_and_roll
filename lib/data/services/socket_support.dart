import 'dart:convert';

import 'socket_support_io.dart'
    if (dart.library.html) 'socket_support_web.dart'
    as socket_impl;

import 'transport/websocket/websocket_game.dart';
import 'transport/legacy/socket_support_adapter.dart';

// ═══════════════════════════════════════════════════════════════
// 旧接口：保留以兼容所有现有 UI 代码。
// Phase 2 移除，届时 UI 直接使用 transport/ 层。
// ═══════════════════════════════════════════════════════════════

/// 房主服务端句柄抽象，提供消息广播与客户端管理接口
abstract class RoomServerHandle {
  bool get isActive;
  Stream<String> get messages;
  void broadcast(String message);
  void updateHostRole(String role) {}
  void updateHostSaveName(String name) {}
  void kickClient(String name) {}
  Future<void> close();
}

/// 客户端连接句柄抽象，提供消息收发与断连接口
abstract class RoomClientHandle {
  bool get isConnected;
  Stream<String> get messages;
  void send(String message);
  Future<void> close();
}

// ═══════════════════════════════════════════════════════════════
// 平台入口：内部通过 transport/ 层包装现有 socket 实现。
// 上层（RoomSession / UI）不感知底层变更。
// ═══════════════════════════════════════════════════════════════

class PlatformSocketSupport {
  /// Whether this platform can host a room (desktop only in Phase 0).
  static bool get canHost => !socket_impl.isWebPlatform;

  /// Whether this platform can connect to a room (desktop + web via WebSocket).
  static bool get canConnect => true;

  /// Alias for [canHost].
  static bool get isSupported => canHost;

  static Future<RoomServerHandle> startServer(
    int port, {
    required void Function(String remoteAddress, String name, String role)
    onClient,
    String hostName = '',
    String hostRole = '玩家',
  }) async {
    // Phase 0: 使用 platform socket 实现建立原始句柄
    final rawServer = await socket_impl.startServer(
      port,
      onClient: onClient,
      hostName: hostName,
      hostRole: hostRole,
    );

    // 包装到 transport/ 层
    final transport = WebSocketHostGameTransport(rawServer);
    await transport.connect();

    // 适配为旧接口返回
    return ServerHandleAdapter(transport);
  }

  static Future<RoomClientHandle> connectToRoom(
    String host,
    int port, {
    required String playerName,
    String role = '玩家',
  }) async {
    // Phase 0: 使用 platform socket 实现建立原始句柄
    final rawClient = await socket_impl.connectToRoom(
      host,
      port,
      playerName: playerName,
      role: role,
    );

    // 包装到 transport/ 层
    final transport = WebSocketClientGameTransport(rawClient);
    await transport.connect();

    // 适配为旧接口返回
    return ClientHandleAdapter(transport);
  }

  static String get unsupportedHostMessage =>
      '当前 Web 端暂不支持创建房间，请在桌面端运行。';
}

/// Encode a JSON map as a newline-terminated socket message.
String socketEncode(Map<String, dynamic> data) => '${jsonEncode(data)}\n';
