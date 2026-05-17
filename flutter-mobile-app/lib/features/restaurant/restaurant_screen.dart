import 'package:flutter/material.dart';

import '../../core/data/mock_foodpulse_data.dart';
import '../../core/models/menu_item.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/primary_button.dart';
import '../cart/cart_screen.dart';

class RestaurantScreen extends StatefulWidget {
  const RestaurantScreen({super.key});

  @override
  State<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> {
  static const _tabs = ['Bestsellers', 'Specials', 'Desserts'];
  late final Map<int, int> _cart;
  String _selectedTab = 'Bestsellers';

  @override
  void initState() {
    super.initState();
    _cart = {
      for (final item in MockFoodPulseData.defaultCart)
        item.item.id: item.quantity,
    };
  }

  int get _cartCount => _cart.values.fold(0, (sum, quantity) => sum + quantity);

  int get _cartTotal {
    return _cart.entries.fold(0, (sum, entry) {
      final item = MockFoodPulseData.menuItems.firstWhere(
        (menuItem) => menuItem.id == entry.key,
      );
      return sum + item.price * entry.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = MockFoodPulseData.menuItems
        .where((item) => item.category == _selectedTab)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.prussian,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _RestaurantHero(onBack: () => Navigator.of(context).pop()),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tambayan Grill',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Filipino · Grills · Local Favorites',
                              style: TextStyle(
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
                        children: const [
                          Text(
                            '★ 4.8',
                            style: TextStyle(
                              color: AppColors.orange,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            '15–25 min',
                            style: TextStyle(
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
                      color: AppColors.green.withAlpha(38),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.green.withAlpha(72)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 15,
                          color: AppColors.green,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Low fulfillment risk (28%) · ETA on track',
                            style: TextStyle(
                              color: AppColors.green,
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
              tabs: _tabs,
              selected: _selectedTab,
              onChanged: (tab) => setState(() => _selectedTab = tab),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  18,
                  8,
                  18,
                  _cartCount > 0 ? 92 : 20,
                ),
                itemBuilder: (context, index) => _MenuItemRow(
                  item: visibleItems[index],
                  onAdd: () {
                    setState(() {
                      _cart[visibleItems[index].id] =
                          (_cart[visibleItems[index].id] ?? 0) + 1;
                    });
                  },
                ),
                separatorBuilder: (_, _) =>
                    Divider(color: AppColors.white.withAlpha(14), height: 1),
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
                    MaterialPageRoute<void>(builder: (_) => const CartScreen()),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _RestaurantHero extends StatelessWidget {
  const _RestaurantHero({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 124,
      color: AppColors.dusk,
      child: Stack(
        children: [
          const Center(child: Text('🍖', style: TextStyle(fontSize: 54))),
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
    );
  }
}

class _MenuItemRow extends StatelessWidget {
  const _MenuItemRow({required this.item, required this.onAdd});

  final MenuItem item;
  final VoidCallback onAdd;

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
                  color: AppColors.dusk.withAlpha(112),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(item.emoji, style: const TextStyle(fontSize: 29)),
              ),
              Positioned(
                right: -8,
                bottom: -8,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onAdd,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: AppColors.prussian,
                      size: 20,
                    ),
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
