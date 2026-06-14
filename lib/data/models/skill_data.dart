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
