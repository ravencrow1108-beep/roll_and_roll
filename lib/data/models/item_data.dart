/// 物品数据模型
class ItemData {
  final String name;
  final String imageBase64;
  final String type;
  final String effect;
  final String description;
  final int quantity;
  final int weight;
  final int value;

  const ItemData({
    this.name = '无名物品',
    this.imageBase64 = '',
    this.type = '杂物',
    this.effect = '',
    this.description = '',
    this.quantity = 1,
    this.weight = 0,
    this.value = 0,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    if (imageBase64.isNotEmpty) 'imageBase64': imageBase64,
    'type': type,
    if (effect.isNotEmpty) 'effect': effect,
    if (description.isNotEmpty) 'description': description,
    'quantity': quantity,
    'weight': weight,
    'value': value,
  };

  factory ItemData.fromJson(Map<String, dynamic> json) {
    return ItemData(
      name: json['name'] as String? ?? '无名物品',
      imageBase64: json['imageBase64'] as String? ?? '',
      type: json['type'] as String? ?? '杂物',
      effect: json['effect'] as String? ?? '',
      description: json['description'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 1,
      weight: json['weight'] as int? ?? 0,
      value: json['value'] as int? ?? 0,
    );
  }
}
