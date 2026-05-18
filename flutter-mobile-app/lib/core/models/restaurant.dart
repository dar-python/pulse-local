import '../constants/foodpulse_image_assets.dart';

class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.rating,
    required this.deliveryTime,
    required this.minimumOrder,
    required this.emoji,
    required this.riskScore,
    this.imageAsset,
  });

  final int id;
  final String name;
  final String cuisine;
  final double rating;
  final String deliveryTime;
  final int minimumOrder;
  final String emoji;
  final int riskScore;
  final String? imageAsset;

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as num).toInt();
    final name = json['name']?.toString() ?? 'Restaurant';

    return Restaurant(
      id: id,
      name: name,
      cuisine: json['cuisine']?.toString() ?? 'Local Food',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      deliveryTime:
          json['delivery_time']?.toString() ??
          json['deliveryTime']?.toString() ??
          '15-25 min',
      minimumOrder:
          (json['minimum_order'] as num?)?.toInt() ??
          (json['minimumOrder'] as num?)?.toInt() ??
          0,
      emoji: json['emoji']?.toString() ?? '',
      riskScore:
          (json['risk_score'] as num?)?.toInt() ??
          (json['riskScore'] as num?)?.toInt() ??
          0,
      imageAsset:
          _stringOrNull(json['image_asset'] ?? json['imageAsset']) ??
          FoodPulseImageAssets.restaurantAsset(
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
