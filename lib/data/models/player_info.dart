/// 玩家身份信息
class PlayerInfo {
  final String name;
  final String role;

  const PlayerInfo({required this.name, this.role = '玩家'});

  bool get isHost => role == '主持';
  bool get isPlayer => role == '玩家';
}
