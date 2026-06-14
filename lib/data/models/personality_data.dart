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
