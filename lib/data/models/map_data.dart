import 'enemy_data.dart';
import 'map_tile.dart';

/// 地图数据模型
class MapData {
  final String name;
  final String description;
  final int width;
  final int height;
  final String imageBase64;
  final String unit;
  final List<MapTile> tiles;
  final List<EnemyData> enemies;

  const MapData({
    this.name = '无名地图',
    this.description = '',
    this.width = 20,
    this.height = 20,
    required this.imageBase64,
    this.unit = '米',
    this.tiles = const [],
    this.enemies = const [],
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'width': width,
    'height': height,
    'unit': unit,
    'imageBase64': imageBase64,
    'tiles': tiles.map((t) => t.toJson()).toList(),
    if (enemies.isNotEmpty) 'enemies': enemies.map((e) => e.toJson()).toList(),
  };

  factory MapData.fromJson(Map<String, dynamic> json) {
    return MapData(
      name: json['name'] as String? ?? '无名地图',
      description: json['description'] as String? ?? '',
      width: json['width'] as int? ?? 20,
      height: json['height'] as int? ?? 20,
      imageBase64: json['imageBase64'] as String? ?? '',
      unit: json['unit'] as String? ?? '米',
      tiles:
          (json['tiles'] as List<dynamic>?)
              ?.map((t) => MapTile.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      enemies:
          (json['enemies'] as List<dynamic>?)
              ?.map((e) => EnemyData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Create a modified copy with only the given fields replaced.
  MapData copyWith({
    String? name,
    String? description,
    int? width,
    int? height,
    String? imageBase64,
    String? unit,
    List<MapTile>? tiles,
    List<EnemyData>? enemies,
  }) => MapData(
    name: name ?? this.name,
    description: description ?? this.description,
    width: width ?? this.width,
    height: height ?? this.height,
    imageBase64: imageBase64 ?? this.imageBase64,
    unit: unit ?? this.unit,
    tiles: tiles ?? this.tiles,
    enemies: enemies ?? this.enemies,
  );
}
