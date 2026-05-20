import 'package:flutter/foundation.dart';

import '../../core/models/cart_item.dart';
import '../../core/models/menu_item.dart';
import '../../core/models/restaurant.dart';

class FoodPulseCartController extends ChangeNotifier {
  Restaurant? _restaurant;
  final Map<int, CartItem> _itemsById = {};

  Restaurant? get restaurant => _restaurant;

  List<CartItem> get items => List.unmodifiable(_itemsById.values);

  int get totalQuantity {
    return _itemsById.values.fold(0, (sum, item) => sum + item.quantity);
  }

  int get subtotal {
    return _itemsById.values.fold(0, (sum, item) => sum + item.lineTotal);
  }

  bool get isEmpty => _itemsById.isEmpty;

  bool hasDifferentRestaurant(Restaurant restaurant) {
    return _restaurant != null &&
        _restaurant!.id != restaurant.id &&
        _itemsById.isNotEmpty;
  }

  List<CartItem> itemsForRestaurant(Restaurant restaurant) {
    if (_restaurant?.id != restaurant.id) {
      return const [];
    }

    return items;
  }

  int quantityForRestaurant(Restaurant restaurant) {
    if (_restaurant?.id != restaurant.id) {
      return 0;
    }

    return totalQuantity;
  }

  int subtotalForRestaurant(Restaurant restaurant) {
    if (_restaurant?.id != restaurant.id) {
      return 0;
    }

    return subtotal;
  }

  void addItem({
    required Restaurant restaurant,
    required MenuItem item,
    bool clearExisting = false,
  }) {
    if (clearExisting) {
      _itemsById.clear();
      _restaurant = null;
    }

    if (hasDifferentRestaurant(restaurant)) {
      throw StateError('Clear the current cart before changing restaurants.');
    }

    _restaurant ??= restaurant;
    final current = _itemsById[item.id];
    _itemsById[item.id] = CartItem(
      item: item,
      quantity: (current?.quantity ?? 0) + 1,
    );
    notifyListeners();
  }

<<<<<<< HEAD
  void decreaseItem(MenuItem item) {
    final current = _itemsById[item.id];
=======
  void increaseItem({required Restaurant restaurant, required MenuItem item}) {
    addItem(restaurant: restaurant, item: item);
  }

  void decreaseItem(int itemId) {
    final current = _itemsById[itemId];
>>>>>>> 18df08fdba0b440f2f19572b1e7b31a29cc5205f
    if (current == null) {
      return;
    }

    if (current.quantity <= 1) {
<<<<<<< HEAD
      _itemsById.remove(item.id);
    } else {
      _itemsById[item.id] = CartItem(
        item: item,
        quantity: current.quantity - 1,
      );
    }

    if (_itemsById.isEmpty) {
      _restaurant = null;
    }
    notifyListeners();
  }

  void removeItem(MenuItem item) {
    if (!_itemsById.containsKey(item.id)) {
      return;
    }

    _itemsById.remove(item.id);
=======
      removeItem(itemId);
      return;
    }

    _itemsById[itemId] = CartItem(
      item: current.item,
      quantity: current.quantity - 1,
    );
    notifyListeners();
  }

  void removeItem(int itemId) {
    if (!_itemsById.containsKey(itemId)) {
      return;
    }

    _itemsById.remove(itemId);
>>>>>>> 18df08fdba0b440f2f19572b1e7b31a29cc5205f
    if (_itemsById.isEmpty) {
      _restaurant = null;
    }
    notifyListeners();
  }

<<<<<<< HEAD
  int quantityForItem(MenuItem item) {
    return _itemsById[item.id]?.quantity ?? 0;
  }

=======
>>>>>>> 18df08fdba0b440f2f19572b1e7b31a29cc5205f
  void clear() {
    if (_itemsById.isEmpty && _restaurant == null) {
      return;
    }

    _itemsById.clear();
    _restaurant = null;
    notifyListeners();
  }
}
