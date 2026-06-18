import 'dart:async';

import '../protocol/signal_message.dart';
import 'signaling_transport.dart';

/// 内存信令实现 —— Phase 1A 本地 WebRTC loopback 使用。
///
/// 两个 [MemorySignaling] 实例通过 [MemorySignalingPair] 配对，
/// 一端调用 [sendSignal] 的消息会出现在另一端的 [signals] 流中。
///
/// 用途：在引入 Cloudflare Durable Object 之前，先验证
/// WebRTC offer/answer/ICE 信令流程在本地可以跑通。
///
/// Phase 1B 替换为 [WebSocketSignaling] 连接到 Cloudflare Worker。
class MemorySignaling implements SignalingTransport {
  MemorySignaling._({required this.role});

  /// "host" | "player"
  final String role;

  bool _connected = false;

  /// 配对的对端实例。设置后，本端 [sendSignal] 会写入对端的 [_incoming]。
  MemorySignaling? _peer;

  final StreamController<SignalMessage> _incoming =
      StreamController<SignalMessage>.broadcast();

  @override
  bool get connected => _connected;

  @override
  Stream<SignalMessage> get signals => _incoming.stream;

  @override
  Future<void> connect() async {
    _connected = true;
  }

  @override
  Future<void> sendSignal(SignalMessage message) async {
    if (!_connected) return;
    _peer?._incoming.add(message);
  }

  @override
  Future<void> close() async {
    _connected = false;
    await _incoming.close();
  }
}

/// 创建一对互联的 [MemorySignaling] 实例。
///
/// 用法：
/// ```dart
/// final pair = MemorySignalingPair.create();
/// // pair.host  ← Host 端使用
/// // pair.player ← Player 端使用
/// ```
class MemorySignalingPair {
  final MemorySignaling host;
  final MemorySignaling player;

  MemorySignalingPair._({required this.host, required this.player});

  /// 创建一对互联的 MemorySignaling。
  ///
  /// host.sendSignal() → player.signals
  /// player.sendSignal() → host.signals
  factory MemorySignalingPair.create() {
    final host = MemorySignaling._(role: 'host');
    final player = MemorySignaling._(role: 'player');
    host._peer = player;
    player._peer = host;
    return MemorySignalingPair._(host: host, player: player);
  }

  /// 连接双方。
  Future<void> connect() async {
    await host.connect();
    await player.connect();
  }

  /// 断开双方。
  Future<void> close() async {
    await host.close();
    await player.close();
  }
}
