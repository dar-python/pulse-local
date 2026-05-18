class MenuItem {
  const MenuItem({
    required this.id,
    this.restaurantId = 0,
    required this.name,
    required this.description,
    required this.price,
    required this.emoji,
    required this.category,
    this.isAvailable = true,
  });

  final int id;
  final int restaurantId;
  final String name;
  final String description;
  final int price;
  final String emoji;
  final String category;
  final bool isAvailable;

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: (json['id'] as num).toInt(),
      restaurantId:
          (json['restaurant_id'] as num?)?.toInt() ??
          (json['restaurantId'] as num?)?.toInt() ??
          0,
      name: json['name']?.toString() ?? 'Menu item',
      description: json['description']?.toString() ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      emoji: json['emoji']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Bestsellers',
      isAvailable: json['is_available'] != false,
    );
  }
}
