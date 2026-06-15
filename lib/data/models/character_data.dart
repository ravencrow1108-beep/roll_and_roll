import 'item_data.dart';
import 'personality_data.dart';
import 'skill_data.dart';

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

  /// GM 留下的注释（多条竖直叠加显示）
  final List<String> notes;

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
    this.notes = const [],
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
    if (notes.isNotEmpty) 'notes': notes,
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
      notes: (json['notes'] as List<dynamic>?)
              ?.map((n) => n.toString())
              .toList() ??
          (json['note'] is String ? [json['note'] as String] : const []),
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
    List<String>? notes,
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
    notes: notes ?? this.notes,
    portraitBase64: portraitBase64 ?? this.portraitBase64,
  );
}
