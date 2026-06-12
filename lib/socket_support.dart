import 'socket_support_io.dart'
    if (dart.library.html) 'socket_support_web.dart' as socket_impl;

abstract class RoomServerHandle {
  bool get isActive;
  Future<void> close();
}

class PlatformSocketSupport {
  static bool get isSupported => !socket_impl.isWebPlatform;

  static Future<RoomServerHandle> startServer(
    int port, {
    required void Function(String remoteAddress) onClient,
  }) {
    return socket_impl.startServer(port, onClient: onClient);
  }

  static Future<void> connectToRoom(String host, int port) {
    return socket_impl.connectToRoom(host, port);
  }

  static String get unsupportedMessage =>
      '当前 Web 端暂不支持直接使用网络套接字，请在桌面端运行。';
}
