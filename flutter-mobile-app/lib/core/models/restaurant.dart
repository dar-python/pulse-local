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
  });

  final int id;
  final String name;
  final String cuisine;
  final double rating;
  final String deliveryTime;
  final int minimumOrder;
  final String emoji;
  final int riskScore;

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? 'Restaurant',
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
    );
  }
}
