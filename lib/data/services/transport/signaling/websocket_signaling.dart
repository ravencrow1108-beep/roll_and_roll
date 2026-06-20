import 'dart:async';
import 'dart:convert';

import '../protocol/signal_message.dart';
import 'signaling_transport.dart';

// 平台 WebSocket 实现
import 'websocket_signaling_io.dart'
    if (dart.library.html) 'websocket_signaling_web.dart'
    as impl;

/// WebSocket 信令传输 —— 连接到 Cloudflare Worker Durable Object。
///
/// 使用 WebSocket 与 Cloudflare DO 通信，完成：
///   - 房间创建/加入/离开
///   - WebRTC offer/answer/ICE candidate 中继
///   - 心跳保活
///   - 玩家状态通知
///
/// Phase 1B 启用。
///
/// 用法：
/// ```dart
/// final sig = WebSocketSignaling(
///   workerUrl: 'wss://ravencrow1108.workers.dev',
///   roomId: 'ABC123',
///   role: 'host',
///   name: 'GM',
/// );
/// await sig.connect();
/// sig.signals.listen((msg) { ... });
/// sig.sendSignal(SignalMessage.createOffer(sdp: '...'));
/// ```
class WebSocketSignaling implements SignalingTransport {
  final String workerUrl;
  final String roomId;
  final String role; // "host" | "player"
  final String name;
  final String? playerId;

  final StreamController<SignalMessage> _signalController =
      StreamController<SignalMessage>.broadcast();

  impl.WebSocketWrapper? _ws;
  bool _connected = false;

  /// 鉴权完成后的 playerId（Player 连接时由 DO 分配）。
  String? assignedPlayerId;

  WebSocketSignaling({
    required this.workerUrl,
    required this.roomId,
    required this.role,
    required this.name,
    this.playerId,
  });

  @override
  bool get connected => _connected;

  @override
  Stream<SignalMessage> get signals => _signalController.stream;

  @override
  Future<void> connect() async {
    if (_connected) return;

    final url = '$workerUrl/room/$roomId';
    // 将 https:// → wss:// 或 http:// → ws://
    final wsUrl = url.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://');

    _ws = await impl.connect(wsUrl);
    _connected = true;

    // 发送鉴权消息
    sendSignal(SignalMessage.createAuth(
      token: roomId,
      role: role,
      playerId: playerId,
      name: name,
    ));

    // 监听消息
    _ws!.messages.listen((raw) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final sig = SignalMessage.fromJson(map);

        // 捕获 auth_ok 中的 playerId
        if (sig.type == SignalMessage.authOk && sig.payload['playerId'] != null) {
          assignedPlayerId = sig.payload['playerId'] as String;
        }

        _signalController.add(sig);
      } catch (_) {
        // 无法解析的消息静默丢弃
      }
    });

    _ws!.onDone.listen((_) {
      _connected = false;
    });
  }

  @override
  Future<void> sendSignal(SignalMessage message) async {
    if (!_connected || _ws == null) return;
    _ws!.send(jsonEncode(message.toJson()));
  }

  @override
  Future<void> close() async {
    _connected = false;
    await _ws?.close();
    _ws = null;
    await _signalController.close();
  }
}
