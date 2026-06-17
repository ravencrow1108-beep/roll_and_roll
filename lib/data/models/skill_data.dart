/// 技能伤害条目 — 一个表达式对应一种伤害类型
class SkillDamage {
  final String? expression;
  final String? damageType;

  const SkillDamage({this.expression, this.damageType});

  Map<String, dynamic> toJson() => {
    if (expression != null) 'expression': expression,
    if (damageType != null) 'damageType': damageType,
  };

  factory SkillDamage.fromJson(Map<String, dynamic> json) => SkillDamage(
    expression: json['expression'] as String?,
    damageType: json['damageType'] as String?,
  );
}

/// 技能数据模型
class SkillData {
  final String name;
  final String? description;
  final String? imageBase64;
  final List<SkillDamage> damages;

  const SkillData({
    required this.name,
    this.description,
    this.imageBase64,
    this.damages = const [],
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    if (description != null) 'description': description,
    if (imageBase64 != null) 'imageBase64': imageBase64,
    if (damages.isNotEmpty) 'damages': damages.map((d) => d.toJson()).toList(),
  };

  factory SkillData.fromJson(Map<String, dynamic> json) => SkillData(
    name: json['name'] as String,
    description: json['description'] as String?,
    imageBase64: json['imageBase64'] as String?,
    damages: (json['damages'] as List<dynamic>?)
            ?.map((d) => SkillDamage.fromJson(d as Map<String, dynamic>))
            .toList() ??
        const [],
  );
}
