import '../../../core/models/cart_item.dart';
import '../../../core/models/menu_item.dart';
import '../../../core/models/restaurant.dart';
import '../../checkout_risk/models/risk_prediction_response.dart';

class RestaurantMenu {
  const RestaurantMenu({required this.restaurant, required this.items});

  final Restaurant restaurant;
  final List<MenuItem> items;

  factory RestaurantMenu.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final restaurant = data['restaurant'];
    final items = data['items'];

    return RestaurantMenu(
      restaurant: Restaurant.fromJson(restaurant as Map<String, dynamic>),
      items: (items as List<dynamic>? ?? [])
          .map((item) => MenuItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class FoodPulseDeliveryAddress {
  const FoodPulseDeliveryAddress({
    required this.label,
    this.notes,
    this.tag = 'Home',
  });

  final String label;
  final String? notes;
  final String tag;

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes,
    };
  }
}

class FoodPulseRider {
  const FoodPulseRider({
    required this.name,
    required this.phoneNumber,
    required this.vehicleType,
    required this.plateNumber,
    required this.rating,
    this.profileImageAsset,
  });

  final String name;
  final String phoneNumber;
  final String vehicleType;
  final String plateNumber;
  final double rating;
  final String? profileImageAsset;

  factory FoodPulseRider.fromJson(Map<String, dynamic>? json) {
    return FoodPulseRider(
      name: json?['name']?.toString() ?? 'Juan Dela Cruz',
      phoneNumber: json?['phone_number']?.toString() ?? '0917 555 0148',
      vehicleType: json?['vehicle_type']?.toString() ?? 'Motorcycle',
      plateNumber: json?['plate_number']?.toString() ?? 'ABC 1234',
      rating: (json?['rating'] as num?)?.toDouble() ?? 4.8,
      profileImageAsset: json?['profile_image_asset']?.toString(),
    );
  }
}

class CheckoutCartRequest {
  const CheckoutCartRequest({
    required this.restaurant,
    required this.items,
    required this.paymentMethod,
    required this.deliveryAddress,
  });

  final Restaurant restaurant;
  final List<CartItem> items;
  final String paymentMethod;
  final FoodPulseDeliveryAddress deliveryAddress;

