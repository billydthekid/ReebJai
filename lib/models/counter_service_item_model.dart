class CounterServiceItemModel {
  final String itemId;
  final String categoryId;
  final String name;
  final String description;
  final String icon;
  final double fee;
  final bool isActive;

  CounterServiceItemModel({
    required this.itemId,
    required this.categoryId,
    required this.name,
    this.description = '',
    this.icon = '',
    this.fee = 0,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'categoryId': categoryId,
      'name': name,
      'description': description,
      'icon': icon,
      'fee': fee,
      'isActive': isActive,
    };
  }

  factory CounterServiceItemModel.fromMap(Map<String, dynamic> map) {
    return CounterServiceItemModel(
      itemId: map['itemId'] ?? '',
      categoryId: map['categoryId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '',
      fee: (map['fee'] ?? 0).toDouble(),
      isActive: map['isActive'] ?? true,
    );
  }
}
