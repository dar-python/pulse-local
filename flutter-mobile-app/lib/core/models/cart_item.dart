import 'menu_item.dart';

class CartItem {
  const CartItem({required this.item, required this.quantity});

  final MenuItem item;
  final int quantity;

  int get lineTotal => item.price * quantity;
}
