import '../../../core/models/cart_item.dart';
import '../../../core/models/restaurant.dart';
import '../../foodpulse/models/foodpulse_order.dart';

class CheckoutRiskCartItem {
  const CheckoutRiskCartItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unitPrice,
  });

  final int id;
  final String name;
  final String category;
  final int quantity;
  final int unitPrice;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'quantity': quantity,
      'unit_price': unitPrice,
    };
  }
}

class CheckoutRiskDeliveryAddress {
  const CheckoutRiskDeliveryAddress({required this.label, this.notes});

  final String label;
  final String? notes;

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes,
    };
  }
}

class CheckoutRiskRequest {
  const CheckoutRiskRequest({
    this.restaurantId = 1,
    this.restaurantSlug = 'tambayan-grill',
    this.items = const [
      CheckoutRiskCartItem(
        id: 1,
        name: 'Pork Sinigang',
        category: 'Bestsellers',
        quantity: 1,
        unitPrice: 185,
      ),
    ],
    this.deliveryAddress = const CheckoutRiskDeliveryAddress(
      label: 'Marasbaras, Tacloban City',
      notes: 'Zone 7, Leyte, Philippines',
    ),
    this.paymentMethod = 'cod',
    this.subtotal = 185,
    this.totalQuantity = 1,
    this.riderToOrderRatio = 0.45,
    this.merchantPrepTime = 25,
    this.trafficCorridorIntensity = 'high',
    this.weatherCategory = 'rainy',
    this.deliveryDistanceKm = 4.2,
    this.addressComplexity = 'medium',
  });

  factory CheckoutRiskRequest.fromCheckoutContext({
    required Restaurant restaurant,
    required List<CartItem> items,
    required FoodPulseDeliveryAddress deliveryAddress,
    required String paymentMethod,
  }) {
    final riskItems = items
        .map(
          (item) => CheckoutRiskCartItem(
            id: item.item.id,
            name: item.item.name,
            category: item.item.category,
            quantity: item.quantity,
            unitPrice: item.item.price,
          ),
        )
        .toList(growable: false);

    return CheckoutRiskRequest(
      restaurantId: restaurant.id,
      restaurantSlug: _slugFor(restaurant.name),
      items: riskItems,
      deliveryAddress: CheckoutRiskDeliveryAddress(
        label: deliveryAddress.label,
        notes: deliveryAddress.notes,
      ),
      paymentMethod: paymentMethod,
      subtotal: items.fold(0, (sum, item) => sum + item.lineTotal),
      totalQuantity: items.fold(0, (sum, item) => sum + item.quantity),
    );
  }

  final int restaurantId;
  final String restaurantSlug;
  final List<CheckoutRiskCartItem> items;
  final CheckoutRiskDeliveryAddress deliveryAddress;
  final String paymentMethod;
  final int subtotal;
  final int totalQuantity;

  // Legacy fields retained for the older standalone risk demo controller.
  final double riderToOrderRatio;
  final int merchantPrepTime;
  final String trafficCorridorIntensity;
  final String weatherCategory;
  final double deliveryDistanceKm;
  final String addressComplexity;

  Map<String, dynamic> toJson() {
    return {
      'restaurant_id': restaurantId,
      'restaurant_slug': restaurantSlug,
      'items': items.map((item) => item.toJson()).toList(growable: false),
      'delivery_address': deliveryAddress.toJson(),
      'payment_method': paymentMethod,
      'subtotal': subtotal,
      'total_quantity': totalQuantity,
    };
  }

  static String _slugFor(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}
