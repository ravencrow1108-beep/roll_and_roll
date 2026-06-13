import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive.dart';

/// 玩家身份信息
class PlayerInfo {
  final String name;
  final String role;

  const PlayerInfo({required this.name, this.role = '玩家'});

  bool get isHost => role == '主持';
  bool get isPlayer => role == '玩家';
}

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

/// 骰子表达式解析结果
class DiceRollResult {
  final List<int> individualRolls;
  final int total;
  final String expression;

  const DiceRollResult({
    required this.individualRolls,
    required this.total,
    required this.expression,
  });

  @override
  String toString() =>
      '$expression => $total ${individualRolls.isNotEmpty ? individualRolls : ""}';
}

/// 骰子表达式解析器 — 支持如 "2d6+3", "1d8+1d4", "d20+力量", "2d6+敏捷+1d4" 等
class DiceExpression {
  static final _dicePattern = RegExp(r'(\d+)?d(\d+)', caseSensitive: false);
  static final _attrPattern = RegExp(r'[+\-]\s*(力量|敏捷|体质|智力|感知|魅力)');

  /// 解析并投掷骰子表达式
  /// [expression] 如 "2d6+3", "d20+力量"
  /// [statModifiers] 属性名到调整值的映射
  static DiceRollResult roll(
    String expression, {
    Map<String, int>? statModifiers,
  }) {
    final mods = statModifiers ?? {};
    final rolls = <int>[];
    int total = 0;
    String remaining = expression.trim();

    // 先提取所有骰子部分
    for (final match in _dicePattern.allMatches(remaining)) {
      final count = int.tryParse(match.group(1) ?? '1') ?? 1;
      final sides = int.tryParse(match.group(2) ?? '6') ?? 6;
      final rng = Random();
      for (int i = 0; i < count; i++) {
        final roll = rng.nextInt(sides) + 1;
        rolls.add(roll);
        total += roll;
      }
    }

    // 处理固定数值加成 (如 +3, -2)
    final fixedPattern = RegExp(r'([+\-])\s*(\d+)');
    for (final match in fixedPattern.allMatches(remaining)) {
      final sign = match.group(1) == '-' ? -1 : 1;
      final val = int.tryParse(match.group(2) ?? '0') ?? 0;
      total += sign * val;
    }

    // 处理属性加成 (如 +力量)
    for (final match in _attrPattern.allMatches(remaining)) {
      final sign = match.group(0)!.trimLeft().startsWith('-') ? -1 : 1;
      final attrName = match.group(1)!;
      final mod = mods[attrName] ?? 0;
      total += sign * mod;
    }

    return DiceRollResult(
      individualRolls: rolls,
      total: total,
      expression: expression,
    );
  }

  /// 校验表达式是否合法
  static bool isValid(String? expression) {
    if (expression == null || expression.trim().isEmpty) return false;
    final cleaned = expression.trim();
    return _dicePattern.hasMatch(cleaned) || _attrPattern.hasMatch(cleaned);
  }
}

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

/// 性格数据模型
class PersonalityData {
  final String trait;
  final String? description;

  const PersonalityData({required this.trait, this.description});

  Map<String, dynamic> toJson() => {
    'trait': trait,
    if (description != null) 'description': description,
  };

