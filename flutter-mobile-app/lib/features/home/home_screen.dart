import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/data/mock_foodpulse_data.dart';
import '../../core/models/restaurant.dart';
import '../../core/models/risk_info.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/bottom_nav.dart';
import '../../shared/widgets/foodpulse_asset_image.dart';
import '../../shared/widgets/risk_chip.dart';
import '../auth/auth_api_service.dart';
import '../auth/demo_account.dart';
import '../auth/login_screen.dart';
import '../cart/cart_screen.dart';
import '../cart/foodpulse_cart_controller.dart';
import '../foodpulse/models/foodpulse_order.dart';
import '../foodpulse/repositories/foodpulse_repository.dart';
import '../order/order_tracking_screen.dart';
import '../restaurant/restaurant_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, FoodPulseCartController? cartController})
    : _cartController = cartController;

  final FoodPulseCartController? _cartController;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  late final FoodPulseCartController _cartController;
  late final bool _ownsCartController;
  FoodPulseDeliveryAddress _selectedAddress =
      MockFoodPulseData.savedAddresses.first;
  final List<OrderConfirmation> _orders = [];

  @override
  void initState() {
    super.initState();
    _ownsCartController = widget._cartController == null;
    _cartController = widget._cartController ?? FoodPulseCartController();
  }

  @override
  void dispose() {
    if (_ownsCartController) {
      _cartController.dispose();
    }
    super.dispose();
  }

  void _recordOrder(OrderConfirmation order) {
    setState(() => _orders.insert(0, order));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnight,
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _navIndex,
              children: [
                _HomeTab(
                  cartController: _cartController,
                  selectedAddress: _selectedAddress,
                  onAddressChanged: (address) {
                    setState(() => _selectedAddress = address);
                  },
                  onOrderPlaced: _recordOrder,
                ),
                _ExploreTab(
                  cartController: _cartController,
                  selectedAddress: _selectedAddress,
                  onOrderPlaced: _recordOrder,
                ),
                _OrdersTab(orders: _orders),
                _ProfileTab(selectedAddress: _selectedAddress),
              ],
            ),
          ),
          FoodPulseBottomNav(
            currentIndex: _navIndex,
            onTap: (index) => setState(() => _navIndex = index),
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab({
    required this.cartController,
    required this.selectedAddress,
    required this.onAddressChanged,
    required this.onOrderPlaced,
  });

  final FoodPulseCartController cartController;
  final FoodPulseDeliveryAddress selectedAddress;
  final ValueChanged<FoodPulseDeliveryAddress> onAddressChanged;
  final ValueChanged<OrderConfirmation> onOrderPlaced;

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  static const _categories = [
    'All',
    'Near Me',
    'Fast Food',
    'Chicken',
    'Pizza',
    'Chinese',
  ];

  String _selectedCategory = 'All';
  List<Restaurant> _restaurants = MockFoodPulseData.restaurants;
  bool _didLoadRestaurants = false;
  bool _isLoadingRestaurants = true;
  String? _restaurantMessage;
  late FoodPulseRepository _repository;

  @override
  void initState() {
    super.initState();
    widget.cartController.addListener(_handleCartChanged);
  }

  @override
  void dispose() {
    widget.cartController.removeListener(_handleCartChanged);
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
    if (_didLoadRestaurants) {
      return;
    }
    _didLoadRestaurants = true;
    _repository =
        FoodPulseRepositoryScope.maybeOf(context) ??
        LaravelFoodPulseRepository();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    final result = await _repository.fetchRestaurants();
    if (!mounted) {
      return;
    }
    setState(() {
      _restaurants = result.data;
      _restaurantMessage = result.usedFallback ? result.message : null;
      _isLoadingRestaurants = false;
    });
  }

  List<Restaurant> get _visibleRestaurants {
    if (_selectedCategory == 'All' || _selectedCategory == 'Near Me') {
      return _restaurants;
    }

    return _restaurants
        .where(
          (restaurant) => restaurant.cuisine.toLowerCase().contains(
            _selectedCategory.toLowerCase(),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final restaurants = _visibleRestaurants;
    final featuredRestaurant = restaurants.isNotEmpty
        ? restaurants.first
        : MockFoodPulseData.restaurants.first;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LocationHeader(
              address: widget.selectedAddress,
              cartCount: widget.cartController.totalQuantity,
              onAddressTap: () => _showAddressSelector(context),
              onCartTap: () => _openCart(featuredRestaurant),
            ),
            const SizedBox(height: 14),
            const _SearchBar(),
            const SizedBox(height: 12),
            _PromoBanner(onTap: () => _openRestaurant(featuredRestaurant)),
            const SizedBox(height: 12),
            _QuickActions(),
            const SizedBox(height: 12),
            _CategoryRail(
              categories: _categories,
              selected: _selectedCategory,
              onChanged: (category) {
                setState(() => _selectedCategory = category);
              },
            ),
            const SizedBox(height: 15),
            const _SectionHeader(title: 'Restaurants Near You'),
            const SizedBox(height: 10),
            if (_isLoadingRestaurants || _restaurantMessage != null) ...[
              _DataStatusBanner(
                isLoading: _isLoadingRestaurants,
                message: _restaurantMessage,
              ),
              const SizedBox(height: 10),
            ],
            if (!_isLoadingRestaurants && restaurants.isEmpty)
              const _EmptyRestaurantsState(),
            for (final restaurant in restaurants) ...[
              _RestaurantCard(
                restaurant: restaurant,
                onTap: () => _openRestaurant(restaurant),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  void _openRestaurant(Restaurant restaurant) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RestaurantScreen(
          restaurant: restaurant,
          cartController: widget.cartController,
          deliveryAddress: widget.selectedAddress,
          onOrderPlaced: widget.onOrderPlaced,
        ),
      ),
    );
  }

  void _openCart(Restaurant restaurant) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CartScreen(
          restaurant: restaurant,
          cartController: widget.cartController,
          deliveryAddress: widget.selectedAddress,
          onOrderPlaced: widget.onOrderPlaced,
        ),
      ),
    );
  }

  Future<void> _showAddressSelector(BuildContext context) async {
    final selected = await showModalBottomSheet<FoodPulseDeliveryAddress>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _AddressSelectorSheet(selectedAddress: widget.selectedAddress),
    );

    if (selected != null) {
      widget.onAddressChanged(selected);
    }
  }
}

