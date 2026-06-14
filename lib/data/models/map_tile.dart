class MapTile {
  final int x;
  final int y;
  final String terrain;
  final String? description;

  const MapTile({
    required this.x,
    required this.y,
    this.terrain = '平原',
    this.description,
  });

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'terrain': terrain,
    if (description != null) 'description': description,
  };

  factory MapTile.fromJson(Map<String, dynamic> json) {
    return MapTile(
      x: json['x'] as int,
      y: json['y'] as int,
      terrain: json['terrain'] as String? ?? '平原',
      description: json['description'] as String?,
    );
  }
}
