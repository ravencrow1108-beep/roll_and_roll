import 'dart:convert';

import 'socket_support_io.dart'
    if (dart.library.html) 'socket_support_web.dart'
    as socket_impl;

abstract class RoomServerHandle {
  bool get isActive;
  Stream<String> get messages;
  void broadcast(String message);
  void updateHostRole(String role) {}
  void updateHostSaveName(String name) {}
  Future<void> close();
}

abstract class RoomClientHandle {
  bool get isConnected;
  Stream<String> get messages;
  void send(String message);
  Future<void> close();
}

class PlatformSocketSupport {
  static bool get isSupported => !socket_impl.isWebPlatform;

  static Future<RoomServerHandle> startServer(
    int port, {
    required void Function(String remoteAddress, String name, String role)
    onClient,
    String hostName = '',
    String hostRole = '玩家',
  }) {
    return socket_impl.startServer(
      port,
      onClient: onClient,
      hostName: hostName,
      hostRole: hostRole,
    );
  }

  static Future<RoomClientHandle> connectToRoom(
    String host,
    int port, {
    required String playerName,
    String role = '玩家',
  }) {
    return socket_impl.connectToRoom(
      host,
      port,
      playerName: playerName,
      role: role,
    );
  }

  static String get unsupportedMessage => '当前 Web 端暂不支持直接使用网络套接字，请在桌面端运行。';
}

/// Encode a JSON map as a newline-terminated socket message.
String socketEncode(Map<String, dynamic> data) => '${jsonEncode(data)}\n';
