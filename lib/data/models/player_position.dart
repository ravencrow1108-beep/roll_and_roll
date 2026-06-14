/// 玩家在地图上的位置
class PlayerPosition {
  final String name;
  final double x; // 0..1 fraction
  final double y; // 0..1 fraction

  const PlayerPosition({required this.name, this.x = 0.5, this.y = 0.5});

  Map<String, dynamic> toJson() => {'name': name, 'x': x, 'y': y};

  factory PlayerPosition.fromJson(Map<String, dynamic> json) => PlayerPosition(
    name: json['name'] as String,
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
  );
}
