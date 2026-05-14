class CheckoutRiskRequest {
  const CheckoutRiskRequest({
    required this.riderToOrderRatio,
    required this.merchantPrepTime,
    required this.trafficLevel,
    required this.weatherCategory,
    required this.deliveryDistanceKm,
    required this.paymentMethod,
  });

  final double riderToOrderRatio;
  final int merchantPrepTime;
  final String trafficLevel;
  final String weatherCategory;
  final double deliveryDistanceKm;
  final String paymentMethod;

  Map<String, dynamic> toJson() {
    return {
      'rider_to_order_ratio': riderToOrderRatio,
      'merchant_prep_time': merchantPrepTime,
      'traffic_level': trafficLevel,
      'weather_category': weatherCategory,
      'delivery_distance_km': deliveryDistanceKm,
      'payment_method': paymentMethod,
    };
  }
}
