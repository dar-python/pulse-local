import '../constants/foodpulse_image_assets.dart';

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
    this.imageAsset,
  });

  final int id;
  final int restaurantId;
  final String name;
  final String description;
  final int price;
  final String emoji;
  final String category;
  final bool isAvailable;
  final String? imageAsset;

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as num).toInt();
    final name = json['name']?.toString() ?? 'Menu item';

    return MenuItem(
      id: id,
      restaurantId:
          (json['restaurant_id'] as num?)?.toInt() ??
          (json['restaurantId'] as num?)?.toInt() ??
          0,
      name: name,
      description: json['description']?.toString() ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      emoji: json['emoji']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Bestsellers',
      isAvailable: json['is_available'] != false,
      imageAsset:
          _stringOrNull(json['image_asset'] ?? json['imageAsset']) ??
          FoodPulseImageAssets.menuItemAsset(
            id: id,
            name: name,
            slug: _stringOrNull(json['slug']),
          ),
    );
  }
}

String? _stringOrNull(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}
