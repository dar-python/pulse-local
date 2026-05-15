class CheckoutRiskRequest {
  const CheckoutRiskRequest({
    required this.riderToOrderRatio,
    required this.merchantPrepTime,
    required this.trafficCorridorIntensity,
    required this.weatherCategory,
    required this.deliveryDistanceKm,
    required this.addressComplexity,
    required this.paymentMethod,
  });

  final double riderToOrderRatio;
  final int merchantPrepTime;
  final String trafficCorridorIntensity;
  final String weatherCategory;
  final double deliveryDistanceKm;
  final String addressComplexity;
  final String paymentMethod;

  Map<String, dynamic> toJson() {
    return {
      'rider_to_order_ratio': riderToOrderRatio,
      'merchant_prep_time': merchantPrepTime,
      'traffic_corridor_intensity': trafficCorridorIntensity,
      'weather_category': weatherCategory,
      'delivery_distance_km': deliveryDistanceKm,
      'address_complexity': addressComplexity,
      'payment_method': paymentMethod,
    };
  }
}