class _LocationHeader extends StatelessWidget {
  const _LocationHeader({
    required this.address,
    required this.cartCount,
    required this.onAddressTap,
    required this.onCartTap,
  });

  final FoodPulseDeliveryAddress address;
  final int cartCount;
  final VoidCallback onAddressTap;
  final VoidCallback onCartTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onAddressTap,
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.orange.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DELIVERING TO',
                        style: TextStyle(
                          color: AppColors.silver,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              address.label,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.orange,
                            size: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        _CartButton(count: cartCount, onTap: onCartTap),
      ],
    );
  }
}

class _CartButton extends StatelessWidget {
  const _CartButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.dusk,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.shopping_bag_outlined,
              size: 20,
              color: AppColors.white,
            ),
          ),
          Positioned(
            right: -4,
            top: -5,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: AppColors.orange,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$count',
                key: const Key('home_cart_badge_count'),
                style: const TextStyle(
                  color: AppColors.prussian,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressSelectorSheet extends StatelessWidget {
  const _AddressSelectorSheet({required this.selectedAddress});

  final FoodPulseDeliveryAddress selectedAddress;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      maxChildSize: 0.9,
      minChildSize: 0.45,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.silver.withAlpha(110),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Select delivery address',
                style: TextStyle(
                  color: AppColors.prussian,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              _AddressActionTile(
                icon: Icons.near_me_rounded,
                title: 'Use current location',
                subtitle: 'Detect your location in Tacloban',
                onTap: () => Navigator.pop(
                  context,
                  const FoodPulseDeliveryAddress(
                    tag: 'Current',
                    label: 'Current location',
                    notes: 'Tacloban City, Leyte',
                  ),
                ),
              ),
              const Divider(height: 24),
              const Text(
                'Saved addresses',
                style: TextStyle(
                  color: AppColors.silver,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              for (final address in MockFoodPulseData.savedAddresses)
                _SavedAddressTile(
                  address: address,
                  selected: address.label == selectedAddress.label,
                  onTap: () => Navigator.pop(context, address),
                ),
              const Divider(height: 24),
              _AddressActionTile(
                icon: Icons.add_rounded,
                title: 'Add new address',
                subtitle: 'Save another delivery point',
                onTap: () => Navigator.pop(
                  context,
                  const FoodPulseDeliveryAddress(
                    tag: 'New',
                    label: 'New Tacloban address',
                    notes: 'Add street, landmark, and notes',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SavedAddressTile extends StatelessWidget {
  const _SavedAddressTile({
    required this.address,
    required this.selected,
    required this.onTap,
  });

  final FoodPulseDeliveryAddress address;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected ? AppColors.orange : AppColors.silver,
      ),
      title: Text(
        address.label,
        style: const TextStyle(
          color: AppColors.prussian,
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: Text(address.notes ?? address.tag),
      trailing: IconButton(
        icon: const Icon(Icons.edit_outlined, color: AppColors.prussian),
        onPressed: onTap,
      ),
      onTap: onTap,
    );
  }
}

class _AddressActionTile extends StatelessWidget {
  const _AddressActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.prussian),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.prussian,
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.white.withAlpha(18)),
      ),
      child: const Row(
        children: [
          Icon(Icons.search_rounded, size: 18, color: AppColors.silver),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Restaurants, dishes, cuisines...',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.silver, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.ink,
      borderColor: AppColors.orange.withAlpha(42),
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.ink,
              AppColors.dusk,
              AppColors.prussian,
            ],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FOODPULSE DEAL',
                    style: TextStyle(
                      color: AppColors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Know before you order. Predict. Decide. Deliver.',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Text(
                      'ORDER NOW',
                      style: TextStyle(
                        color: AppColors.prussian,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.orange.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.orange.withAlpha(70)),
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: AppColors.orange,
                size: 44,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const actions = [
      (Icons.percent_rounded, 'Offers'),
      (Icons.delivery_dining_rounded, 'Fastest'),
      (Icons.star_rounded, 'Top rated'),
      (Icons.restaurant_rounded, 'Meal for one'),
    ];

    return Row(
      children: [
        for (final action in actions)
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.white.withAlpha(16)),
                  ),
                  child: Icon(action.$1, color: AppColors.orange, size: 22),
                ),
                const SizedBox(height: 6),
                Text(
                  action.$2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CategoryRail extends StatelessWidget {
  const _CategoryRail({
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final category in categories) ...[
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => onChanged(category),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: category == selected
                      ? AppColors.orange
                      : AppColors.ink,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: category == selected
                        ? AppColors.orange
                        : AppColors.white.withAlpha(16),
                  ),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: category == selected
                        ? AppColors.prussian
                        : AppColors.silver,
                    fontSize: 12,
                    fontWeight: category == selected
                        ? FontWeight.w900
                        : FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 7),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const Text(
          'See all',
          style: TextStyle(
            color: AppColors.orange,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.white,
        fontSize: 13,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({required this.restaurant, required this.onTap});

  final Restaurant restaurant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final risk = RiskInfo.fromScore(restaurant.riskScore);

    return AppCard(
      padding: EdgeInsets.zero,
      color: AppColors.ink,
      borderColor: AppColors.white.withAlpha(16),
      onTap: onTap,
      child: Column(
        children: [
          SizedBox(
            height: 96,
            child: Stack(
              children: [
                Positioned.fill(
                  child: FoodPulseAssetImage(
                    imageAsset: restaurant.imageAsset,
                    fallbackLabel: restaurant.emoji,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                    backgroundColor: AppColors.dusk,
                    fallbackTextStyle: const TextStyle(
                      color: AppColors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.prussian.withAlpha(10),
                          AppColors.prussian.withAlpha(180),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _RatingPill(rating: restaurant.rating),
                ),
                Positioned(
                  bottom: 8,
                  left: 10,
                  child: RiskChip(
                    risk: risk,
                    text: '${restaurant.riskScore}% risk',
                    dense: true,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant.name,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        restaurant.cuisine,
                        style: const TextStyle(
                          color: AppColors.silver,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      restaurant.deliveryTime,
                      style: const TextStyle(
                        color: AppColors.silver,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${restaurant.distance} - P${restaurant.deliveryFee}',
                      style: const TextStyle(
                        color: AppColors.silver,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingPill extends StatelessWidget {
  const _RatingPill({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.prussian.withAlpha(210),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.orange, size: 12),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: AppColors.orange,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreTab extends StatelessWidget {
  const _ExploreTab({
    required this.cartController,
    required this.selectedAddress,
    required this.onOrderPlaced,
  });

  final FoodPulseCartController cartController;
  final FoodPulseDeliveryAddress selectedAddress;
  final ValueChanged<OrderConfirmation> onOrderPlaced;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Explore',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: cartController,
                builder: (context, _) => _CartButton(
                  count: cartController.totalQuantity,
                  onTap: () => _openCart(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _SearchBar(),
          const SizedBox(height: 14),
          for (final restaurant in MockFoodPulseData.restaurants) ...[
            _RestaurantCard(
              restaurant: restaurant,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RestaurantScreen(
                    restaurant: restaurant,
                    cartController: cartController,
                    deliveryAddress: selectedAddress,
                    onOrderPlaced: onOrderPlaced,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  void _openCart(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CartScreen(
          restaurant: cartController.restaurant,
          cartController: cartController,
          deliveryAddress: selectedAddress,
          onOrderPlaced: onOrderPlaced,
        ),
      ),
    );
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab({required this.orders});

  final List<OrderConfirmation> orders;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        children: [
          const Text(
            'Orders',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (orders.isEmpty)
            const AppCard(
              child: Text(
                'No orders yet. Your placed orders will appear here.',
                style: TextStyle(color: AppColors.silver, fontSize: 12),
              ),
            )
          else
            for (final order in orders) ...[
              _OrderCard(order: order),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final OrderConfirmation order;

  @override
  Widget build(BuildContext context) {
    final items = order.items
        .map((item) => '${item.quantity}x ${item.name}')
        .join(', ');

    return AppCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => OrderTrackingScreen(order: order),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.restaurant.name,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                'P${order.total}',
                style: const TextStyle(
                  color: AppColors.orange,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            items,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.silver, fontSize: 11),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatusPill(status: _humanStatus(order.status)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ETA ${order.estimatedArrival} - Rider ${order.rider.name}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.silver,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  _dateLabel(order.orderedAt ?? DateTime.now()),
                  style: const TextStyle(
                    color: AppColors.silver,
                    fontSize: 10,
                  ),
                ),
              ),
              const Icon(
                Icons.near_me_rounded,
                color: AppColors.orange,
                size: 14,
              ),
              const SizedBox(width: 4),
              const Text(
                'Track rider',
                style: TextStyle(
                  color: AppColors.orange,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _humanStatus(String status) {
    return status.replaceAll('_', ' ').trim().isEmpty
        ? 'Order placed'
        : status.replaceAll('_', ' ');
  }

  String _dateLabel(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.month}/${date.day}/${date.year} $hour:$minute $suffix';
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.orange.withAlpha(26),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: AppColors.orange,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ProfileTab extends StatefulWidget {
  const _ProfileTab({required this.selectedAddress});

  final FoodPulseDeliveryAddress selectedAddress;

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
        children: [
          const Text(
            'Profile',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: AppColors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.prussian,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    DemoAccount.username,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _SectionTitle('Account'),
          const SizedBox(height: 8),
          _ProfileActionTile(
            icon: Icons.mail_outline_rounded,
            title: 'Edit Email',
            subtitle: DemoAccount.email.isEmpty
                ? 'Add your email address'
                : DemoAccount.email,
            onTap: _showEditEmailDialog,
          ),
          const SizedBox(height: 8),
          _ProfileActionTile(
            icon: Icons.phone_outlined,
            title: 'Edit Contact Number',
            subtitle: DemoAccount.contactNumber.isEmpty
                ? 'Add your mobile number'
                : DemoAccount.contactNumber,
            onTap: _showEditContactDialog,
          ),
          const SizedBox(height: 8),
          _ProfileActionTile(
            icon: Icons.lock_reset_rounded,
            title: 'Change Password',
            subtitle: 'Use a stronger account password',
            onTap: _showChangePasswordDialog,
          ),
          const SizedBox(height: 14),
          const _SectionTitle('Support'),
          const SizedBox(height: 8),
          _ProfileActionTile(
            icon: Icons.help_outline_rounded,
            title: 'Help Center',
            subtitle: 'FAQs, delivery support, and contact options',
            onTap: () => _showInfoSheet(
              title: 'Help Center',
              lines: const [
                'Order support: track rider status from the Orders tab.',
                'Checkout help: risk score updates before placing an order.',
                'Payments: GCash, card, and cash on delivery are supported.',
                'For urgent orders, contact the rider from the tracking screen.',
              ],
            ),
          ),
          const SizedBox(height: 8),
          _ProfileActionTile(
            icon: Icons.policy_outlined,
            title: 'Terms & Policies',
            subtitle: 'Privacy, refunds, and delivery guidelines',
            onTap: () => _showInfoSheet(
              title: 'Terms & Policies',
              lines: const [
                'Risk predictions are decision-support estimates, not guarantees.',
                'Refunds follow merchant review and payment provider timelines.',
                'Delivery details are used to calculate ETA and fulfillment risk.',
                'Keep account credentials private and update your password regularly.',
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _SectionTitle('Session'),
          const SizedBox(height: 8),
          _ProfileActionTile(
            icon: Icons.logout_rounded,
            title: 'Logout',
            subtitle: 'Sign out of this device',
            destructive: true,
            onTap: _confirmLogout,
          ),
        ],
      ),
    );
  }

  Future<void> _showEditEmailDialog() async {
    final email = await showDialog<String>(
      context: context,
      builder: (_) => _EditEmailDialog(initialEmail: DemoAccount.email),
    );

    if (email == null || !mounted) {
      return;
    }

    try {
      final user = await AuthApiService().updateProfile(
        username: DemoAccount.username,
        password: DemoAccount.password,
        email: email,
        contactNumber: DemoAccount.contactNumber,
      );

      setState(() => DemoAccount.email = user.email);
      await DemoAccount.save();
    } on ApiException catch (error) {
      if (mounted) {
        _showProfileError(error.message);
      }
    }
  }

  Future<void> _showEditContactDialog() async {
    final contactNumber = await showDialog<String>(
      context: context,
      builder: (_) =>
          _EditContactDialog(initialContactNumber: DemoAccount.contactNumber),
    );

    if (contactNumber == null || !mounted) {
      return;
    }

    try {
      final user = await AuthApiService().updateProfile(
        username: DemoAccount.username,
        password: DemoAccount.password,
        email: DemoAccount.email,
        contactNumber: contactNumber,
      );

      setState(() => DemoAccount.contactNumber = user.contactNumber);
      await DemoAccount.save();
    } on ApiException catch (error) {
      if (mounted) {
        _showProfileError(error.message);
      }
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final newPassword = await showDialog<String>(
      context: context,
      builder: (_) => _ChangePasswordDialog(currentPassword: DemoAccount.password),
    );

    if (newPassword != null && mounted) {
      try {
        await AuthApiService().updatePassword(
          username: DemoAccount.username,
          currentPassword: DemoAccount.password,
          password: newPassword,
        );

        DemoAccount.password = newPassword;
        await DemoAccount.save();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password updated.')),
          );
        }
      } on ApiException catch (error) {
        if (mounted) {
          _showProfileError(error.message);
        }
      }
    }
  }

  void _showProfileError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showInfoSheet({
    required String title,
    required List<String> lines,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.prussian,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.silver.withAlpha(95),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              for (final line in lines) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppColors.orange,
                      size: 17,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        line,
                        style: const TextStyle(
                          color: AppColors.alabaster,
                          fontSize: 12,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.prussian,
          title: const Text(
            'Logout?',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'You will return to the login screen.',
            style: TextStyle(color: AppColors.silver),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Logout',
                style: TextStyle(color: AppColors.tangerine),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.tangerine : AppColors.orange;

    return AppCard(
      onTap: onTap,
      color: destructive ? AppColors.orange : null,
      borderColor: destructive ? AppColors.orange : null,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: destructive ? AppColors.prussian.withAlpha(24) : color.withAlpha(24),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: destructive
                    ? AppColors.prussian.withAlpha(48)
                    : color.withAlpha(48),
              ),
            ),
            child: Icon(
              icon,
              color: destructive ? AppColors.prussian : color,
              size: 19,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: destructive ? AppColors.prussian : AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: destructive
                        ? AppColors.prussian.withAlpha(190)
                        : AppColors.silver,
                    fontSize: 11,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: destructive ? AppColors.prussian : AppColors.silver,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _EditEmailDialog extends StatefulWidget {
  const _EditEmailDialog({required this.initialEmail});

  final String initialEmail;

  @override
  State<_EditEmailDialog> createState() => _EditEmailDialogState();
}

class _EditEmailDialogState extends State<_EditEmailDialog> {
  late final TextEditingController _controller;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _errorMessage = 'Email address is required.');
      return;
    }

    if (!value.contains('@') || !value.contains('.')) {
      setState(() => _errorMessage = 'Enter a valid email address.');
      return;
    }

    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return _ProfileInputDialog(
      title: 'Edit Email',
      primaryLabel: 'Save',
      errorMessage: _errorMessage,
      fields: [
        TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: AppColors.white),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9@._-]')),
          ],
          decoration: const InputDecoration(
            labelText: 'Email address',
            prefixIcon: Icon(Icons.mail_outline_rounded),
          ),
          onSubmitted: (_) => _submit(),
        ),
      ],
      onSubmit: _submit,
    );
  }
}

class _EditContactDialog extends StatefulWidget {
  const _EditContactDialog({required this.initialContactNumber});

  final String initialContactNumber;

  @override
  State<_EditContactDialog> createState() => _EditContactDialogState();
}

class _EditContactDialogState extends State<_EditContactDialog> {
  late final TextEditingController _controller;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContactNumber);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _errorMessage = 'Contact number is required.');
      return;
    }

    if (!DemoAccount.contactNumberPattern.hasMatch(value)) {
      setState(() => _errorMessage = 'Contact number must contain digits only.');
      return;
    }

    if (value.length < 10) {
      setState(() => _errorMessage = 'Enter a valid contact number.');
      return;
    }

    if (value.length > DemoAccount.maxContactNumberLength) {
      setState(() => _errorMessage = 'Contact number cannot exceed 11 digits.');
      return;
    }

    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return _ProfileInputDialog(
      title: 'Edit Contact Number',
      primaryLabel: 'Save',
      errorMessage: _errorMessage,
      fields: [
        TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: AppColors.white),
          maxLength: DemoAccount.maxContactNumberLength,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Contact number',
            counterText: '',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          onSubmitted: (_) => _submit(),
        ),
      ],
      onSubmit: _submit,
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog({required this.currentPassword});

  final String currentPassword;

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    final currentPassword = _currentController.text;
    final newPassword = _newController.text;
    final confirmPassword = _confirmController.text;

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      setState(() => _errorMessage = 'Complete all password fields.');
      return;
    }

    if (currentPassword != widget.currentPassword) {
      setState(() => _errorMessage = 'Current password is incorrect.');
      return;
    }

    if (newPassword.length < 6) {
      setState(
        () => _errorMessage = 'New password must be at least 6 characters.',
      );
      return;
    }

    if (newPassword.length > DemoAccount.maxPasswordLength) {
      setState(() => _errorMessage = 'New password cannot exceed 15 characters.');
      return;
    }

    if (!DemoAccount.passwordPattern.hasMatch(newPassword) ||
        !DemoAccount.passwordPattern.hasMatch(confirmPassword)) {
      setState(() => _errorMessage = 'Password contains unsupported characters.');
      return;
    }

    if (newPassword != confirmPassword) {
      setState(
        () => _errorMessage = 'New password and confirmation do not match.',
      );
      return;
    }

    Navigator.of(context).pop(newPassword);
  }

  @override
  Widget build(BuildContext context) {
    return _ProfileInputDialog(
      title: 'Change Password',
      primaryLabel: 'Update',
      errorMessage: _errorMessage,
      fields: [
        TextField(
          controller: _currentController,
          obscureText: true,
          style: const TextStyle(color: AppColors.white),
          maxLength: DemoAccount.maxPasswordLength,
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(r'[A-Za-z0-9!@#$%^&*._-]'),
            ),
          ],
          decoration: const InputDecoration(
            labelText: 'Current password',
            counterText: '',
            prefixIcon: Icon(Icons.lock_outline_rounded),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _newController,
          obscureText: true,
          style: const TextStyle(color: AppColors.white),
          maxLength: DemoAccount.maxPasswordLength,
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(r'[A-Za-z0-9!@#$%^&*._-]'),
            ),
          ],
          decoration: const InputDecoration(
            labelText: 'New password',
            counterText: '',
            prefixIcon: Icon(Icons.lock_reset_rounded),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _confirmController,
          obscureText: true,
          style: const TextStyle(color: AppColors.white),
          maxLength: DemoAccount.maxPasswordLength,
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(r'[A-Za-z0-9!@#$%^&*._-]'),
            ),
          ],
          decoration: const InputDecoration(
            labelText: 'Confirm new password',
            counterText: '',
            prefixIcon: Icon(Icons.verified_user_outlined),
          ),
          onSubmitted: (_) => _submit(),
        ),
      ],
      onSubmit: _submit,
    );
  }
}

class _ProfileInputDialog extends StatelessWidget {
  const _ProfileInputDialog({
    required this.title,
    required this.primaryLabel,
    required this.fields,
    required this.onSubmit,
    this.errorMessage,
  });

  final String title;
  final String primaryLabel;
  final List<Widget> fields;
  final VoidCallback onSubmit;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.prussian,
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...fields,
            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.tangerine.withAlpha(24),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.tangerine.withAlpha(80)),
                ),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: AppColors.tangerine,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: onSubmit,
          child: Text(
            primaryLabel,
            style: const TextStyle(
              color: AppColors.orange,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _DataStatusBanner extends StatelessWidget {
  const _DataStatusBanner({required this.isLoading, required this.message});

  final bool isLoading;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      color: AppColors.white.withAlpha(12),
      borderColor: isLoading
          ? AppColors.orange.withAlpha(48)
          : AppColors.white.withAlpha(26),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.orange,
              ),
            )
          else
            const Icon(
              Icons.info_outline_rounded,
              color: AppColors.orange,
              size: 17,
            ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              isLoading
                  ? 'Loading restaurants from Laravel...'
                  : message ?? 'Using saved local restaurant data.',
              style: const TextStyle(
                color: AppColors.silver,
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRestaurantsState extends StatelessWidget {
  const _EmptyRestaurantsState();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Text(
        'No restaurants available right now.',
        style: TextStyle(color: AppColors.silver, fontSize: 12),
      ),
    );
  }
}
