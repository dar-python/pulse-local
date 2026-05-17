import 'package:flutter/material.dart';

import '../../core/data/mock_foodpulse_data.dart';
import '../../core/models/restaurant.dart';
import '../../core/models/risk_info.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/bottom_nav.dart';
import '../../shared/widgets/foodpulse_logo.dart';
import '../../shared/widgets/risk_chip.dart';
import '../cart/cart_screen.dart';
import '../restaurant/restaurant_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.prussian,
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _navIndex,
              children: const [
                _HomeContent(),
                _PlaceholderTab(title: 'Explore', icon: Icons.explore_rounded),
                _PlaceholderTab(
                  title: 'Orders',
                  icon: Icons.receipt_long_rounded,
                ),
                _PlaceholderTab(title: 'Profile', icon: Icons.person_rounded),
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

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  static const _categories = [
    'All',
    'Near Me',
    'Fast Food',
    'Meals',
    'Desserts',
  ];
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final cartCount = MockFoodPulseData.defaultCart.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DELIVERING TO',
                        style: TextStyle(
                          color: AppColors.silver,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Tacloban City, E. Visayas',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.orange,
                            size: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _CartButton(count: cartCount),
              ],
            ),
            const SizedBox(height: 14),
            const _SearchBar(),
            const SizedBox(height: 10),
            _HeroBanner(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const RestaurantScreen(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final category in _categories) ...[
                    _CategoryChip(
                      label: category,
                      selected: category == _selectedCategory,
                      onTap: () {
                        setState(() => _selectedCategory = category);
                      },
                    ),
                    const SizedBox(width: 7),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: const [
                Expanded(
                  child: Text(
                    'Restaurants Near You',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  'See all',
                  style: TextStyle(
                    color: AppColors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final restaurant in MockFoodPulseData.restaurants) ...[
              _RestaurantCard(restaurant: restaurant),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  const _CartButton({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const CartScreen())),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.dusk,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 18,
              color: AppColors.white,
            ),
          ),
          Positioned(
            right: -4,
            top: -5,
            child: Container(
              width: 17,
              height: 17,
              decoration: const BoxDecoration(
                color: AppColors.orange,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$count',
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

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white.withAlpha(18),
        borderRadius: BorderRadius.circular(8),
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

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.dusk,
      borderColor: AppColors.dusk,
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -18,
            child: Container(
              width: 98,
              height: 98,
              decoration: BoxDecoration(
                color: AppColors.orange.withAlpha(36),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Positioned(
            right: 4,
            bottom: -7,
            child: Text(
              '⚡',
              style: TextStyle(fontSize: 46, color: AppColors.silver),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'RISK-AWARE QUICK COMMERCE',
                style: TextStyle(
                  color: AppColors.orange,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Know before you order.\nPredict. Decide. Deliver.',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 17,
                  height: 1.32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 13),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ORDER NOW',
                      style: TextStyle(
                        color: AppColors.prussian,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(width: 5),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: AppColors.prussian,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.orange : AppColors.white.withAlpha(18),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.prussian : AppColors.silver,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final risk = RiskInfo.fromScore(restaurant.riskScore);

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const RestaurantScreen())),
      child: Column(
        children: [
          Container(
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.dusk.withAlpha(205),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    restaurant.emoji,
                    style: const TextStyle(fontSize: 42),
                  ),
                ),
                Positioned(
                  top: 7,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.prussian.withAlpha(205),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      '★ ${restaurant.rating.toStringAsFixed(1)}',
                      style: const TextStyle(
                        color: AppColors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 9,
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
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
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
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
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
                      'Min ₱${restaurant.minimumOrder}',
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

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FoodPulseLogo(compact: true),
              const SizedBox(height: 28),
              Icon(icon, color: AppColors.orange, size: 42),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Coming soon',
                style: TextStyle(color: AppColors.silver, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
