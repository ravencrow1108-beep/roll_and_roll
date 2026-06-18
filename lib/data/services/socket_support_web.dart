// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:html' show WebSocket, CloseEvent, MessageEvent;

import 'socket_support.dart';

bool get isWebPlatform => true;

// ──────────────────────────────────────────────
//  Server stub (web cannot host)
// ──────────────────────────────────────────────

class WebRoomServerHandle implements RoomServerHandle {
  final StreamController<String> _sc = StreamController<String>.broadcast();

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

Future<RoomServerHandle> startServer(
  int port, {
  required void Function(String remoteAddress, String name, String role)
  onClient,
  String hostName = '',
  String hostRole = '玩家',
}) async {
  throw UnsupportedError('Web 端不支持创建房间，请使用桌面端创建。');
}

// ──────────────────────────────────────────────
//  Client (WebSocket via dart:html)
// ──────────────────────────────────────────────

class WebRoomClientHandle implements RoomClientHandle {
  WebRoomClientHandle(this._ws) : _sc = StreamController<String>.broadcast() {
    _ws.onMessage.listen((MessageEvent e) {
      final text = e.data as String?;
      if (text != null) {
        for (final line in text.split('\n')) {
          final trimmed = line.trim();
          if (trimmed.isNotEmpty) {
            _sc.add(trimmed);
          }
        }
      }
    });

    _ws.onClose.listen((CloseEvent e) {
      if (!_sc.isClosed) {
        _sc.add(
          jsonEncode({
            'type': 'host_disconnected',
            'code': e.code,
            'reason': e.reason,
          }),
        );
      }
    });

    _ws.onError.listen((_) {
      if (!_sc.isClosed) {
        _sc.add(jsonEncode({'type': 'host_disconnected'}));
      }
    });
  }

  final WebSocket _ws;
  final StreamController<String> _sc;

  @override
  bool get isConnected => _ws.readyState == WebSocket.OPEN;

  @override
  Stream<String> get messages => _sc.stream;

  @override
  void send(String message) {
    if (_ws.readyState == WebSocket.OPEN) {
      _ws.send(message);
    }
  }

  @override
  Future<void> close() async {
    try {
      _ws.close();
    } catch (_) {}
    await _sc.close();
  }
}

Future<RoomClientHandle> connectToRoom(
  String host,
  int port, {
  required String playerName,
  String role = '玩家',
}) {
  final completer = Completer<RoomClientHandle>();
  final uri = 'ws://$host:$port';
  final ws = WebSocket(uri);

  ws.onOpen.listen((_) {
    final handle = WebRoomClientHandle(ws);
    handle.send(
      socketEncode({'type': 'join', 'name': playerName, 'role': role}),
    );
    completer.complete(handle);
  });

  ws.onError.listen((_) {
    if (!completer.isCompleted) {
      completer.completeError(Exception('无法连接到 $uri'));
    }
  });

  // Timeout after 10 seconds
  Timer(const Duration(seconds: 10), () {
    if (!completer.isCompleted) {
      ws.close();
      completer.completeError(TimeoutException('连接 $uri 超时'));
    }
  });

  return completer.future;
}
