import 'dart:async';

import 'socket_support.dart';

bool get isWebPlatform => true;

class WebRoomServerHandle implements RoomServerHandle {
  final StreamController<String> _sc = StreamController<String>();

  @override
  bool get isActive => false;

  @override
  Stream<String> get messages => _sc.stream;

  @override
  void broadcast(String message) {}

  @override
  void updateHostRole(String role) {}

  @override
  void updateHostSaveName(String name) {}

  @override
  void kickClient(String name) {}

  @override
  Future<void> close() async {
    await _sc.close();
  }
}

class WebRoomClientHandle implements RoomClientHandle {
  final StreamController<String> _sc = StreamController<String>();

  @override
  bool get isConnected => false;

  @override
  Stream<String> get messages => _sc.stream;

  @override
  void send(String message) {}

  @override
  Future<void> close() async {
    await _sc.close();
  }
}

Future<RoomServerHandle> startServer(
  int port, {
  required void Function(String remoteAddress, String name, String role)
  onClient,
  String hostName = '',
  String hostRole = '玩家',
}) async {
  return WebRoomServerHandle();
}

Future<RoomClientHandle> connectToRoom(
  String host,
  int port, {
  required String playerName,
  String role = '玩家',
}) async {
  throw UnsupportedError('Socket is not supported on web.');
}
