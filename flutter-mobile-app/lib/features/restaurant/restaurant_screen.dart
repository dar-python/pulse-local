import 'package:flutter/material.dart';

import '../../core/data/mock_foodpulse_data.dart';
import '../../core/models/menu_item.dart';
import '../../core/models/restaurant.dart';
import '../../core/models/risk_info.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/foodpulse_asset_image.dart';
import '../../shared/widgets/primary_button.dart';
import '../cart/cart_screen.dart';
import '../cart/foodpulse_cart_controller.dart';
import '../foodpulse/models/foodpulse_order.dart';
import '../foodpulse/repositories/foodpulse_repository.dart';

class RestaurantScreen extends StatefulWidget {
  const RestaurantScreen({
    super.key,
    Restaurant? restaurant,
    FoodPulseCartController? cartController,
    FoodPulseDeliveryAddress? deliveryAddress,
    ValueChanged<OrderConfirmation>? onOrderPlaced,
  }) : _restaurant = restaurant,
       _cartController = cartController,
       _deliveryAddress = deliveryAddress,
       _onOrderPlaced = onOrderPlaced;

  final Restaurant? _restaurant;
  final FoodPulseCartController? _cartController;
  final FoodPulseDeliveryAddress? _deliveryAddress;
  final ValueChanged<OrderConfirmation>? _onOrderPlaced;

  @override
  State<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> {
  static const _defaultTabs = ['Bestsellers', 'Specials', 'Desserts'];

  late final Restaurant _restaurant;
  late final FoodPulseCartController _cartController;
  late final bool _ownsCartController;
  late FoodPulseRepository _repository;
  List<MenuItem> _menuItems = const [];
  String _selectedTab = 'Bestsellers';
  bool _didLoadMenu = false;
  bool _isLoadingMenu = true;
  String? _menuMessage;

  @override
  void initState() {
    super.initState();
    _restaurant = widget._restaurant ?? MockFoodPulseData.restaurants.first;
    _menuItems = MockFoodPulseData.menuItemsFor(_restaurant.id);
    _ownsCartController = widget._cartController == null;
    _cartController = widget._cartController ?? FoodPulseCartController();
    _cartController.addListener(_handleCartChanged);
  }

  @override
  void dispose() {
    _cartController.removeListener(_handleCartChanged);
    if (_ownsCartController) {
      _cartController.dispose();
    }
    super.dispose();
  }

  void _handleCartChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadMenu) {
      return;
    }

