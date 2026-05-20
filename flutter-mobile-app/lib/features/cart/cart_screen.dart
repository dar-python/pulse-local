import 'package:flutter/material.dart';

import '../../core/data/mock_foodpulse_data.dart';
import '../../core/models/cart_item.dart';
import '../../core/models/restaurant.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/foodpulse_asset_image.dart';
import '../../shared/widgets/primary_button.dart';
import '../checkout/checkout_screen.dart';
import '../checkout/repositories/foodpulse_checkout_risk_repository.dart';
import '../foodpulse/models/foodpulse_order.dart';
import '../foodpulse/repositories/foodpulse_repository.dart';
import 'foodpulse_cart_controller.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({
    super.key,
    Restaurant? restaurant,
    List<CartItem>? items,
    FoodPulseCartController? cartController,
    FoodPulseDeliveryAddress? deliveryAddress,
    ValueChanged<OrderConfirmation>? onOrderPlaced,
  }) : _restaurant = restaurant,
       _items = items,
       _cartController = cartController,
       _deliveryAddress = deliveryAddress,
       _onOrderPlaced = onOrderPlaced;

  final Restaurant? _restaurant;
  final List<CartItem>? _items;
  final FoodPulseCartController? _cartController;
  final FoodPulseDeliveryAddress? _deliveryAddress;
  final ValueChanged<OrderConfirmation>? _onOrderPlaced;

  @override
  Widget build(BuildContext context) {
    if (_cartController == null) {
      return _buildCart(context);
    }

    final cartController = _cartController;
    return AnimatedBuilder(
      animation: cartController,
      builder: (context, _) => _buildCart(context),
    );
  }

  Widget _buildCart(BuildContext context) {
    final cartController = _cartController;
    final restaurant =
        cartController?.restaurant ??
        _restaurant ??
        MockFoodPulseData.restaurants.first;
    final items = _items ?? cartController?.items ?? const <CartItem>[];
    final subtotal = MockFoodPulseData.subtotalFor(items);
    final deliveryFee = restaurant.deliveryFee;
    final serviceCharge = MockFoodPulseData.serviceCharge;
    final total = subtotal + deliveryFee + serviceCharge;

    return Scaffold(
      backgroundColor: AppColors.prussian,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(title: 'My Cart', onBack: () => Navigator.pop(context)),
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
                            '${restaurant.deliveryTime} - P$deliveryFee delivery',
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
              if (items.isEmpty)
                const _EmptyCartState()
              else ...[
                for (final cartItem in items)
                  _CartItemRow(
                    cartItem: cartItem,
                    onDecrease: cartController == null
                        ? null
                        : () => cartController.decreaseItem(cartItem.item),
                    onIncrease: cartController == null
                        ? null
                        : () => cartController.addItem(
                            restaurant: restaurant,
                            item: cartItem.item,
                          ),
                    onRemove: cartController == null
                        ? null
                        : () => cartController.removeItem(cartItem.item),
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
                      _SummaryRow(label: 'Delivery Fee', value: deliveryFee),
                      const SizedBox(height: 6),
                      _SummaryRow(
                        label: 'Service Charge',
                        value: serviceCharge,
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
                _PromoBox(),
                const SizedBox(height: 14),
                PrimaryButton(
                  label: 'Place order - P$total',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CheckoutScreen(
                        restaurant: restaurant,
                        items: items,
                        deliveryAddress: _deliveryAddress,
                        onOrderPlaced: (order) {
                          _onOrderPlaced?.call(order);
                          _cartController?.clear();
                        },
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
    required this.cartItem,
    this.onDecrease,
    this.onIncrease,
    this.onRemove,
  });

  final CartItem cartItem;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final item = cartItem.item;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.white.withAlpha(14)),
        ),
      ),
      child: Row(
        children: [
          FoodPulseAssetImage(
            imageAsset: item.imageAsset,
            fallbackLabel: item.emoji,
            width: 44,
            height: 44,
            backgroundColor: AppColors.dusk.withAlpha(96),
            fallbackTextStyle: const TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'P${item.price} x ${cartItem.quantity}',
                  style: const TextStyle(color: AppColors.silver, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'P${cartItem.lineTotal}',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _QuantityIconButton(
                    icon: cartItem.quantity <= 1
                        ? Icons.delete_outline_rounded
                        : Icons.remove_rounded,
                    onTap: onDecrease,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${cartItem.quantity}',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _QuantityIconButton(
                    icon: Icons.add_rounded,
                    onTap: onIncrease,
                  ),
                ],
              ),
              TextButton(
                onPressed: onRemove,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(44, 24),
                ),
                child: const Text(
                  'Remove',
                  style: TextStyle(
                    color: AppColors.silver,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuantityIconButton extends StatelessWidget {
  const _QuantityIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: onTap,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: AppColors.orange,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: AppColors.prussian, size: 15),
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
          'P$value',
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

class _PromoBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        child: const Row(
          children: [
            Icon(Icons.local_offer_outlined, color: AppColors.orange, size: 18),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'Add promo code',
                style: TextStyle(color: AppColors.silver, fontSize: 12),
              ),
            ),
            Icon(Icons.add_rounded, color: AppColors.orange, size: 18),
          ],
        ),
      ),
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
