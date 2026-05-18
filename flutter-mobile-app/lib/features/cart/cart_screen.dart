import 'package:flutter/material.dart';

import '../../core/data/mock_foodpulse_data.dart';
import '../../core/models/cart_item.dart';
import '../../core/models/restaurant.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/primary_button.dart';
import '../checkout/checkout_screen.dart';
import '../checkout/repositories/foodpulse_checkout_risk_repository.dart';
import '../foodpulse/repositories/foodpulse_repository.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key, Restaurant? restaurant, List<CartItem>? items})
    : _restaurant = restaurant,
      _items = items;

  final Restaurant? _restaurant;
  final List<CartItem>? _items;

  @override
  Widget build(BuildContext context) {
    final restaurant = _restaurant ?? MockFoodPulseData.restaurants.first;
    final items = _items ?? MockFoodPulseData.defaultCart;
    final isCartEmpty = items.isEmpty;
    final subtotal = MockFoodPulseData.subtotalFor(items);
    final total = MockFoodPulseData.totalFor(items);

    return Scaffold(
      backgroundColor: AppColors.prussian,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                title: 'My Cart',
                onBack: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Row(
                  children: [
                    Text(
                      restaurant.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            restaurant.name,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${restaurant.deliveryTime} · ₱${MockFoodPulseData.deliveryFee} delivery',
                            style: const TextStyle(
                              color: AppColors.silver,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (isCartEmpty)
                const _EmptyCartState()
              else ...[
                for (final cartItem in items)
                  _CartItemRow(
                    emoji: cartItem.item.emoji,
                    name: cartItem.item.name,
                    price: cartItem.item.price,
                    quantity: cartItem.quantity,
                    lineTotal: cartItem.lineTotal,
                  ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Summary',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _SummaryRow(label: 'Subtotal', value: subtotal),
                      const SizedBox(height: 6),
                      const _SummaryRow(
                        label: 'Delivery Fee',
                        value: MockFoodPulseData.deliveryFee,
                      ),
                      const SizedBox(height: 6),
                      const _SummaryRow(
                        label: 'Service Charge',
                        value: MockFoodPulseData.serviceCharge,
                      ),
                      Divider(height: 20, color: AppColors.white.withAlpha(16)),
                      _SummaryRow(
                        label: 'Total',
                        value: total,
                        emphasized: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                CustomPaint(
                  painter: _DashedBorderPainter(),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 12,
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.local_offer_outlined,
                          color: AppColors.orange,
                          size: 18,
                        ),
                        SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'Add promo code',
                            style: TextStyle(
                              color: AppColors.silver,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.add_rounded,
                          color: AppColors.orange,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                PrimaryButton(
                  label: 'Proceed to Checkout →',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CheckoutScreen(
                        restaurant: restaurant,
                        items: items,
                        checkoutRiskRepository:
                            FoodPulseCheckoutRiskScope.maybeOf(context),
                        foodPulseRepository: FoodPulseRepositoryScope.maybeOf(
                          context,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCartState extends StatelessWidget {
  const _EmptyCartState();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shopping_cart_outlined, color: AppColors.orange, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your cart is empty.',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Add at least one dish before moving to checkout.',
                  style: TextStyle(
                    color: AppColors.silver,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onBack,
          child: const SizedBox(
            width: 36,
            height: 36,
            child: Icon(Icons.arrow_back_rounded, color: AppColors.white),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _CartItemRow extends StatelessWidget {
  const _CartItemRow({
    required this.emoji,
    required this.name,
    required this.price,
    required this.quantity,
    required this.lineTotal,
  });

  final String emoji;
  final String name;
  final int price;
  final int quantity;
  final int lineTotal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.white.withAlpha(14)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.dusk.withAlpha(96),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '₱$price × $quantity',
                  style: const TextStyle(color: AppColors.silver, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '₱$lineTotal',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final int value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: emphasized ? AppColors.white : AppColors.silver,
            fontSize: emphasized ? 15 : 12,
            fontWeight: emphasized ? FontWeight.w900 : FontWeight.w500,
          ),
        ),
        Text(
          '₱$value',
          style: TextStyle(
            color: emphasized ? AppColors.orange : AppColors.white,
            fontSize: emphasized ? 15 : 12,
            fontWeight: emphasized ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.dusk
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(8),
    );
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 7), paint);
        distance += 12;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
