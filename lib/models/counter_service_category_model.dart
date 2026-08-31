class CounterServiceCategoryModel {
  final String categoryId;
  final String name;
  final String icon;
  final int sortOrder;
  final bool isActive;

  CounterServiceCategoryModel({
    required this.categoryId,
    required this.name,
    this.icon = '',
    this.sortOrder = 0,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'name': name,
      'icon': icon,
      'sortOrder': sortOrder,
      'isActive': isActive,
    };
  }

  factory CounterServiceCategoryModel.fromMap(Map<String, dynamic> map) {
    return CounterServiceCategoryModel(
      categoryId: map['categoryId'] ?? '',
      name: map['name'] ?? '',
      icon: map['icon'] ?? '',
      sortOrder: map['sortOrder'] ?? 0,
      isActive: map['isActive'] ?? true,
    );
  }
}
