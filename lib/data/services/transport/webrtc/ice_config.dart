/// WebRTC ICE 服务器配置。
///
/// Phase 1A：仅 Google STUN，适合局域网+简单 NAT 穿透。
/// Phase 3+：添加 TURN 服务器以支持对称 NAT 和中继。
class IceConfig {
  IceConfig._();

  /// 默认 ICE 配置（Phase 1A：仅 STUN）
  static Map<String, dynamic> get defaultConfig => {
        'iceServers': [
          {
            'urls': [
              'stun:stun.l.google.com:19302',
              'stun:stun1.l.google.com:19302',
            ],
          },
        ],
        'iceTransportPolicy': 'all',
      };

  /// 调试用：强制 TURN 中继（Phase 3 启用）
  static Map<String, dynamic> relayOnly(TurnServer turn) => {
        'iceServers': [
          {
            'urls': turn.urls,
            'username': turn.username,
            'credential': turn.credential,
          },
        ],
        'iceTransportPolicy': 'relay',
      };

  /// 完整配置：STUN + TURN
  static Map<String, dynamic> withTurn(TurnServer turn) => {
        'iceServers': [
          ...(_defaultStunServers),
          {
            'urls': turn.urls,
            'username': turn.username,
            'credential': turn.credential,
          },
        ],
        'iceTransportPolicy': 'all',
      };

  static List<Map<String, dynamic>> get _defaultStunServers => [
        {'urls': ['stun:stun.l.google.com:19302', 'stun:stun1.l.google.com:19302']},
      ];
}

/// TURN 服务器配置
class TurnServer {
  final List<String> urls;
  final String username;
  final String credential;

  const TurnServer({
    required this.urls,
    required this.username,
    required this.credential,
  });
}
