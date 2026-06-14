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
  String role;
}

class IoRoomServerHandle implements RoomServerHandle {
  IoRoomServerHandle(
    this._serverSocket, {
    this.hostName = '',
    this.hostRole = '玩家',
  }) : _sc = StreamController<String>.broadcast();

  final ServerSocket _serverSocket;
  final String hostName;
  String hostRole;
  String hostSaveFileName = '';
  StreamSubscription<Socket>? _serverSub;
  final StreamController<String> _sc;
  final List<_ClientInfo> _clients = [];

  @override
  void updateHostRole(String role) {
    hostRole = role;
  }

  @override
  void updateHostSaveName(String name) {
    hostSaveFileName = name;
  }

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
    final leaving = _clients.where((c) => c.socket == socket).toList();
    _clients.removeWhere((c) => c.socket == socket);
    for (final c in leaving) {
      final msg = socketEncode({'type': 'member_left', 'name': c.name});
      // Notify remaining clients
      broadcast(msg);
      // Notify host
      _onMessage(msg.trim());
    }
  }

  @override
  void kickClient(String name) {
    final target = _clients.where((c) => c.name.trim() == name.trim()).toList();
    for (final c in target) {
      try {
        c.socket.write(
          socketEncode({'type': 'kicked', 'message': '你已被房主踢出房间'}),
        );
      } catch (_) {}
      try {
        c.socket.destroy();
      } catch (_) {}
    }
    if (target.isNotEmpty) {
      _clients.removeWhere((c) => target.contains(c));
      final msg = socketEncode({'type': 'member_left', 'name': name});
      broadcast(msg);
      _onMessage(msg.trim());
    }
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
  String hostName = '',
  String hostRole = '玩家',
}) async {
  final serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
  final handle = IoRoomServerHandle(
    serverSocket,
    hostName: hostName,
    hostRole: hostRole,
  );

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

              // ── 重名检测：不允许与房主或已有成员重名 ──
              final trimmedName = name.trim();
              final existingNames = <String>{
                handle.hostName.trim(),
                for (final c in handle._clients) c.name.trim(),
              };
              if (existingNames.contains(trimmedName)) {
                try {
                  socket.write(
                    socketEncode({
                      'type': 'name_taken',
                      'message': '名称 "$trimmedName" 已被使用，请更换名称后重试',
                    }),
                  );
                } catch (_) {}
                try {
                  socket.destroy();
                } catch (_) {}
                continue;
              }

              handle._addClient(socket, name, role);
              onClient(remote, name, role);

              // Send full existing member list (host + other clients) to the new client
              final existing = <Map<String, dynamic>>[
                {
                  'name': handle.hostName,
                  'role': handle.hostRole,
                  if (handle.hostSaveFileName.isNotEmpty)
                    'hostSaveName': handle.hostSaveFileName,
                },
              ];
              for (final c in handle._clients) {
                if (c.socket != socket) {
                  existing.add({'name': c.name, 'role': c.role});
                }
              }
              if (existing.isNotEmpty) {
                try {
                  socket.write(
                    socketEncode({'type': 'members_list', 'members': existing}),
                  );
                } catch (_) {}
              }
              continue;
            }

            // Relay to all OTHER clients (and notify host)
            if (joined) {
              if (msg['type'] == 'request_members') {
                // Reply with host + all clients
                final hostEntry = <String, dynamic>{
                  'name': handle.hostName,
                  'role': handle.hostRole,
                };
                if (handle.hostSaveFileName.isNotEmpty) {
                  hostEntry['hostSaveName'] = handle.hostSaveFileName;
                }
                final all = <Map<String, dynamic>>[
                  hostEntry,
                  ...handle._clients.map(
                    (c) => {'name': c.name, 'role': c.role},
                  ),
                ];
                try {
                  socket.write(
                    socketEncode({'type': 'members_list', 'members': all}),
                  );
                } catch (_) {}
                continue;
              }

              // Handle role change from a client
              if (msg['type'] == 'role_change') {
                final newRole = (msg['role'] as String?) ?? '玩家';
                final clientName = (msg['name'] as String?) ?? '';
                for (final c in handle._clients) {
                  if (c.socket == socket) {
                    c.role = newRole;
                    break;
                  }
                }
                // Tell host about the role change
                handle._onMessage(
                  socketEncode({
                    'type': 'role_change',
                    'name': clientName,
                    'role': newRole,
                  }).trim(),
                );
                continue;
              }

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
  IoRoomClientHandle(this._socket) : _sc = StreamController<String>();

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
    try {
      await _sc.close();
    } catch (_) {}
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
  final handle = IoRoomClientHandle(socket);

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
          handle._sc.add(trimmed);
        }
      }
    },
    onDone: () {
      if (!handle._sc.isClosed) {
        handle._sc.add(jsonEncode({'type': 'host_disconnected'}));
      }
    },
    onError: (_) {
      if (!handle._sc.isClosed) {
        handle._sc.add(jsonEncode({'type': 'host_disconnected'}));
      }
    },
    cancelOnError: false,
  );

  return handle;
}