  Map<String, dynamic> toJson() {
    return {
      'restaurant_id': restaurant.id,
      'items': items
          .map(
            (item) => {'menu_item_id': item.item.id, 'quantity': item.quantity},
          )
          .toList(),
      'payment_method': paymentMethod,
      'delivery_address': deliveryAddress.toJson(),
    };
  }
}

class FoodPulseOrderItem {
  const FoodPulseOrderItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.lineTotal,
  });

  final int menuItemId;
  final String name;
  final int price;
  final int quantity;
  final int lineTotal;

  factory FoodPulseOrderItem.fromJson(Map<String, dynamic> json) {
    return FoodPulseOrderItem(
      menuItemId: (json['menu_item_id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? 'Menu item',
      price: (json['price'] as num?)?.toInt() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      lineTotal: (json['line_total'] as num?)?.toInt() ?? 0,
    );
  }
}

class FoodPulseOrderRisk {
  const FoodPulseOrderRisk({
    required this.score,
    required this.level,
    required this.recommendation,
    this.advisoryMessage = '',
    this.advisoryReasons = const [],
  });

  final int score;
  final String level;
  final String recommendation;
  final String advisoryMessage;
  final List<RiskAdvisoryReason> advisoryReasons;

  factory FoodPulseOrderRisk.fromJson(Map<String, dynamic>? json) {
    final riskScore = json?['risk_score'];
    final rawScore = riskScore is num ? riskScore.toDouble() : 0.0;
    final percent = rawScore <= 1 ? rawScore * 100 : rawScore;

    return FoodPulseOrderRisk(
      score: percent.round().clamp(0, 100).toInt(),
      level: json?['risk_level']?.toString() ?? 'Unknown',
      recommendation:
          json?['recommendation']?.toString() ??
          'No recommendation was returned.',
      advisoryMessage: json?['advisory_message']?.toString() ?? '',
      advisoryReasons: (json?['advisory_reasons'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(RiskAdvisoryReason.fromJson)
          .toList(growable: false),
    );
  }
}

class CheckoutSummary {
  const CheckoutSummary({
    required this.orderNumber,
    required this.status,
    required this.restaurant,
    required this.items,
    required this.paymentMethod,
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceCharge,
    required this.total,
    required this.risk,
  });

  final String orderNumber;
  final String status;
  final Restaurant restaurant;
  final List<FoodPulseOrderItem> items;
  final String paymentMethod;
  final int subtotal;
  final int deliveryFee;
  final int serviceCharge;
  final int total;
  final FoodPulseOrderRisk risk;

  factory CheckoutSummary.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;

    return CheckoutSummary(
      orderNumber: data['order_number']?.toString() ?? '',
      status: data['status']?.toString() ?? 'ready_for_confirmation',
      restaurant: Restaurant.fromJson(
        data['restaurant'] as Map<String, dynamic>,
      ),
      items: (data['items'] as List<dynamic>? ?? [])
          .map(
            (item) => FoodPulseOrderItem.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      paymentMethod: data['payment_method']?.toString() ?? 'cod',
      subtotal: (data['subtotal'] as num?)?.toInt() ?? 0,
      deliveryFee: (data['delivery_fee'] as num?)?.toInt() ?? 0,
      serviceCharge: (data['service_charge'] as num?)?.toInt() ?? 0,
      total: (data['total'] as num?)?.toInt() ?? 0,
      risk: FoodPulseOrderRisk.fromJson(data['risk'] as Map<String, dynamic>?),
    );
  }
}

class FoodPulseTrackingStep {
  const FoodPulseTrackingStep({required this.label, required this.done});

  final String label;
  final bool done;

  factory FoodPulseTrackingStep.fromJson(Map<String, dynamic> json) {
    return FoodPulseTrackingStep(
      label: json['label']?.toString() ?? 'Order update',
      done: json['done'] == true,
    );
  }
}

class OrderConfirmation {
  const OrderConfirmation({
    required this.orderNumber,
    required this.status,
    required this.estimatedArrival,
    required this.restaurant,
    required this.items,
    required this.paymentMethod,
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceCharge,
    required this.total,
    required this.risk,
    required this.trackingSteps,
    this.rider = const FoodPulseRider(
      name: 'Juan Dela Cruz',
      phoneNumber: '0917 555 0148',
      vehicleType: 'Motorcycle',
      plateNumber: 'ABC 1234',
      rating: 4.8,
    ),
    this.orderedAt,
  });

  final String orderNumber;
  final String status;
  final String estimatedArrival;
  final Restaurant restaurant;
  final List<FoodPulseOrderItem> items;
  final String paymentMethod;
  final int subtotal;
  final int deliveryFee;
  final int serviceCharge;
  final int total;
  final FoodPulseOrderRisk risk;
  final List<FoodPulseTrackingStep> trackingSteps;
  final FoodPulseRider rider;
  final DateTime? orderedAt;

  factory OrderConfirmation.fromCheckout(CheckoutSummary checkout) {
    return OrderConfirmation(
      orderNumber: checkout.orderNumber,
      status: 'confirmed',
      estimatedArrival: '30-45 min',
      restaurant: checkout.restaurant,
      items: checkout.items,
      paymentMethod: checkout.paymentMethod,
      subtotal: checkout.subtotal,
      deliveryFee: checkout.deliveryFee,
      serviceCharge: checkout.serviceCharge,
      total: checkout.total,
      risk: checkout.risk,
      trackingSteps: const [
        FoodPulseTrackingStep(label: 'Order placed', done: true),
        FoodPulseTrackingStep(label: 'Restaurant preparing', done: true),
        FoodPulseTrackingStep(label: 'Rider picking up', done: false),
        FoodPulseTrackingStep(label: 'On the way', done: false),
        FoodPulseTrackingStep(label: 'Delivered', done: false),
      ],
      rider: const FoodPulseRider(
        name: 'Juan Dela Cruz',
        phoneNumber: '0917 555 0148',
        vehicleType: 'Motorcycle',
        plateNumber: 'ABC 1234',
        rating: 4.8,
      ),
      orderedAt: DateTime.now(),
    );
  }

  OrderConfirmation copyWith({
    String? orderNumber,
    String? status,
    String? estimatedArrival,
    Restaurant? restaurant,
    List<FoodPulseOrderItem>? items,
    String? paymentMethod,
    int? subtotal,
    int? deliveryFee,
    int? serviceCharge,
    int? total,
    FoodPulseOrderRisk? risk,
    List<FoodPulseTrackingStep>? trackingSteps,
    FoodPulseRider? rider,
    DateTime? orderedAt,
  }) {
    return OrderConfirmation(
      orderNumber: orderNumber ?? this.orderNumber,
      status: status ?? this.status,
      estimatedArrival: estimatedArrival ?? this.estimatedArrival,
      restaurant: restaurant ?? this.restaurant,
      items: items ?? this.items,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      total: total ?? this.total,
      risk: risk ?? this.risk,
      trackingSteps: trackingSteps ?? this.trackingSteps,
      rider: rider ?? this.rider,
      orderedAt: orderedAt ?? this.orderedAt,
    );
  }

  factory OrderConfirmation.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;

    return OrderConfirmation(
      orderNumber: data['order_number']?.toString() ?? '',
      status: data['status']?.toString() ?? 'confirmed',
      estimatedArrival: data['estimated_arrival']?.toString() ?? '30-45 min',
      restaurant: Restaurant.fromJson(
        data['restaurant'] as Map<String, dynamic>,
      ),
      items: (data['items'] as List<dynamic>? ?? [])
          .map(
            (item) => FoodPulseOrderItem.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      paymentMethod: data['payment_method']?.toString() ?? 'cod',
      subtotal: (data['subtotal'] as num?)?.toInt() ?? 0,
      deliveryFee: (data['delivery_fee'] as num?)?.toInt() ?? 0,
      serviceCharge: (data['service_charge'] as num?)?.toInt() ?? 0,
      total: (data['total'] as num?)?.toInt() ?? 0,
      risk: FoodPulseOrderRisk.fromJson(data['risk'] as Map<String, dynamic>?),
      trackingSteps: (data['tracking_steps'] as List<dynamic>? ?? [])
          .map(
            (step) =>
                FoodPulseTrackingStep.fromJson(step as Map<String, dynamic>),
          )
          .toList(),
      rider: FoodPulseRider.fromJson(data['rider'] as Map<String, dynamic>?),
      orderedAt:
          DateTime.tryParse(data['ordered_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
