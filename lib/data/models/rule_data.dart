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
