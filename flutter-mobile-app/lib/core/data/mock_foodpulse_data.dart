import '../models/cart_item.dart';
import '../models/menu_item.dart';
import '../models/restaurant.dart';

class MockFoodPulseData {
  const MockFoodPulseData._();

  static const restaurants = [
    Restaurant(
      id: 1,
      name: 'Tambayan Grill',
      cuisine: 'Filipino - Grills',
      rating: 4.8,
      deliveryTime: '15-25 min',
      minimumOrder: 99,
      emoji: 'TG',
      riskScore: 28,
    ),
    Restaurant(
      id: 2,
      name: 'Jollibee Express',
      cuisine: 'Fast Food',
      rating: 4.9,
      deliveryTime: '10-20 min',
      minimumOrder: 79,
      emoji: 'JB',
      riskScore: 62,
    ),
    Restaurant(
      id: 3,
      name: 'Chao Fan House',
      cuisine: 'Chinese - Meals',
      rating: 4.6,
      deliveryTime: '20-35 min',
      minimumOrder: 89,
      emoji: 'CF',
      riskScore: 81,
    ),
  ];

  static const porkSinigang = MenuItem(
    id: 1,
    restaurantId: 1,
    name: 'Pork Sinigang',
    description: 'Sour tamarind broth with tender pork ribs',
    price: 185,
    emoji: 'PS',
    category: 'Bestsellers',
  );
  static const chickenInasal = MenuItem(
    id: 2,
    restaurantId: 1,
    name: 'Chicken Inasal',
    description: 'Charcoal-grilled chicken with garlic rice',
    price: 155,
    emoji: 'CI',
    category: 'Bestsellers',
  );
  static const lechonKawali = MenuItem(
    id: 3,
    restaurantId: 1,
    name: 'Lechon Kawali',
    description: 'Crispy pork belly with liver sauce',
    price: 210,
    emoji: 'LK',
    category: 'Mains',
  );
  static const pancitCanton = MenuItem(
    id: 4,
    restaurantId: 1,
    name: 'Pancit Canton',
    description: 'Stir-fried noodles with vegetables and pork',
    price: 145,
    emoji: 'PC',
    category: 'Mains',
  );
  static const haloHalo = MenuItem(
    id: 5,
    restaurantId: 1,
    name: 'Halo-Halo',
    description: 'Shaved ice with mixed fruits and leche flan',
    price: 95,
    emoji: 'HH',
    category: 'Desserts',
  );

  static const chickenjoyMeal = MenuItem(
    id: 6,
    restaurantId: 2,
    name: 'Chickenjoy Meal',
    description: 'Crispy fried chicken with rice and gravy',
    price: 149,
    emoji: 'CJ',
    category: 'Bestsellers',
  );
  static const jollySpaghetti = MenuItem(
    id: 7,
    restaurantId: 2,
    name: 'Jolly Spaghetti',
    description: 'Sweet-style spaghetti with hotdog slices',
    price: 85,
    emoji: 'JS',
    category: 'Bestsellers',
  );
  static const yumburger = MenuItem(
    id: 8,
    restaurantId: 2,
    name: 'Yumburger',
    description: 'Classic burger with signature dressing',
    price: 55,
    emoji: 'YB',
    category: 'Sandwiches',
  );
  static const burgerSteak = MenuItem(
    id: 9,
    restaurantId: 2,
    name: 'Burger Steak',
    description: 'Burger patties with mushroom gravy and rice',
    price: 99,
    emoji: 'BS',
    category: 'Rice Meals',
  );
  static const peachMangoPie = MenuItem(
    id: 10,
    restaurantId: 2,
    name: 'Peach Mango Pie',
    description: 'Crispy pocket pie with peach mango filling',
    price: 49,
    emoji: 'PM',
    category: 'Desserts',
  );

  static const porkChaoFan = MenuItem(
    id: 11,
    restaurantId: 3,
    name: 'Pork Chao Fan',
    description: 'Wok-fried rice with pork and vegetables',
    price: 135,
    emoji: 'PF',
    category: 'Bestsellers',
  );
  static const beefChaoFan = MenuItem(
    id: 12,
    restaurantId: 3,
    name: 'Beef Chao Fan',
    description: 'Wok-fried rice with savory beef strips',
    price: 155,
    emoji: 'BF',
    category: 'Bestsellers',
  );
  static const siomai = MenuItem(
    id: 13,
    restaurantId: 3,
    name: 'Siomai',
    description: 'Steamed pork dumplings with chili garlic',
    price: 90,
    emoji: 'SM',
    category: 'Dimsum',
  );
  static const wontonNoodles = MenuItem(
    id: 14,
    restaurantId: 3,
    name: 'Wonton Noodles',
    description: 'Noodle soup with wontons and spring onions',
    price: 120,
    emoji: 'WN',
    category: 'Noodles',
  );
  static const buchi = MenuItem(
    id: 15,
    restaurantId: 3,
    name: 'Buchi',
    description: 'Sesame rice balls with sweet filling',
    price: 65,
    emoji: 'BC',
    category: 'Desserts',
  );

  static const menuItems = [
    porkSinigang,
    chickenInasal,
    lechonKawali,
    pancitCanton,
    haloHalo,
    chickenjoyMeal,
    jollySpaghetti,
    yumburger,
    burgerSteak,
    peachMangoPie,
    porkChaoFan,
    beefChaoFan,
    siomai,
    wontonNoodles,
    buchi,
  ];

  static const defaultCart = [
    CartItem(item: porkSinigang, quantity: 1),
    CartItem(item: chickenInasal, quantity: 2),
  ];

  static const deliveryFee = 49;
  static const serviceCharge = 10;
  static const checkoutRiskScore = 68;
  static const orderNumber = 'FP-2024-9873';

  static List<MenuItem> menuItemsFor(int restaurantId) {
    return menuItems
        .where((item) => item.restaurantId == restaurantId)
        .toList(growable: false);
  }

  static int subtotalFor(List<CartItem> items) {
    return items.fold(0, (sum, item) => sum + item.lineTotal);
  }

  static int totalFor(List<CartItem> items) {
    return subtotalFor(items) + deliveryFee + serviceCharge;
  }
}
