import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'socket_support.dart';

bool get isWebPlatform => false;

// ──────────────────────────────────────────────
//  Server
// ──────────────────────────────────────────────

class _ClientInfo {
  _ClientInfo(this.socket, this.name);
  final Socket socket;
  final String name;
}

class IoRoomServerHandle implements RoomServerHandle {
  IoRoomServerHandle(this._serverSocket) : _sc = StreamController<String>();

  final ServerSocket _serverSocket;
  final StreamController<String> _sc;
  final List<_ClientInfo> _clients = [];

  @override
  bool get isActive => true;

  @override
  Stream<String> get messages => _sc.stream;

  @override
  void broadcast(String message) {
    final dead = <_ClientInfo>[];
    for (final c in _clients) {
      try {
        c.socket.write(message);
      } catch (_) {
        dead.add(c);
      }
    }
    _clients.removeWhere((c) => dead.contains(c));
  }

  void _addClient(Socket socket, String name) {
    _clients.add(_ClientInfo(socket, name));
  }

  void _removeClient(Socket socket) {
    _clients.removeWhere((c) => c.socket == socket);
  }

  void _onMessage(String message) {
    _sc.add(message);
  }

  @override
  Future<void> close() async {
    for (final c in [..._clients]) {
      try {
        await c.socket.close();
      } catch (_) {}
    }
    _clients.clear();
    await _sc.close();
    await _serverSocket.close();
  }
}

Future<RoomServerHandle> startServer(
  int port, {
  required void Function(String remoteAddress, String name) onClient,
}) async {
  final serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
  final handle = IoRoomServerHandle(serverSocket);

  serverSocket.listen((socket) {
    final remote = socket.remoteAddress.address;
    bool joined = false;

    socket.listen(
      (data) {
        try {
          final text = utf8.decode(data);
          for (final line in text.split('\n')) {
            final trimmed = line.trim();
            if (trimmed.isEmpty) continue;
            final msg = jsonDecode(trimmed) as Map<String, dynamic>;

            if (!joined && msg['type'] == 'join') {
              joined = true;
              final name = (msg['name'] as String?) ?? remote;
              handle._addClient(socket, name);
              onClient(remote, name);
              continue;
            }

            // Relay to all OTHER clients (and notify host)
            if (joined) {
              handle._onMessage('$trimmed\n');
              for (final c in [...handle._clients]) {
                if (c.socket != socket) {
                  try {
                    c.socket.write('$trimmed\n');
                  } catch (_) {}
                }
              }
            }
          }
        } catch (_) {
          try {
            socket.close();
          } catch (_) {}
        }
      },
      onDone: () => handle._removeClient(socket),
      onError: (_) => handle._removeClient(socket),
      cancelOnError: false,
    );
  });

  return handle;
}

// ──────────────────────────────────────────────
//  Client
// ──────────────────────────────────────────────

class IoRoomClientHandle implements RoomClientHandle {
  IoRoomClientHandle(this._socket, this._sc);

  final Socket _socket;
  final StreamController<String> _sc;

  @override
  bool get isConnected => true;

  @override
  Stream<String> get messages => _sc.stream;

  @override
  void send(String message) {
    try {
      _socket.write(message);
    } catch (_) {}
  }

  @override
  Future<void> close() async {
    await _sc.close();
    try {
      await _socket.close();
    } catch (_) {}
  }
}

Future<RoomClientHandle> connectToRoom(
  String host,
  int port, {
  required String playerName,
}) async {
  final socket = await Socket.connect(
    host,
    port,
    timeout: const Duration(seconds: 3),
  );
  final sc = StreamController<String>();

  // Send join message
  socket.write(socketEncode({'type': 'join', 'name': playerName}));

  socket.listen(
    (data) {
      final text = utf8.decode(data);
      // A single write may contain multiple newline-delimited messages
      for (final line in text.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty) {
          sc.add(trimmed);
        }
      }
    },
    onDone: () {
      if (!sc.isClosed) sc.close();
    },
    onError: (_) {
      if (!sc.isClosed) sc.close();
    },
    cancelOnError: false,
  );

  return IoRoomClientHandle(socket, sc);
}
