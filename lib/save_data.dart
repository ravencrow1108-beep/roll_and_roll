import 'dart:convert';

/// 技能数据模型
class SkillData {
  final String name;
  final String? description;
  final String? diceType;

  const SkillData({required this.name, this.description, this.diceType});

  Map<String, dynamic> toJson() => {
        'name': name,
        if (description != null) 'description': description,
        if (diceType != null) 'diceType': diceType,
      };

  factory SkillData.fromJson(Map<String, dynamic> json) => SkillData(
        name: json['name'] as String,
        description: json['description'] as String?,
        diceType: json['diceType'] as String?,
      );
}

/// 角色数据模型
class CharacterData {
  final String name;
  final String className;
  final List<String> additionalClasses;
  final String race;
  final int level;
  final List<SkillData> skills;
  final int strength;
  final int dexterity;
  final int constitution;
  final int intelligence;
  final int wisdom;
  final int charisma;

  const CharacterData({
    this.name = '无名冒险者',
    this.className = '战士',
    this.additionalClasses = const [],
    this.race = '人类',
    this.level = 1,
    this.skills = const [],
    this.strength = 10,
    this.dexterity = 10,
    this.constitution = 10,
    this.intelligence = 10,
    this.wisdom = 10,
    this.charisma = 10,
  });

  int getStatModifier(int value) => (value - 10) ~/ 2;

  Map<String, dynamic> toJson() => {
        'name': name,
        'className': className,
        'additionalClasses': additionalClasses,
        'race': race,
        'level': level,
        'skills': skills.map((s) => s.toJson()).toList(),
        'stats': {
          'strength': strength,
          'dexterity': dexterity,
          'constitution': constitution,
          'intelligence': intelligence,
          'wisdom': wisdom,
          'charisma': charisma,
        },
      };

  factory CharacterData.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    return CharacterData(
      name: json['name'] as String? ?? '无名冒险者',
      className: json['className'] as String? ?? '战士',
      additionalClasses: (json['additionalClasses'] as List<dynamic>?)
              ?.map((s) => s.toString())
              .toList() ??
          [],
      race: json['race'] as String? ?? '人类',
      level: json['level'] as int? ?? 1,
      skills: (json['skills'] as List<dynamic>?)
              ?.map((s) => SkillData.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      strength: stats['strength'] as int? ?? 10,
      dexterity: stats['dexterity'] as int? ?? 10,
      constitution: stats['constitution'] as int? ?? 10,
      intelligence: stats['intelligence'] as int? ?? 10,
      wisdom: stats['wisdom'] as int? ?? 10,
      charisma: stats['charisma'] as int? ?? 10,
    );
  }

  String get statsSummary =>
      '力量$strength 敏$dexterity 体$constitution 智$intelligence 感$wisdom 魅$charisma';
}

/// 地图数据模型
class MapData {
  final String name;
  final String description;
  final int width;
  final int height;
  final List<MapTile> tiles;

  const MapData({
    this.name = '无名地图',
    this.description = '',
    this.width = 20,
    this.height = 20,
    this.tiles = const [],
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'width': width,
        'height': height,
        'tiles': tiles.map((t) => t.toJson()).toList(),
      };

  factory MapData.fromJson(Map<String, dynamic> json) {
    return MapData(
      name: json['name'] as String? ?? '无名地图',
      description: json['description'] as String? ?? '',
      width: json['width'] as int? ?? 20,
      height: json['height'] as int? ?? 20,
      tiles: (json['tiles'] as List<dynamic>?)
              ?.map((t) => MapTile.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

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

/// 物品数据模型
class ItemData {
  final String name;
  final String type;
  final String description;
  final int quantity;
  final int weight;
  final int value;
  final Map<String, dynamic>? effects;

  const ItemData({
    this.name = '无名物品',
    this.type = '杂物',
    this.description = '',
    this.quantity = 1,
    this.weight = 0,
    this.value = 0,
    this.effects,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'description': description,
        'quantity': quantity,
        'weight': weight,
        'value': value,
        if (effects != null) 'effects': effects,
      };

  factory ItemData.fromJson(Map<String, dynamic> json) {
    return ItemData(
      name: json['name'] as String? ?? '无名物品',
      type: json['type'] as String? ?? '杂物',
      description: json['description'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 1,
      weight: json['weight'] as int? ?? 0,
      value: json['value'] as int? ?? 0,
      effects: json['effects'] as Map<String, dynamic>?,
    );
  }
}

/// 存档数据模型（整合三类对象）
class SaveData {
  final int version;
  final String createdAt;
  final List<CharacterData> characters;
  final List<MapData> maps;
  final List<ItemData> items;

  const SaveData({
    this.version = 1,
    required this.createdAt,
    this.characters = const [],
    this.maps = const [],
    this.items = const [],
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'characters': characters.map((c) => c.toJson()).toList(),
        'maps': maps.map((m) => m.toJson()).toList(),
        'items': items.map((i) => i.toJson()).toList(),
        'createdAt': createdAt,
      };

  String toJsonString() =>
      const JsonEncoder.withIndent('  ').convert(toJson());

  factory SaveData.fromJson(Map<String, dynamic> json) {
    List<CharacterData> chars;
    if (json.containsKey('characters')) {
      chars = (json['characters'] as List<dynamic>)
          .map((c) => CharacterData.fromJson(c as Map<String, dynamic>))
          .toList();
    } else if (json.containsKey('character')) {
      chars = [CharacterData.fromJson(
          json['character'] as Map<String, dynamic>? ?? {})];
    } else {
      chars = [];
    }
    return SaveData(
      version: json['version'] as int? ?? 1,
      createdAt: json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      characters: chars,
      maps: (json['maps'] as List<dynamic>?)
              ?.map((m) => MapData.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      items: (json['items'] as List<dynamic>?)
              ?.map((i) => ItemData.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