  factory PersonalityData.fromJson(Map<String, dynamic> json) =>
      PersonalityData(
        trait: json['trait'] as String,
        description: json['description'] as String?,
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
  final List<PersonalityData> personalities;
  final List<ItemData> backpack;
  final int strength;
  final int dexterity;
  final int constitution;
  final int intelligence;
  final int wisdom;
  final int charisma;
  final Map<String, int> customStats;
  final int hp;
  final int maxHp;

  /// Character portrait image (base64 PNG, may be empty).
  final String portraitBase64;

  const CharacterData({
    this.name = '无名冒险者',
    this.className = '战士',
    this.additionalClasses = const [],
    this.race = '人类',
    this.level = 1,
    this.skills = const [],
    this.personalities = const [],
    this.backpack = const [],
    this.strength = 10,
    this.dexterity = 10,
    this.constitution = 10,
    this.intelligence = 10,
    this.wisdom = 10,
    this.charisma = 10,
    this.customStats = const {},
    this.hp = 1,
    this.maxHp = 1,
    this.portraitBase64 = '',
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'className': className,
    'additionalClasses': additionalClasses,
    'race': race,
    'level': level,
    'skills': skills.map((s) => s.toJson()).toList(),
    if (personalities.isNotEmpty)
      'personalities': personalities.map((p) => p.toJson()).toList(),
    if (backpack.isNotEmpty)
      'backpack': backpack.map((i) => i.toJson()).toList(),
    'stats': {
      'strength': strength,
      'dexterity': dexterity,
      'constitution': constitution,
      'intelligence': intelligence,
      'wisdom': wisdom,
      'charisma': charisma,
    },
    if (customStats.isNotEmpty) 'customStats': customStats,
    'hp': hp,
    'maxHp': maxHp,
    if (portraitBase64.isNotEmpty) 'portraitBase64': portraitBase64,
  };

  factory CharacterData.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    final cs = json['customStats'] as Map<String, dynamic>?;
    return CharacterData(
      name: json['name'] as String? ?? '无名冒险者',
      className: json['className'] as String? ?? '战士',
      additionalClasses:
          (json['additionalClasses'] as List<dynamic>?)
              ?.map((s) => s.toString())
              .toList() ??
          [],
      race: json['race'] as String? ?? '人类',
      level: json['level'] as int? ?? 1,
      skills:
          (json['skills'] as List<dynamic>?)
              ?.map((s) => SkillData.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      personalities:
          (json['personalities'] as List<dynamic>?)
              ?.map((p) => PersonalityData.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      backpack:
          (json['backpack'] as List<dynamic>?)
              ?.map((i) => ItemData.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      strength: stats['strength'] as int? ?? 10,
      dexterity: stats['dexterity'] as int? ?? 10,
      constitution: stats['constitution'] as int? ?? 10,
      intelligence: stats['intelligence'] as int? ?? 10,
      wisdom: stats['wisdom'] as int? ?? 10,
      charisma: stats['charisma'] as int? ?? 10,
      customStats: cs != null
          ? cs.map((k, v) => MapEntry(k, (v as num).toInt()))
          : const {},
      hp: json['hp'] as int? ?? 1,
      maxHp: json['maxHp'] as int? ?? 1,
      portraitBase64: json['portraitBase64'] as String? ?? '',
    );
  }

  /// Create a modified copy with only the given fields replaced.
  CharacterData copyWith({
    String? name,
    String? className,
    List<String>? additionalClasses,
    String? race,
    int? level,
    List<SkillData>? skills,
    List<PersonalityData>? personalities,
    List<ItemData>? backpack,
    int? strength,
    int? dexterity,
    int? constitution,
    int? intelligence,
    int? wisdom,
    int? charisma,
    Map<String, int>? customStats,
    int? hp,
    int? maxHp,
    String? portraitBase64,
  }) => CharacterData(
    name: name ?? this.name,
    className: className ?? this.className,
    additionalClasses: additionalClasses ?? this.additionalClasses,
    race: race ?? this.race,
    level: level ?? this.level,
    skills: skills ?? this.skills,
    personalities: personalities ?? this.personalities,
    backpack: backpack ?? this.backpack,
    strength: strength ?? this.strength,
    dexterity: dexterity ?? this.dexterity,
    constitution: constitution ?? this.constitution,
    intelligence: intelligence ?? this.intelligence,
    wisdom: wisdom ?? this.wisdom,
    charisma: charisma ?? this.charisma,
    customStats: customStats ?? this.customStats,
    hp: hp ?? this.hp,
    maxHp: maxHp ?? this.maxHp,
    portraitBase64: portraitBase64 ?? this.portraitBase64,
  );
}

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

/// 敌人数据模型
class EnemyData {
  final String name;
  final double x; // 0..1 fraction
  final double y; // 0..1 fraction
  final int hp;
  final int maxHp;
  final int ac;
  final int initiative;
  final String? attackDice;
  final String? description;
  final int strength;
  final int dexterity;
  final int constitution;
  final int intelligence;
  final int wisdom;
  final int charisma;

  const EnemyData({
    required this.name,
    this.x = 0.5,
    this.y = 0.5,
    this.hp = 10,
    this.maxHp = 10,
    this.ac = 10,
    this.initiative = 0,
    this.attackDice,
    this.description,
    this.strength = 10,
    this.dexterity = 10,
    this.constitution = 10,
    this.intelligence = 10,
    this.wisdom = 10,
    this.charisma = 10,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'x': x,
    'y': y,
    'hp': hp,
    'maxHp': maxHp,
    'ac': ac,
    'initiative': initiative,
    if (attackDice != null) 'attackDice': attackDice,
    if (description != null) 'description': description,
    'stats': {
      'strength': strength,
      'dexterity': dexterity,
      'constitution': constitution,
      'intelligence': intelligence,
      'wisdom': wisdom,
      'charisma': charisma,
    },
  };

  factory EnemyData.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    return EnemyData(
      name: json['name'] as String? ?? '无名敌人',
      x: (json['x'] as num?)?.toDouble() ?? 0.5,
      y: (json['y'] as num?)?.toDouble() ?? 0.5,
      hp: json['hp'] as int? ?? 10,
      maxHp: json['maxHp'] as int? ?? 10,
      ac: json['ac'] as int? ?? 10,
      initiative: json['initiative'] as int? ?? 0,
      attackDice: json['attackDice'] as String?,
      description: json['description'] as String?,
      strength: stats['strength'] as int? ?? 10,
      dexterity: stats['dexterity'] as int? ?? 10,
      constitution: stats['constitution'] as int? ?? 10,
      intelligence: stats['intelligence'] as int? ?? 10,
      wisdom: stats['wisdom'] as int? ?? 10,
      charisma: stats['charisma'] as int? ?? 10,
    );
  }

  /// Create a modified copy with only the given fields replaced.
  EnemyData copyWith({
    String? name,
    double? x,
    double? y,
    int? hp,
    int? maxHp,
    int? ac,
    int? initiative,
    String? attackDice,
    String? description,
    int? strength,
    int? dexterity,
    int? constitution,
    int? intelligence,
    int? wisdom,
    int? charisma,
  }) => EnemyData(
    name: name ?? this.name,
    x: x ?? this.x,
    y: y ?? this.y,
    hp: hp ?? this.hp,
    maxHp: maxHp ?? this.maxHp,
    ac: ac ?? this.ac,
    initiative: initiative ?? this.initiative,
    attackDice: attackDice ?? this.attackDice,
    description: description ?? this.description,
    strength: strength ?? this.strength,
    dexterity: dexterity ?? this.dexterity,
    constitution: constitution ?? this.constitution,
    intelligence: intelligence ?? this.intelligence,
    wisdom: wisdom ?? this.wisdom,
    charisma: charisma ?? this.charisma,
  );
}

/// 规则数据模型 — 回合设置、环节设置
class RuleData {
  /// 回合设置 (暂时留空)
  final List<String> turnSettings;

  /// 环节设置 (默认：先攻、战斗)
  final List<String> phaseSettings;

  const RuleData({
    this.turnSettings = const [],
    this.phaseSettings = const ['先攻', '战斗'],
  });

  Map<String, dynamic> toJson() => {
    if (turnSettings.isNotEmpty) 'turnSettings': turnSettings,
    'phaseSettings': phaseSettings,
  };

  factory RuleData.fromJson(Map<String, dynamic> json) => RuleData(
    turnSettings:
        (json['turnSettings'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        const [],
    phaseSettings:
        (json['phaseSettings'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        const ['先攻', '战斗'],
  );
}

/// 存档数据模型（整合三类对象）— ZIP 格式
class SaveData {
  final int version;
  final String createdAt;
  final List<CharacterData> characters;
  final List<MapData> maps;
  final List<ItemData> items;
  final List<PlayerPosition> playerPositions;
  final RuleData rules;

  const SaveData({
    this.version = 1,
    required this.createdAt,
    this.characters = const [],
    this.maps = const [],
    this.items = const [],
    this.playerPositions = const [],
    this.rules = const RuleData(),
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'characters': characters.map((c) => c.toJson()).toList(),
    'maps': maps.map((m) => m.toJson()).toList(),
    'items': items.map((i) => i.toJson()).toList(),
    'createdAt': createdAt,
    if (playerPositions.isNotEmpty)
      'playerPositions': playerPositions.map((p) => p.toJson()).toList(),
    'rules': rules.toJson(),
  };

  factory SaveData.fromJson(Map<String, dynamic> json) {
    List<CharacterData> chars;
    if (json.containsKey('characters')) {
      chars = (json['characters'] as List<dynamic>)
          .map((c) => CharacterData.fromJson(c as Map<String, dynamic>))
          .toList();
    } else if (json.containsKey('character')) {
      chars = [
        CharacterData.fromJson(
          json['character'] as Map<String, dynamic>? ?? {},
        ),
      ];
    } else {
      chars = [];
    }
    return SaveData(
      version: json['version'] as int? ?? 1,
      createdAt:
          json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      characters: chars,
      maps:
          (json['maps'] as List<dynamic>?)
              ?.map((m) => MapData.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      items:
          (json['items'] as List<dynamic>?)
              ?.map((i) => ItemData.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      playerPositions:
          (json['playerPositions'] as List<dynamic>?)
              ?.map((p) => PlayerPosition.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      rules: json.containsKey('rules')
          ? RuleData.fromJson(json['rules'] as Map<String, dynamic>)
          : const RuleData(),
    );
  }

  // ═══════════════════════════════════════════════
  //  ZIP 存档（v2）
  // ═══════════════════════════════════════════════

  /// Write this SaveData to a ZIP file at [path].
  /// Images are stored as raw PNG bytes inside the archive.
  Future<void> packToZip(String path) async {
    final archive = Archive();

    // 1. JSON manifest (without base64 blobs — images are separate files)
    final manifest = _toZipManifest();
    archive.addFile(
      ArchiveFile(
        'save.json',
        utf8
            .encode(const JsonEncoder.withIndent('  ').convert(manifest))
            .length,
        utf8.encode(const JsonEncoder.withIndent('  ').convert(manifest)),
      ),
    );

    // 2. Map images
    for (final m in maps) {
      if (m.imageBase64.isNotEmpty) {
        final bytes = base64Decode(m.imageBase64);
        archive.addFile(
          ArchiveFile('maps/${_safeFileName(m.name)}.png', bytes.length, bytes),
        );
      }
    }

    // 3. Character portraits
    for (final c in characters) {
      if (c.portraitBase64.isNotEmpty) {
        final bytes = base64Decode(c.portraitBase64);
        archive.addFile(
          ArchiveFile(
            'portraits/${_safeFileName(c.name)}.png',
            bytes.length,
            bytes,
          ),
        );
      }
    }

    final encoded = ZipEncoder().encode(archive);
    await File(path).writeAsBytes(encoded, flush: true);
  }

  /// Generate a clean manifest that references image paths instead of
  /// embedding base64 blobs.
  Map<String, dynamic> _toZipManifest() {
    final mapJson = maps.map((m) {
      final j = m.toJson();
      if (m.imageBase64.isNotEmpty) {
        j['imageFile'] = 'maps/${_safeFileName(m.name)}.png';
        j.remove('imageBase64');
      }
      return j;
    }).toList();

    final charJson = characters.map((c) {
      final j = c.toJson();
      if (c.portraitBase64.isNotEmpty) {
        j['portraitFile'] = 'portraits/${_safeFileName(c.name)}.png';
        j.remove('portraitBase64');
      }
      return j;
    }).toList();

    return {
      'version': 2,
      'format': 'zip',
      'createdAt': createdAt,
      'characters': charJson,
      'maps': mapJson,
      'items': items.map((i) => i.toJson()).toList(),
      if (playerPositions.isNotEmpty)
        'playerPositions': playerPositions.map((p) => p.toJson()).toList(),
      'rules': rules.toJson(),
    };
  }

  /// Read a ZIP archive and reconstruct SaveData with images loaded
  /// into base64 fields.
  static Future<SaveData> fromZip(String path) async {
    final bytes = await File(path).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // Find save.json
    final manifestFile = archive.findFile('save.json');
    if (manifestFile == null) {
      throw FormatException('ZIP 存档中缺少 save.json');
    }

    final manifest =
        jsonDecode(utf8.decode(manifestFile.content as List<int>))
            as Map<String, dynamic>;

    // Load maps, injecting imageBase64 from ZIP image entries
    final maps = <MapData>[];
    for (final m in (manifest['maps'] as List<dynamic>? ?? <dynamic>[])) {
      final j = m as Map<String, dynamic>;
      final imageFile = j['imageFile'] as String?;
      if (imageFile != null) {
        final img = archive.findFile(imageFile);
        if (img != null) {
          j['imageBase64'] = base64Encode(img.content as List<int>);
        }
      }
      j.remove('imageFile');
      maps.add(MapData.fromJson(j));
    }

    // Load characters, injecting portraitBase64 from ZIP image entries
    final characters = <CharacterData>[];
    for (final c in (manifest['characters'] as List<dynamic>? ?? <dynamic>[])) {
      final j = c as Map<String, dynamic>;
      final portraitFile = j['portraitFile'] as String?;
      if (portraitFile != null) {
        final img = archive.findFile(portraitFile);
        if (img != null) {
          j['portraitBase64'] = base64Encode(img.content as List<int>);
        }
      }
      j.remove('portraitFile');
      characters.add(CharacterData.fromJson(j));
    }

    return SaveData(
      version: manifest['version'] as int? ?? 1,
      createdAt:
          manifest['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      characters: characters,
      maps: maps,
      items:
          (manifest['items'] as List<dynamic>?)
              ?.map((i) => ItemData.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      playerPositions:
          (manifest['playerPositions'] as List<dynamic>?)
              ?.map((p) => PlayerPosition.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      rules: manifest.containsKey('rules')
          ? RuleData.fromJson(manifest['rules'] as Map<String, dynamic>)
          : const RuleData(),
    );
  }

  /// Sanitize a name for use as a file name inside the ZIP.
  static String _safeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
  }
}
