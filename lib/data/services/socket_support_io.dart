import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'socket_support.dart';

bool get isWebPlatform => false;

// ──────────────────────────────────────────────
//  Server (WebSocket based)
// ──────────────────────────────────────────────

class _ClientInfo {
  _ClientInfo(this.ws, this.name, this.role);
  final WebSocket ws;
  final String name;
  String role;
}

class IoRoomServerHandle implements RoomServerHandle {
  IoRoomServerHandle(
    this._httpServer, {
    this.hostName = '',
    this.hostRole = '玩家',
  }) : _sc = StreamController<String>.broadcast();

  final HttpServer _httpServer;
  final String hostName;
  String hostRole;
  String hostSaveFileName = '';
  StreamSubscription<HttpRequest>? _serverSub;
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
        c.ws.add(message);
      } catch (_) {
        dead.add(c);
      }
    }
    _clients.removeWhere((c) => dead.contains(c));
  }

  void _addClient(WebSocket ws, String name, String role) {
    _clients.add(_ClientInfo(ws, name, role));
  }

  void _removeClient(WebSocket ws) {
    final leaving = _clients.where((c) => c.ws == ws).toList();
    _clients.removeWhere((c) => c.ws == ws);
    for (final c in leaving) {
      final msg = socketEncode({'type': 'member_left', 'name': c.name});
      broadcast(msg);
      _onMessage(msg.trim());
    }
  }

  @override
  void kickClient(String name) {
    final target = _clients.where((c) => c.name.trim() == name.trim()).toList();
    for (final c in target) {
      try {
        c.ws.add(socketEncode({'type': 'kicked', 'message': '你已被房主踢出房间'}));
      } catch (_) {}
      try {
        c.ws.close();
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
        c.ws.close();
      } catch (_) {}
    }
    _clients.clear();
    await _sc.close();
    await _httpServer.close();
  }
}

Future<RoomServerHandle> startServer(
  int port, {
  required void Function(String remoteAddress, String name, String role)
  onClient,
  String hostName = '',
  String hostRole = '玩家',
}) async {
  final httpServer = await HttpServer.bind(InternetAddress.anyIPv4, port);
  final handle = IoRoomServerHandle(
    httpServer,
    hostName: hostName,
    hostRole: hostRole,
  );

  handle._serverSub = httpServer.listen((HttpRequest request) {
    final remote = request.connectionInfo?.remoteAddress.address ?? 'unknown';
    WebSocketTransformer.upgrade(request).then((WebSocket ws) {
      _handleWebSocket(ws, remote, handle, onClient);
    });
  });

  return handle;
}

void _handleWebSocket(
  WebSocket ws,
  String remote,
  IoRoomServerHandle handle,
  void Function(String remoteAddress, String name, String role) onClient,
) {
  bool joined = false;

  ws.listen(
    (data) {
      try {
        final text = data is String ? data : utf8.decode(data as List<int>);
        for (final line in text.split('\n')) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;
          final msg = jsonDecode(trimmed) as Map<String, dynamic>;

          if (!joined && msg['type'] == 'join') {
            joined = true;
            final name = (msg['name'] as String?) ?? remote;
            final role = (msg['role'] as String?) ?? '玩家';

            final trimmedName = name.trim();
            final existingNames = <String>{
              handle.hostName.trim(),
              for (final c in handle._clients) c.name.trim(),
            };
            if (existingNames.contains(trimmedName)) {
              try {
                ws.add(
                  socketEncode({
                    'type': 'name_taken',
                    'message': '名称 "$trimmedName" 已被使用，请更换名称后重试',
                  }),
                );
              } catch (_) {}
              try {
                ws.close();
              } catch (_) {}
              return;
            }

            handle._addClient(ws, name, role);
            onClient(remote, name, role);

            final existing = <Map<String, dynamic>>[
              {
                'name': handle.hostName,
                'role': handle.hostRole,
                if (handle.hostSaveFileName.isNotEmpty)
                  'hostSaveName': handle.hostSaveFileName,
              },
            ];
            for (final c in handle._clients) {
              if (c.ws != ws) {
                existing.add({'name': c.name, 'role': c.role});
              }
            }
            if (existing.isNotEmpty) {
              try {
                ws.add(
                  socketEncode({'type': 'members_list', 'members': existing}),
                );
              } catch (_) {}
            }
            continue;
          }

          if (joined) {
            if (msg['type'] == 'request_members') {
              final hostEntry = <String, dynamic>{
                'name': handle.hostName,
                'role': handle.hostRole,
              };
              if (handle.hostSaveFileName.isNotEmpty) {
                hostEntry['hostSaveName'] = handle.hostSaveFileName;
              }
              final all = <Map<String, dynamic>>[
                hostEntry,
                ...handle._clients.map((c) => {'name': c.name, 'role': c.role}),
              ];
              try {
                ws.add(socketEncode({'type': 'members_list', 'members': all}));
              } catch (_) {}
              continue;
            }

            if (msg['type'] == 'role_change') {
              final newRole = (msg['role'] as String?) ?? '玩家';
              final clientName = (msg['name'] as String?) ?? '';
              for (final c in handle._clients) {
                if (c.ws == ws) {
                  c.role = newRole;
                  break;
                }
              }
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
              if (c.ws != ws) {
                try {
                  c.ws.add('$trimmed\n');
                } catch (_) {}
              }
            }
          }
        }
      } catch (_) {
        try {
          ws.close();
        } catch (_) {}
      }
    },
    onDone: () => handle._removeClient(ws),
    onError: (_) => handle._removeClient(ws),
    cancelOnError: false,
  );
}

// ──────────────────────────────────────────────
//  Client (WebSocket based)
// ──────────────────────────────────────────────

class IoRoomClientHandle implements RoomClientHandle {
  IoRoomClientHandle(this._ws) : _sc = StreamController<String>.broadcast();

  final WebSocket _ws;
  final StreamController<String> _sc;

  @override
  bool get isConnected => true;

  @override
  Stream<String> get messages => _sc.stream;

  @override
  void send(String message) {
    try {
      _ws.add(message);
    } catch (_) {}
  }

  @override
  Future<void> close() async {
    try {
      await _sc.close();
    } catch (_) {}
    try {
      await _ws.close();
    } catch (_) {}
  }
}

Future<RoomClientHandle> connectToRoom(
  String host,
  int port, {
  required String playerName,
  String role = '玩家',
}) async {
  final ws = await WebSocket.connect(
    'ws://$host:$port',
  ).timeout(const Duration(seconds: 5));
  final handle = IoRoomClientHandle(ws);

  // Send join message with role
  ws.add(socketEncode({'type': 'join', 'name': playerName, 'role': role}));

  ws.listen(
    (data) {
      final text = data is String ? data : utf8.decode(data as List<int>);
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
