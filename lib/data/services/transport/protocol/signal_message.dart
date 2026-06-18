/// 信令消息协议 —— WebSocket 连接到 Durable Object 时使用的消息格式。
///
/// 仅在 Phase 1+ 启用 Durable Object 信令时使用。
/// Phase 0 暂时不接入，但接口已定义以备后续实现。
///
/// 消息方向：
///   Client → DO:  auth, offer, answer, iceCandidate, heartbeat, playerReady, leave
///   DO → Client:  auth_ok, playerJoined, playerLeft, offer, answer, iceCandidate, error, roomClosing
class SignalMessage {
  /// 信令消息类型
  final String type;

  /// 消息载荷
  final Map<String, dynamic> payload;

  const SignalMessage({
    required this.type,
    required this.payload,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        ...payload,
      };

  factory SignalMessage.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? '';
    final payload = Map<String, dynamic>.from(json);
    payload.remove('type');
    return SignalMessage(type: type, payload: payload);
  }

  // ─── 消息类型常量 ───

  /// Client→DO: 鉴权
  static const String auth = 'auth';

  /// DO→Client: 鉴权成功
  static const String authOk = 'auth_ok';

  /// Host→DO: 为指定 Player 创建 SDP Offer
  static const String offer = 'offer';

  /// Player→DO: 回复 SDP Answer
  static const String answer = 'answer';

  /// Host/Player→DO: ICE Candidate
  static const String iceCandidate = 'iceCandidate';

  /// Host/Player→DO: 心跳
  static const String heartbeat = 'heartbeat';

  /// Player→DO: 切换准备状态
  static const String playerReady = 'playerReady';

  /// Host/Player→DO: 离开房间
  static const String leave = 'leave';

  /// DO→Host: 新玩家加入
  static const String playerJoined = 'player_joined';

  /// DO→All: 玩家离开
  static const String playerLeft = 'player_left';

  /// DO→Client: 错误
  static const String error = 'error';

  /// DO→All: 房间即将关闭
  static const String roomClosing = 'room_closing';

  // ─── 预定义工厂（createXxx 前缀避免与 static const 字段名冲突）───

  factory SignalMessage.createAuth({
    required String token,
    required String role, // "host" | "player"
    String? playerId,
  }) {
    final payload = <String, dynamic>{
      'token': token,
      'role': role,
    };
    if (playerId != null) payload['playerId'] = playerId;
    return SignalMessage(type: auth, payload: payload);
  }

  factory SignalMessage.createOffer({
    required String sdp,
    String? targetPlayerId,
  }) {
    final payload = <String, dynamic>{'sdp': sdp};
    if (targetPlayerId != null) payload['targetPlayerId'] = targetPlayerId;
    return SignalMessage(type: offer, payload: payload);
  }

  factory SignalMessage.createAnswer({required String sdp}) => SignalMessage(
        type: answer,
        payload: {'sdp': sdp},
      );

  factory SignalMessage.createIceCandidate({
    required String candidate,
    required String sdpMid,
    required int sdpMLineIndex,
    String? targetPlayerId,
  }) {
    final payload = <String, dynamic>{
      'candidate': candidate,
      'sdpMid': sdpMid,
      'sdpMLineIndex': sdpMLineIndex,
    };
    if (targetPlayerId != null) payload['targetPlayerId'] = targetPlayerId;
    return SignalMessage(type: iceCandidate, payload: payload);
  }

  factory SignalMessage.createHeartbeat() => const SignalMessage(
        type: heartbeat,
        payload: {},
      );

  factory SignalMessage.createPlayerReady({required bool isReady}) =>
      SignalMessage(
        type: playerReady,
        payload: {'isReady': isReady},
      );

  factory SignalMessage.createLeave() => const SignalMessage(
        type: leave,
        payload: {},
      );

  @override
  String toString() => 'SignalMessage($type, $payload)';
}
