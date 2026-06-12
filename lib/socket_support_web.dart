import 'socket_support.dart';

bool get isWebPlatform => true;

class WebRoomServerHandle implements RoomServerHandle {
  @override
  bool get isActive => false;

  @override
  Future<void> close() async {}
}

Future<RoomServerHandle> startServer(
  int port, {
  required void Function(String remoteAddress) onClient,
}) async {
  return WebRoomServerHandle();
}

Future<void> connectToRoom(String host, int port) async {
  throw UnsupportedError('Socket is not supported on web.');
}
