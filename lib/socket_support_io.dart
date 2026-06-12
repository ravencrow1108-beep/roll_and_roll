import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'socket_support.dart';

bool get isWebPlatform => false;

// ──────────────────────────────────────────────
//  Server
// ──────────────────────────────────────────────

class _ClientInfo {
  _ClientInfo(this.socket, this.name, this.role);
  final Socket socket;
  final String name;
  final String role;
}

class IoRoomServerHandle implements RoomServerHandle {
  IoRoomServerHandle(this._serverSocket) : _sc = StreamController<String>();

  final ServerSocket _serverSocket;
  StreamSubscription<Socket>? _serverSub;
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

  void _addClient(Socket socket, String name, String role) {
    _clients.add(_ClientInfo(socket, name, role));
  }

  void _removeClient(Socket socket) {
    _clients.removeWhere((c) => c.socket == socket);
  }

  void _onMessage(String message) {
    _sc.add(message);
  }

  @override
  Future<void> close() async {
    await _serverSub?.cancel();
    _serverSub = null;
    for (final c in [..._clients]) {
      try {
        c.socket.destroy();
      } catch (_) {}
    }
    _clients.clear();
    await _sc.close();
    await _serverSocket.close();
  }
}

Future<RoomServerHandle> startServer(
  int port, {
  required void Function(String remoteAddress, String name, String role)
  onClient,
}) async {
  final serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
  final handle = IoRoomServerHandle(serverSocket);

  handle._serverSub = serverSocket.listen((socket) {
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
              final role = (msg['role'] as String?) ?? '玩家';
              handle._addClient(socket, name, role);
              onClient(remote, name, role);
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
            socket.destroy();
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
  String role = '玩家',
}) async {
  final socket = await Socket.connect(
    host,
    port,
    timeout: const Duration(seconds: 3),
  );
  final sc = StreamController<String>();

  // Send join message with role
  socket.write(
    socketEncode({'type': 'join', 'name': playerName, 'role': role}),
  );

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
