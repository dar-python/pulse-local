import '../constants/foodpulse_image_assets.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';
import '../models/restaurant.dart';
import '../../features/foodpulse/models/foodpulse_order.dart';

class MockFoodPulseData {
  const MockFoodPulseData._();

  static const savedAddresses = [
    FoodPulseDeliveryAddress(
      tag: 'Home',
      label: 'Tacloban City, E. Visayas',
      notes: 'Lnu gate Independencia St, Leyte',
    ),
    FoodPulseDeliveryAddress(
      tag: 'Work',
      label: '929 San Isidro St',
      notes: 'Tacloban City, Leyte',
    ),
    FoodPulseDeliveryAddress(
      tag: 'Favorite',
      label: 'Soya Wheat Bakeshop Alvarado St.',
      notes: 'Downtown Tacloban, Leyte',
    ),
  ];

  static const restaurants = [
    Restaurant(
      id: 1,
      name: 'McDonald\'s Tacloban',
      cuisine: 'Burgers - Fast Food',
      rating: 4.8,
      deliveryTime: '15-25 min',
      minimumOrder: 99,
      distance: '1.1 km',
      deliveryFee: 39,
      emoji: 'M',
      riskScore: 28,
      imageAsset: FoodPulseImageAssets.tambayanGrill,
      branchAddress: 'Real St, Downtown Tacloban',
    ),
    Restaurant(
      id: 2,
      name: 'Jollibee Tacloban',
      cuisine: 'Fast Food',
      rating: 4.9,
      deliveryTime: '10-20 min',
      minimumOrder: 79,
      distance: '0.8 km',
      deliveryFee: 29,
      emoji: 'JB',
      riskScore: 62,
      imageAsset: FoodPulseImageAssets.jollibeeExpress,
      branchAddress: 'Justice Romualdez St, Tacloban City',
    ),
    Restaurant(
      id: 3,
      name: 'KFC Tacloban',
      cuisine: 'Chicken - Fast Food',
      rating: 4.6,
      deliveryTime: '20-30 min',
      minimumOrder: 99,
      distance: '1.6 km',
      deliveryFee: 49,
      emoji: 'KFC',
      riskScore: 54,
      imageAsset: FoodPulseImageAssets.chaoFanHouse,
      branchAddress: 'Robinsons North Tacloban',
    ),
    Restaurant(
      id: 4,
      name: 'Chowking Tacloban',
      cuisine: 'Chinese - Rice Meals',
      rating: 4.6,
      deliveryTime: '20-35 min',
      minimumOrder: 89,
      distance: '1.4 km',
      deliveryFee: 45,
      emoji: 'CK',
      riskScore: 81,
      imageAsset: FoodPulseImageAssets.chaoFanHouse,
      branchAddress: 'Zamora St, Tacloban City',
    ),
    Restaurant(
      id: 5,
      name: 'Shakey\'s Tacloban',
      cuisine: 'Pizza - Chicken',
      rating: 4.7,
      deliveryTime: '25-40 min',
      minimumOrder: 199,
      distance: '2.2 km',
      deliveryFee: 59,
      emoji: 'SK',
      riskScore: 44,
      imageAsset: FoodPulseImageAssets.tambayanGrill,
      branchAddress: 'P. Burgos St, Tacloban City',
    ),
    Restaurant(
      id: 6,
      name: 'Greenwich Tacloban',
      cuisine: 'Pizza - Pasta',
      rating: 4.5,
      deliveryTime: '20-35 min',
      minimumOrder: 149,
      distance: '1.9 km',
      deliveryFee: 49,
      emoji: 'GW',
      riskScore: 36,
      imageAsset: FoodPulseImageAssets.jollibeeExpress,
      branchAddress: 'Rizal Ave, Tacloban City',
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
    imageAsset: FoodPulseImageAssets.porkSinigang,
  );
  static const chickenInasal = MenuItem(
    id: 2,
    restaurantId: 1,
    name: 'Chicken Inasal',
    description: 'Charcoal-grilled chicken with garlic rice',
    price: 155,
    emoji: 'CI',
    category: 'Bestsellers',
    imageAsset: FoodPulseImageAssets.chickenInasal,
  );
  static const lechonKawali = MenuItem(
    id: 3,
    restaurantId: 1,
    name: 'Lechon Kawali',
    description: 'Crispy pork belly with liver sauce',
    price: 210,
    emoji: 'LK',
    category: 'Mains',
    imageAsset: FoodPulseImageAssets.lechonKawali,
  );
  static const pancitCanton = MenuItem(
    id: 4,
    restaurantId: 1,
    name: 'Pancit Canton',
    description: 'Stir-fried noodles with vegetables and pork',
    price: 145,
    emoji: 'PC',
    category: 'Mains',
    imageAsset: FoodPulseImageAssets.pancitCanton,
  );
  static const haloHalo = MenuItem(
    id: 5,
    restaurantId: 1,
    name: 'Halo-Halo',
    description: 'Shaved ice with mixed fruits and leche flan',
    price: 95,
    emoji: 'HH',
    category: 'Desserts',
    imageAsset: FoodPulseImageAssets.haloHalo,
  );

  static const chickenjoyMeal = MenuItem(
    id: 6,
    restaurantId: 2,
    name: 'Chickenjoy Meal',
    description: 'Crispy fried chicken with rice and gravy',
    price: 149,
    emoji: 'CJ',
    category: 'Bestsellers',
    imageAsset: FoodPulseImageAssets.chickenjoyMeal,
  );
  static const jollySpaghetti = MenuItem(
    id: 7,
    restaurantId: 2,
    name: 'Jolly Spaghetti',
    description: 'Sweet-style spaghetti with hotdog slices',
    price: 85,
    emoji: 'JS',
    category: 'Bestsellers',
    imageAsset: FoodPulseImageAssets.jollySpaghetti,
  );
  static const yumburger = MenuItem(
    id: 8,
    restaurantId: 2,
    name: 'Yumburger',
    description: 'Classic burger with signature dressing',
    price: 55,
    emoji: 'YB',
    category: 'Sandwiches',
    imageAsset: FoodPulseImageAssets.yumburger,
  );
  static const burgerSteak = MenuItem(
    id: 9,
    restaurantId: 2,
    name: 'Burger Steak',
    description: 'Burger patties with mushroom gravy and rice',
    price: 99,
    emoji: 'BS',
    category: 'Rice Meals',
    imageAsset: FoodPulseImageAssets.burgerSteak,
  );
  static const peachMangoPie = MenuItem(
    id: 10,
    restaurantId: 2,
    name: 'Peach Mango Pie',
    description: 'Crispy pocket pie with peach mango filling',
    price: 49,
    emoji: 'PM',
    category: 'Desserts',
    imageAsset: FoodPulseImageAssets.peachMangoPie,
  );

  static const porkChaoFan = MenuItem(
    id: 11,
    restaurantId: 3,
    name: 'Pork Chao Fan',
    description: 'Wok-fried rice with pork and vegetables',
    price: 135,
    emoji: 'PF',
    category: 'Bestsellers',
    imageAsset: FoodPulseImageAssets.porkChaoFan,
  );
  static const beefChaoFan = MenuItem(
    id: 12,
    restaurantId: 3,
    name: 'Beef Chao Fan',
    description: 'Wok-fried rice with savory beef strips',
    price: 155,
    emoji: 'BF',
    category: 'Bestsellers',
    imageAsset: FoodPulseImageAssets.beefChaoFan,
  );
  static const siomai = MenuItem(
    id: 13,
    restaurantId: 3,
    name: 'Siomai',
    description: 'Steamed pork dumplings with chili garlic',
    price: 90,
    emoji: 'SM',
    category: 'Dimsum',
    imageAsset: FoodPulseImageAssets.siomai,
  );
  static const wontonNoodles = MenuItem(
    id: 14,
    restaurantId: 3,
    name: 'Wonton Noodles',
    description: 'Noodle soup with wontons and spring onions',
    price: 120,
    emoji: 'WN',
    category: 'Noodles',
    imageAsset: FoodPulseImageAssets.wontonNoodles,
  );
  static const buchi = MenuItem(
    id: 15,
    restaurantId: 3,
    name: 'Buchi',
    description: 'Sesame rice balls with sweet filling',
    price: 65,
    emoji: 'BC',
    category: 'Desserts',
    imageAsset: FoodPulseImageAssets.buchi,
  );

  static const mcdoBurger = MenuItem(
    id: 16,
    restaurantId: 1,
    name: 'Cheeseburger Meal',
    description: 'Classic cheeseburger with fries and iced tea',
    price: 169,
    emoji: 'CB',
    category: 'Bestsellers',
    imageAsset: FoodPulseImageAssets.yumburger,
  );
  static const mcdoChicken = MenuItem(
    id: 17,
    restaurantId: 1,
    name: 'McChicken Meal',
    description: 'Crispy chicken sandwich with fries',
    price: 185,
    emoji: 'MC',
    category: 'Chicken',
    imageAsset: FoodPulseImageAssets.chickenjoyMeal,
  );
  static const kfcChicken = MenuItem(
    id: 18,
    restaurantId: 3,
    name: '1-pc Chicken Meal',
    description: 'Original recipe chicken with rice and gravy',
    price: 155,
    emoji: 'KC',
    category: 'Bestsellers',
    imageAsset: FoodPulseImageAssets.chickenjoyMeal,
  );
  static const kfcZinger = MenuItem(
    id: 19,
    restaurantId: 3,
    name: 'Zinger Combo',
    description: 'Spicy chicken fillet sandwich with fries',
    price: 199,
    emoji: 'ZG',
    category: 'Sandwiches',
    imageAsset: FoodPulseImageAssets.yumburger,
  );
  static const shakeysPizza = MenuItem(
    id: 20,
    restaurantId: 5,
    name: 'Manager\'s Choice Pizza',
    description: 'Thin-crust pizza with ham, beef, peppers, and onions',
    price: 429,
    emoji: 'MP',
    category: 'Bestsellers',
    imageAsset: FoodPulseImageAssets.pancitCanton,
  );
  static const shakeysChicken = MenuItem(
    id: 21,
    restaurantId: 5,
    name: 'Chicken \'N Mojos',
    description: 'Crispy chicken with signature potato mojos',
    price: 345,
    emoji: 'CM',
    category: 'Chicken',
    imageAsset: FoodPulseImageAssets.chickenInasal,
  );
  static const greenwichLasagna = MenuItem(
    id: 22,
    restaurantId: 6,
    name: 'Lasagna Supreme',
    description: 'Baked pasta with beefy tomato sauce and cheese',
    price: 165,
    emoji: 'LS',
    category: 'Bestsellers',
    imageAsset: FoodPulseImageAssets.jollySpaghetti,
  );
  static const greenwichPizza = MenuItem(
    id: 23,
    restaurantId: 6,
    name: 'Hawaiian Overload',
    description: 'Pizza with ham, pineapple, and mozzarella',
    price: 299,
    emoji: 'HP',
    category: 'Pizza',
    imageAsset: FoodPulseImageAssets.pancitCanton,
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
    mcdoBurger,
    mcdoChicken,
    kfcChicken,
    kfcZinger,
    shakeysPizza,
    shakeysChicken,
    greenwichLasagna,
    greenwichPizza,
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
