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
