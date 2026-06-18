import 'dart:async';

import '../protocol/signal_message.dart';

/// 信令传输层抽象 —— 用于与 Durable Object 建立 WebSocket 信令通道。
///
/// 职责：
/// - 房间创建/加入/离开
/// - WebRTC Offer/Answer/Candidate 中继
/// - 心跳保活
/// - 玩家状态通知
///
/// Phase 0 暂不接入，Phase 1 启用 Durable Object 时使用。
abstract class SignalingTransport {
  /// 连接到信令服务器（Worker DO WebSocket）
  Future<void> connect();

  /// 信令消息流
  Stream<SignalMessage> get signals;

  /// 发送信令消息
  Future<void> sendSignal(SignalMessage message);

  /// 断开信令连接
  Future<void> close();

  /// 连接状态
  bool get connected;
}
