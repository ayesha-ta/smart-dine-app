import 'package:flutter/material.dart';
import '../models/menu_item.dart';

class CartItem {
  final MenuItem menuItem;
  int quantity;
  String? specialInstructions;

  CartItem({
    required this.menuItem,
    this.quantity = 1,
    this.specialInstructions,
  });
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.menuItem.price * cartItem.quantity;
    });
    return total;
  }

  void addItem(MenuItem menuItem, int quantity, String? specialInstructions) {
    if (_items.containsKey(menuItem.id)) {
      _items.update(
        menuItem.id,
        (existingCartItem) => CartItem(
          menuItem: existingCartItem.menuItem,
          quantity: existingCartItem.quantity + quantity,
          specialInstructions: specialInstructions ?? existingCartItem.specialInstructions,
        ),
      );
    } else {
      _items.putIfAbsent(
        menuItem.id,
        () => CartItem(
          menuItem: menuItem,
          quantity: quantity,
          specialInstructions: specialInstructions,
        ),
      );
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void decrementItem(String productId) {
    if (!_items.containsKey(productId)) return;
    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existing) => CartItem(
          menuItem: existing.menuItem,
          quantity: existing.quantity - 1,
          specialInstructions: existing.specialInstructions,
        ),
      );
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
