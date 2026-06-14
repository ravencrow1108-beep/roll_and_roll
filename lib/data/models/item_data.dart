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
