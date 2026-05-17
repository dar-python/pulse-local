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
}
