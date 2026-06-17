import 'equipment_data.dart';
import 'item_data.dart';
import 'skill_data.dart';

/// 规则数据模型 — 回合设置、环节设置、背包格子上限、物品/装备/技能模板
class RuleData {
  /// 回合设置 (暂时留空)
  final List<String> turnSettings;

  /// 环节设置 (默认：先攻、战斗)
  final List<String> phaseSettings;

  /// 背包物品栏格子上限 (默认 40)
  final int backpackSlotMax;

  /// 物品模板库 (主持在此定义可用物品，角色从中选择)
  final List<ItemData> itemTemplates;

  /// 装备栏位置名称列表 (如 头盔、身甲、手甲、腿甲、饰品)
  final List<String> equipmentSlots;

  /// 装备模板库
  final List<EquipmentData> equipmentTemplates;

  /// 技能模板库 (主持在此定义可用技能，角色从中选择)
  final List<SkillData> skillTemplates;

  /// 伤害类型池 (主持在此定义，技能模板从中选择伤害类型)
  final List<String> damageTypes;

  const RuleData({
    this.turnSettings = const [],
    this.phaseSettings = const ['先攻', '战斗'],
    this.backpackSlotMax = 40,
    this.itemTemplates = const [],
    this.equipmentSlots = const ['头盔', '身甲', '手甲', '腿甲', '饰品'],
    this.equipmentTemplates = const [],
    this.skillTemplates = const [],
    this.damageTypes = const ['火焰', '寒冷', '雷电', '毒素', '暗蚀', '光耀', '力场', '精神', '坏死', '穿刺', '挥砍', '钝击'],
  });

  Map<String, dynamic> toJson() => {
    if (turnSettings.isNotEmpty) 'turnSettings': turnSettings,
    'phaseSettings': phaseSettings,
    'backpackSlotMax': backpackSlotMax,
    if (itemTemplates.isNotEmpty)
      'itemTemplates': itemTemplates.map((i) => i.toJson()).toList(),
    if (equipmentSlots.isNotEmpty) 'equipmentSlots': equipmentSlots,
    if (equipmentTemplates.isNotEmpty)
      'equipmentTemplates':
          equipmentTemplates.map((e) => e.toJson()).toList(),
    if (skillTemplates.isNotEmpty)
      'skillTemplates': skillTemplates.map((s) => s.toJson()).toList(),
    if (damageTypes.isNotEmpty) 'damageTypes': damageTypes,
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
    backpackSlotMax: json['backpackSlotMax'] as int? ?? 40,
    itemTemplates:
        (json['itemTemplates'] as List<dynamic>?)
            ?.map((i) => ItemData.fromJson(i as Map<String, dynamic>))
            .toList() ??
        const [],
    equipmentSlots:
        (json['equipmentSlots'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        const ['头盔', '身甲', '手甲', '腿甲', '饰品'],
    equipmentTemplates:
        (json['equipmentTemplates'] as List<dynamic>?)
            ?.map(
                (e) => EquipmentData.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    skillTemplates:
        (json['skillTemplates'] as List<dynamic>?)
            ?.map(
                (s) => SkillData.fromJson(s as Map<String, dynamic>))
            .toList() ??
        const [],
    damageTypes:
        (json['damageTypes'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        const ['火焰', '寒冷', '雷电', '毒素', '暗蚀', '光耀', '力场', '精神', '坏死', '穿刺', '挥砍', '钝击'],
  );
}
