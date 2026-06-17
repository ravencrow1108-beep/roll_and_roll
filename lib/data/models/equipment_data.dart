import 'item_data.dart';

/// 装备数据模型 — 继承物品所有属性，额外多出装备位置。
class EquipmentData {
  /// 物品基础属性
  final String name;
  final String imageBase64;
  final String type;
  final String effect;
  final String description;
  final int weight;
  final int value;

  /// 装备提供的护甲值 (Armor Class)
  final int ac;

  /// 装备位置（如 头盔、手甲、身甲、腿甲、饰品）
  final String slot;

  const EquipmentData({
    this.name = '无名装备',
    this.imageBase64 = '',
    this.type = '防具',
    this.effect = '',
    this.description = '',
    this.weight = 0,
    this.value = 0,
    this.ac = 0,
    this.slot = '饰品',
  });

  /// 转换为纯物品（丢掉 slot / ac 信息）
  ItemData toItem() => ItemData(
        name: name,
        imageBase64: imageBase64,
        type: type,
        effect: effect,
        description: description,
        weight: weight,
        value: value,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        if (imageBase64.isNotEmpty) 'imageBase64': imageBase64,
        'type': type,
        if (effect.isNotEmpty) 'effect': effect,
        if (description.isNotEmpty) 'description': description,
        'weight': weight,
        'value': value,
        if (ac > 0) 'ac': ac,
        'slot': slot,
      };

  factory EquipmentData.fromJson(Map<String, dynamic> json) {
    return EquipmentData(
      name: json['name'] as String? ?? '无名装备',
      imageBase64: json['imageBase64'] as String? ?? '',
      type: json['type'] as String? ?? '防具',
      effect: json['effect'] as String? ?? '',
      description: json['description'] as String? ?? '',
      weight: json['weight'] as int? ?? 0,
      value: json['value'] as int? ?? 0,
      ac: json['ac'] as int? ?? 0,
      slot: json['slot'] as String? ?? '饰品',
    );
  }
}
