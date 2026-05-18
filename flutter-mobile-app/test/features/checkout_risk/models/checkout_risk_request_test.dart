import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_local_app/features/checkout_risk/models/checkout_risk_request.dart';

void main() {
  test('serializes the current checkout context for Laravel', () {
    const request = CheckoutRiskRequest(
      restaurantId: 1,
      restaurantSlug: 'tambayan-grill',
      items: [
        CheckoutRiskCartItem(
          id: 1,
          name: 'Pork Sinigang',
          category: 'Bestsellers',
          quantity: 1,
          unitPrice: 185,
        ),
        CheckoutRiskCartItem(
          id: 2,
          name: 'Chicken Inasal',
          category: 'Bestsellers',
          quantity: 2,
          unitPrice: 155,
        ),
      ],
      deliveryAddress: CheckoutRiskDeliveryAddress(
        label: 'Marasbaras, Tacloban City',
        notes: 'Zone 7, Leyte, Philippines',
      ),
      paymentMethod: 'cod',
      subtotal: 495,
      totalQuantity: 3,
    );

    final json = request.toJson();

    expect(json, {
      'restaurant_id': 1,
      'restaurant_slug': 'tambayan-grill',
      'items': [
        {
          'id': 1,
          'name': 'Pork Sinigang',
          'category': 'Bestsellers',
          'quantity': 1,
          'unit_price': 185,
        },
        {
          'id': 2,
          'name': 'Chicken Inasal',
          'category': 'Bestsellers',
          'quantity': 2,
          'unit_price': 155,
        },
      ],
      'delivery_address': {
        'label': 'Marasbaras, Tacloban City',
        'notes': 'Zone 7, Leyte, Philippines',
      },
      'payment_method': 'cod',
      'subtotal': 495,
      'total_quantity': 3,
    });
    expect(json, isNot(contains('rider_to_order_ratio')));
    expect(json, isNot(contains('merchant_prep_time')));
    expect(json, isNot(contains('delivery_distance_km')));
  });
}
