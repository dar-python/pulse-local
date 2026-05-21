import '../constants/foodpulse_image_assets.dart';

class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.rating,
    required this.deliveryTime,
    required this.minimumOrder,
    this.distance = '1.2 km',
    this.deliveryFee = 49,
    required this.emoji,
    required this.riskScore,
    this.branchAddress,
    this.imageAsset,
    this.latitude,
    this.longitude,
  });

  final int id;
  final String name;
  final String cuisine;
  final double rating;
  final String deliveryTime;
  final int minimumOrder;
  final String distance;
  final int deliveryFee;
  final String emoji;
  final int riskScore;
  final String? branchAddress;
  final String? imageAsset;
  final double? latitude;
  final double? longitude;

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
      distance: json['distance']?.toString() ?? '1.2 km',
      deliveryFee:
          (json['delivery_fee'] as num?)?.toInt() ??
          (json['deliveryFee'] as num?)?.toInt() ??
          49,
      emoji: json['emoji']?.toString() ?? '',
      riskScore:
          (json['risk_score'] as num?)?.toInt() ??
          (json['riskScore'] as num?)?.toInt() ??
          0,
      branchAddress: _stringOrNull(
        json['branch_address'] ?? json['branchAddress'],
      ),
      imageAsset:
          _stringOrNull(json['image_asset'] ?? json['imageAsset']) ??
          FoodPulseImageAssets.restaurantAsset(
            id: id,
            name: name,
            slug: _stringOrNull(json['slug']),
          ),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

String? _stringOrNull(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}
