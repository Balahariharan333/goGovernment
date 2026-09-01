import 'package:flutter/material.dart';
import '../bloc/cart/cart_bloc.dart';
import '../bloc/cart/cart_event.dart';

class CartManager {
  static final CartManager instance = CartManager._();
  CartManager._() {
    // Listen to CartBloc state changes and sync ValueNotifier
    CartBloc.instance.stream.listen((state) {
      productDetails.clear();
      productDetails.addAll(state.productDetails);
      cartItems.value = state.cartItems;
    });
  }

  final ValueNotifier<Map<String, int>> cartItems = ValueNotifier({});
  final Map<String, Map<String, dynamic>> productDetails = {};

  void addToCart(Map<String, dynamic> product, {int qty = 1, String? productId}) {
    final id = productId ?? product['id']?.toString() ?? '';
    if (id.isEmpty) return;
    if (product.isNotEmpty) {
      productDetails[id] = {...productDetails[id] ?? {}, ...product, 'id': id};
    }
    CartBloc.instance.add(AddToCartEvent(id, product.isNotEmpty ? product : {'id': id}));
  }

  void updateQuantity(Map<String, dynamic> product, int qty, {String? productId}) {
    final id = productId ?? product['id']?.toString() ?? '';
    if (id.isEmpty) return;
    if (product.isNotEmpty) {
      productDetails[id] = {...productDetails[id] ?? {}, ...product, 'id': id};
    }
    CartBloc.instance.add(UpdateQuantityEvent(
      id,
      qty,
      details: product.isNotEmpty ? product : productDetails[id],
    ));
  }

  void updateQuantityById(String productId, int qty) {
    if (productId.isEmpty) return;
    final details = productDetails[productId] ?? {'id': productId};
    CartBloc.instance.add(UpdateQuantityEvent(productId, qty, details: details));
  }

  void removeFromCart(String productId) {
    CartBloc.instance.add(RemoveFromCartEvent(productId));
  }

  int getQuantity(String productId) {
    return CartBloc.instance.state.cartItems[productId] ?? 0;
  }

  int get totalCartCount {
    return CartBloc.instance.state.totalCartCount;
  }

  void clear() {
    CartBloc.instance.add(ClearCartEvent());
  }
}

class WishlistManager {
  static final WishlistManager instance = WishlistManager._();
  WishlistManager._() {
    // Listen to CartBloc state changes and sync ValueNotifier
    CartBloc.instance.stream.listen((state) {
      favoriteIds.value = state.favoriteIds;
    });
  }

  final ValueNotifier<Set<String>> favoriteIds = ValueNotifier({});
  final Map<String, Map<String, dynamic>> productDetails = {};

  void toggleFavorite(Map<String, dynamic> product) {
    final id = product['id']?.toString() ?? '';
    if (id.isEmpty) return;
    productDetails[id] = product;
    CartBloc.instance.add(ToggleFavoriteEvent(id, product));
  }

  bool isFavorite(String productId) {
    return CartBloc.instance.state.favoriteIds.contains(productId);
  }

  List<Map<String, dynamic>> get wishlistedProducts {
    return CartBloc.instance.state.favoriteIds
        .map((id) => productDetails[id])
        .where((p) => p != null)
        .cast<Map<String, dynamic>>()
        .toList();
  }
}
