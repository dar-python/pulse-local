import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_local_app/core/data/mock_foodpulse_data.dart';
import 'package:pulse_local_app/core/models/menu_item.dart';
import 'package:pulse_local_app/core/models/restaurant.dart';

void main() {
  test('fallback restaurants expose the expected local image assets', () {
    final imageAssetsByName = {
      for (final restaurant in MockFoodPulseData.restaurants)
        restaurant.name: restaurant.imageAsset,
    };

    expect(imageAssetsByName, {
      'Tambayan Grill': 'assets/images/restaurants/tambayan-grill.webp',
      'Jollibee Express': 'assets/images/restaurants/jollibee-express.webp',
      'Chao Fan House': 'assets/images/restaurants/chao-fan-house.webp',
    });
  });

  test('fallback menu items expose the expected local food image assets', () {
    final imageAssetsByName = {
      for (final item in MockFoodPulseData.menuItems)
        item.name: item.imageAsset,
    };

    expect(
      imageAssetsByName['Pork Sinigang'],
      'assets/images/foods/pork-sinigang.webp',
    );
    expect(
      imageAssetsByName['Chicken Inasal'],
      'assets/images/foods/chicken-inasal.webp',
    );
    expect(
      imageAssetsByName['Lechon Kawali'],
      'assets/images/foods/lechon-kawali.webp',
    );
    expect(
      imageAssetsByName['Pancit Canton'],
      'assets/images/foods/pancit-canton.webp',
    );
    expect(
      imageAssetsByName['Halo-Halo'],
      'assets/images/foods/halo-halo.webp',
    );
    expect(
      imageAssetsByName['Chickenjoy Meal'],
      'assets/images/foods/chickenjoy-meal.webp',
    );
    expect(
      imageAssetsByName['Jolly Spaghetti'],
      'assets/images/foods/jolly-spaghetti.webp',
    );
    expect(
      imageAssetsByName['Yumburger'],
      'assets/images/foods/yumburger.webp',
    );
    expect(
      imageAssetsByName['Burger Steak'],
      'assets/images/foods/burger-steak.webp',
    );
    expect(
      imageAssetsByName['Peach Mango Pie'],
      'assets/images/foods/peach-mango-pie.webp',
    );
    expect(
      imageAssetsByName['Pork Chao Fan'],
      'assets/images/foods/pork-chao-fan.webp',
    );
    expect(
      imageAssetsByName['Beef Chao Fan'],
      'assets/images/foods/beef-chao-fan.webp',
    );
    expect(imageAssetsByName['Siomai'], 'assets/images/foods/siomai.webp');
    expect(
      imageAssetsByName['Wonton Noodles'],
      'assets/images/foods/wonton-noodles.webp',
    );
    expect(imageAssetsByName['Buchi'], 'assets/images/foods/buchi.webp');
  });

  test('models parse optional image_asset keys without requiring them', () {
    final restaurant = Restaurant.fromJson({
      'id': 9,
      'name': 'Remote Grill',
      'cuisine': 'Filipino',
      'rating': 4.5,
      'delivery_time': '18-25 min',
      'minimum_order': 120,
      'emoji': 'RG',
      'risk_score': 30,
      'image_asset': 'assets/images/restaurants/remote-grill.webp',
    });
    final imageLessMenuItem = MenuItem.fromJson({
      'id': 99,
      'name': 'Remote Soup',
      'description': 'Warm broth',
      'price': 100,
      'emoji': 'RS',
      'category': 'Bestsellers',
    });

    expect(
      restaurant.imageAsset,
      'assets/images/restaurants/remote-grill.webp',
    );
    expect(imageLessMenuItem.imageAsset, isNull);
  });
}