    _didLoadMenu = true;
    _repository =
        FoodPulseRepositoryScope.maybeOf(context) ??
        LaravelFoodPulseRepository();
    _loadMenu();
  }

  int get _cartCount => _cartController.quantityForRestaurant(_restaurant);

  int get _cartTotal => _cartController.subtotalForRestaurant(_restaurant);

  Future<void> _loadMenu() async {
    try {
      final result = await _repository.fetchMenu(_restaurant.id);
      if (!mounted) {
        return;
      }

      setState(() {
        _menuItems = result.data.items;
        _menuMessage = result.usedFallback ? result.message : null;
        _isLoadingMenu = false;

        final tabs = _tabsFor(_menuItems);
        if (!tabs.contains(_selectedTab)) {
          _selectedTab = tabs.first;
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _menuItems = MockFoodPulseData.menuItemsFor(_restaurant.id);
        _menuMessage = 'Using saved local menu data.';
        _isLoadingMenu = false;
      });
    }
  }

  List<String> _tabsFor(List<MenuItem> items) {
    final categories = items
        .where((item) => item.isAvailable)
        .map((item) => item.category)
        .where((category) => category.trim().isNotEmpty)
        .toSet()
        .toList();

    return categories.isEmpty ? _defaultTabs : categories;
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabsFor(_menuItems);
    final visibleItems = _menuItems
        .where((item) => item.isAvailable && item.category == _selectedTab)
        .toList();
    final risk = RiskInfo.fromScore(_restaurant.riskScore);

    return Scaffold(
      backgroundColor: AppColors.prussian,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _RestaurantHero(
              emoji: _restaurant.emoji,
              imageAsset: _restaurant.imageAsset,
              onBack: () => Navigator.of(context).pop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _restaurant.name,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _restaurant.cuisine,
                              style: const TextStyle(
                                color: AppColors.silver,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: AppColors.orange,
                                size: 15,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                _restaurant.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: AppColors.orange,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _restaurant.deliveryTime,
                            style: const TextStyle(
                              color: AppColors.silver,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: risk.color.withAlpha(38),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: risk.color.withAlpha(72)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 15,
                          color: risk.color,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${risk.label} fulfillment risk (${risk.score}%) / ETA on track',
                            style: TextStyle(
                              color: risk.color,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _MenuTabs(
              tabs: tabs,
              selected: _selectedTab,
              onChanged: (tab) => setState(() => _selectedTab = tab),
            ),
            if (_isLoadingMenu || _menuMessage != null)
              _MenuStatusBanner(
                isLoading: _isLoadingMenu,
                message: _menuMessage,
              ),
            Expanded(
              child: visibleItems.isEmpty && !_isLoadingMenu
                  ? const _EmptyMenuState()
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        18,
                        8,
                        18,
                        _cartCount > 0 ? 92 : 20,
                      ),
                      itemBuilder: (context, index) => _MenuItemRow(
                        item: visibleItems[index],
                        quantity: _cartController.quantityForItem(
                          visibleItems[index],
                        ),
                        onAdd: () => _addMenuItem(visibleItems[index]),
                        onRemove: () =>
                            _cartController.decreaseItem(visibleItems[index]),
                      ),
                      separatorBuilder: (_, _) => Divider(
                        color: AppColors.white.withAlpha(14),
                        height: 1,
                      ),
                      itemCount: visibleItems.length,
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _cartCount > 0
          ? SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                color: AppColors.prussian,
                child: PrimaryButton(
                  label: 'View Cart',
                  leading: _CountBubble(count: _cartCount),
                  trailing: Text(
                    '₱$_cartTotal',
                    style: const TextStyle(
                      color: AppColors.prussian,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CartScreen(
                        restaurant: _restaurant,
                        cartController: _cartController,
                        deliveryAddress: widget._deliveryAddress,
                        onOrderPlaced: widget._onOrderPlaced,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _addMenuItem(MenuItem item) async {
    if (_cartController.hasDifferentRestaurant(_restaurant)) {
      final shouldClear = await _showClearCartDialog();
      if (shouldClear != true) {
        return;
      }

      _cartController.addItem(
        restaurant: _restaurant,
        item: item,
        clearExisting: true,
      );
      return;
    }

    _cartController.addItem(restaurant: _restaurant, item: item);
  }

  Future<bool?> _showClearCartDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.prussian,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: AppColors.orange.withAlpha(96)),
          ),
          title: const Text(
            'Start a new order?',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'Starting a new order will clear your current cart.',
            style: TextStyle(
              color: AppColors.silver,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.silver,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Clear Cart and Add Item',
                style: TextStyle(
                  color: AppColors.orange,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RestaurantHero extends StatelessWidget {
  const _RestaurantHero({
    required this.emoji,
    required this.imageAsset,
    required this.onBack,
  });

  final String emoji;
  final String? imageAsset;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 124,
      color: AppColors.dusk,
      child: Stack(
        children: [
          Positioned.fill(
            child: FoodPulseAssetImage(
              imageAsset: imageAsset,
              fallbackLabel: emoji,
              borderRadius: BorderRadius.zero,
              backgroundColor: AppColors.dusk,
              fallbackTextStyle: const TextStyle(
                color: AppColors.white,
                fontSize: 54,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.prussian.withAlpha(18),
                    AppColors.prussian.withAlpha(154),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            top: 12,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onBack,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.prussian.withAlpha(190),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.white,
                  size: 19,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuStatusBanner extends StatelessWidget {
  const _MenuStatusBanner({required this.isLoading, required this.message});

  final bool isLoading;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        color: AppColors.white.withAlpha(11),
        borderColor: isLoading
            ? AppColors.orange.withAlpha(48)
            : AppColors.white.withAlpha(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLoading)
              const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.orange,
                ),
              )
            else
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.orange,
                size: 16,
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLoading ? 'Loading menu' : 'Saved menu in use',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isLoading
                        ? 'Fetching dishes from Laravel local data...'
                        : message ?? 'Using saved local menu data.',
                    style: const TextStyle(
                      color: AppColors.silver,
                      fontSize: 11,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMenuState extends StatelessWidget {
  const _EmptyMenuState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.restaurant_menu, color: AppColors.orange, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No menu items are available right now.',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'This restaurant is reachable, but no local dishes were returned.',
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
        ),
      ),
    );
  }
}

class _MenuTabs extends StatelessWidget {
  const _MenuTabs({
    required this.tabs,
    required this.selected,
    required this.onChanged,
  });

  final List<String> tabs;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.white.withAlpha(16)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final tab in tabs)
              InkWell(
                onTap: () => onChanged(tab),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: selected == tab
                            ? AppColors.orange
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    tab,
                    style: TextStyle(
                      color: selected == tab
                          ? AppColors.orange
                          : AppColors.silver,
                      fontSize: 12,
                      fontWeight: selected == tab
                          ? FontWeight.w900
                          : FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MenuItemRow extends StatelessWidget {
  const _MenuItemRow({
    required this.item,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  final MenuItem item;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
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
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: const TextStyle(
                    color: AppColors.silver,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '₱${item.price}',
                  style: const TextStyle(
                    color: AppColors.orange,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FoodPulseAssetImage(
                  imageAsset: item.imageAsset,
                  fallbackLabel: item.emoji,
                  width: 66,
                  height: 66,
                  backgroundColor: AppColors.dusk.withAlpha(112),
                  fallbackTextStyle: const TextStyle(
                    color: AppColors.white,
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Positioned(
                right: -8,
                bottom: -8,
                child: quantity == 0
                    ? _MenuQuantityButton(icon: Icons.add_rounded, onTap: onAdd)
                    : Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: AppColors.orange,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _MenuQuantityButton(
                              icon: quantity == 1
                                  ? Icons.delete_outline_rounded
                                  : Icons.remove_rounded,
                              onTap: onRemove,
                              compact: true,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                              ),
                              child: Text(
                                '$quantity',
                                style: const TextStyle(
                                  color: AppColors.prussian,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            _MenuQuantityButton(
                              icon: Icons.add_rounded,
                              onTap: onAdd,
                              compact: true,
                            ),
                          ],
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

class _MenuQuantityButton extends StatelessWidget {
  const _MenuQuantityButton({
    required this.icon,
    required this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: compact ? 22 : 28,
        height: compact ? 22 : 28,
        decoration: BoxDecoration(
          color: compact ? AppColors.prussian.withAlpha(24) : AppColors.orange,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.prussian, size: compact ? 15 : 20),
      ),
    );
  }
}

class _CountBubble extends StatelessWidget {
  const _CountBubble({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: AppColors.prussian.withAlpha(60),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: const TextStyle(
          color: AppColors.prussian,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
