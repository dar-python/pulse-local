import '../models/cart_item.dart';
import '../models/menu_item.dart';
import '../models/restaurant.dart';

class MockFoodPulseData {
  const MockFoodPulseData._();

  static const restaurants = [
    Restaurant(
      id: 1,
      name: 'Tambayan Grill',
      cuisine: 'Filipino · Grills',
      rating: 4.8,
      deliveryTime: '15–25 min',
      minimumOrder: 99,
      emoji: '🍖',
      riskScore: 28,
    ),
    Restaurant(
      id: 2,
      name: 'Jollibee Express',
      cuisine: 'Fast Food',
      rating: 4.9,
      deliveryTime: '10–20 min',
      minimumOrder: 79,
      emoji: '🍗',
      riskScore: 62,
    ),
    Restaurant(
      id: 3,
      name: 'Chao Fan House',
      cuisine: 'Chinese · Meals',
      rating: 4.6,
      deliveryTime: '20–35 min',
      minimumOrder: 89,
      emoji: '🍜',
      riskScore: 81,
    ),
  ];

  static const porkSinigang = MenuItem(
    id: 1,
    name: 'Pork Sinigang',
    description: 'Sour tamarind broth with tender pork ribs',
    price: 185,
    emoji: '🍲',
    category: 'Bestsellers',
  );
  static const chickenInasal = MenuItem(
    id: 2,
    name: 'Chicken Inasal',
    description: 'Charcoal-grilled chicken with garlic rice',
    price: 155,
    emoji: '🍗',
    category: 'Bestsellers',
  );
  static const kareKare = MenuItem(
    id: 3,
    name: 'Kare-Kare',
    description: 'Rich peanut stew with oxtail & veggies',
    price: 220,
    emoji: '🥘',
    category: 'Specials',
  );
  static const haloHalo = MenuItem(
    id: 4,
    name: 'Halo-Halo',
    description: 'Shaved ice with mixed fruits & leche flan',
    price: 95,
    emoji: '🍧',
    category: 'Desserts',
  );

  static const menuItems = [porkSinigang, chickenInasal, kareKare, haloHalo];

  static const defaultCart = [
    CartItem(item: porkSinigang, quantity: 1),
    CartItem(item: chickenInasal, quantity: 2),
  ];

  static const deliveryFee = 49;
  static const serviceCharge = 10;
  static const checkoutRiskScore = 68;
  static const orderNumber = 'FP-2024-9873';

  static int subtotalFor(List<CartItem> items) {
    return items.fold(0, (sum, item) => sum + item.lineTotal);
  }

  static int totalFor(List<CartItem> items) {
    return subtotalFor(items) + deliveryFee + serviceCharge;
  }
}
