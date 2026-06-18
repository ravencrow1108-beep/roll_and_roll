import 'dart:async';

import '../protocol/room_message.dart';

/// 游戏传输层抽象 —— 不关心底层是 WebSocket、WebRTC DataChannel 还是 Relay。
///
/// 上层（RoomSession、UI）只面对这个接口。
///
/// Host 和 Player 的差异由实现类处理：
/// - Host 实现: [send] 是广播，可额外提供 [sendToPlayer]
/// - Player 实现: [send] 是发送到 Host
abstract class GameTransport {
  /// 连接到游戏通道
  Future<void> connect();

  /// 统一游戏消息流
  Stream<RoomMessage> get messages;

  /// 发送游戏消息
  ///
  /// Host:  广播给所有 Player
  /// Player: 发送给 Host
  Future<void> send(RoomMessage message);

  /// 断开游戏通道
  Future<void> close();

  /// 连接状态
  bool get connected;

  /// 是否为 Host 端（影响 send 语义）
  bool get isHost;
}

/// Host 端扩展 —— 支持定向发送到指定 Player
abstract class HostGameTransport extends GameTransport {
  @override
  bool get isHost => true;

  /// 广播消息到所有已连接的 Player
  Future<void> broadcast(RoomMessage message);

  /// 定向发送到指定 Player
  Future<void> sendToPlayer(String playerId, RoomMessage message);

  /// 踢出指定 Player（断开其 DataChannel / 发送 kicked 消息）
  Future<void> kickPlayer(String playerId);

  /// 各 Player 的连接状态: playerId → connected
  Map<String, bool> get playerConnectionStates;

  /// 当新 Player 连接建立时触发
  Stream<String> get onPlayerConnected;

  /// 当 Player 断开时触发
  Stream<String> get onPlayerDisconnected;

  @override
  Future<void> send(RoomMessage message) => broadcast(message);
}

/// Player 端扩展 —— 仅能发送到 Host
abstract class ClientGameTransport extends GameTransport {
  @override
  bool get isHost => false;

  /// 发送消息到 Host
  @override
  Future<void> send(RoomMessage message);
}
