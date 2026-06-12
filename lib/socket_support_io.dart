import 'dart:io';

import 'socket_support.dart';

bool get isWebPlatform => false;

class IoRoomServerHandle implements RoomServerHandle {
  IoRoomServerHandle(this._serverSocket);

  final ServerSocket _serverSocket;

  @override
  bool get isActive => true;

  @override
  Future<void> close() => _serverSocket.close();
}

Future<RoomServerHandle> startServer(
  int port, {
  required void Function(String remoteAddress) onClient,
}) async {
  final serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
  serverSocket.listen((socket) {
    onClient(socket.remoteAddress.address);
    socket.write('欢迎加入房间\n');
    socket.close();
  });
  return IoRoomServerHandle(serverSocket);
}

Future<void> connectToRoom(String host, int port) async {
  final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 3));
  socket.write('join\n');
  await socket.flush();
  await socket.close();
}
