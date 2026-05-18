class FoodPulseImageAssets {
  const FoodPulseImageAssets._();

  static const tambayanGrill = 'assets/images/restaurants/tambayan-grill.webp';
  static const jollibeeExpress =
      'assets/images/restaurants/jollibee-express.webp';
  static const chaoFanHouse = 'assets/images/restaurants/chao-fan-house.webp';

  static const porkSinigang = 'assets/images/foods/pork-sinigang.webp';
  static const chickenInasal = 'assets/images/foods/chicken-inasal.webp';
  static const lechonKawali = 'assets/images/foods/lechon-kawali.webp';
  static const pancitCanton = 'assets/images/foods/pancit-canton.webp';
  static const haloHalo = 'assets/images/foods/halo-halo.webp';
  static const chickenjoyMeal = 'assets/images/foods/chickenjoy-meal.webp';
  static const jollySpaghetti = 'assets/images/foods/jolly-spaghetti.webp';
  static const yumburger = 'assets/images/foods/yumburger.webp';
  static const burgerSteak = 'assets/images/foods/burger-steak.webp';
  static const peachMangoPie = 'assets/images/foods/peach-mango-pie.webp';
  static const porkChaoFan = 'assets/images/foods/pork-chao-fan.webp';
  static const beefChaoFan = 'assets/images/foods/beef-chao-fan.webp';
  static const siomai = 'assets/images/foods/siomai.webp';
  static const wontonNoodles = 'assets/images/foods/wonton-noodles.webp';
  static const buchi = 'assets/images/foods/buchi.webp';

  static const _restaurantAssetsById = {
    1: tambayanGrill,
    2: jollibeeExpress,
    3: chaoFanHouse,
  };

  static const _restaurantAssetsBySlug = {
    'tambayan-grill': tambayanGrill,
    'jollibee-express': jollibeeExpress,
    'chao-fan-house': chaoFanHouse,
  };

  static const _menuAssetsById = {
    1: porkSinigang,
    2: chickenInasal,
    3: lechonKawali,
    4: pancitCanton,
    5: haloHalo,
    6: chickenjoyMeal,
    7: jollySpaghetti,
    8: yumburger,
    9: burgerSteak,
    10: peachMangoPie,
    11: porkChaoFan,
    12: beefChaoFan,
    13: siomai,
    14: wontonNoodles,
    15: buchi,
  };

  static const _menuAssetsBySlug = {
    'pork-sinigang': porkSinigang,
    'chicken-inasal': chickenInasal,
    'lechon-kawali': lechonKawali,
    'pancit-canton': pancitCanton,
    'halo-halo': haloHalo,
    'chickenjoy-meal': chickenjoyMeal,
    'jolly-spaghetti': jollySpaghetti,
    'yumburger': yumburger,
    'burger-steak': burgerSteak,
    'peach-mango-pie': peachMangoPie,
    'pork-chao-fan': porkChaoFan,
    'beef-chao-fan': beefChaoFan,
    'siomai': siomai,
    'wonton-noodles': wontonNoodles,
    'buchi': buchi,
  };

  static String? restaurantAsset({
    required int id,
    required String name,
    String? slug,
  }) {
    return _assetFor(
      id: id,
      name: name,
      slug: slug,
      assetsById: _restaurantAssetsById,
      assetsBySlug: _restaurantAssetsBySlug,
    );
  }

  static String? menuItemAsset({
    required int id,
    required String name,
    String? slug,
  }) {
    return _assetFor(
      id: id,
      name: name,
      slug: slug,
      assetsById: _menuAssetsById,
      assetsBySlug: _menuAssetsBySlug,
    );
  }

  static String? _assetFor({
    required int id,
    required String name,
    required Map<int, String> assetsById,
    required Map<String, String> assetsBySlug,
    String? slug,
  }) {
    final explicitSlug = _slugFor(slug);
    if (explicitSlug != null && assetsBySlug.containsKey(explicitSlug)) {
      return assetsBySlug[explicitSlug];
    }

    final nameSlug = _slugFor(name);
    if (nameSlug != null && assetsBySlug.containsKey(nameSlug)) {
      return assetsBySlug[nameSlug];
    }

    return assetsById[id];
  }

  static String? _slugFor(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}
