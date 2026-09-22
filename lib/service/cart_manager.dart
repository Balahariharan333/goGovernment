import 'package:flutter/material.dart';
import '../bloc/cart/cart_bloc.dart';
import '../bloc/cart/cart_event.dart';
import '../utils/app_colors.dart';

class CartManager {
  static final CartManager instance = CartManager._();
  CartManager._() {
    productDetails.addAll(CartBloc.instance.state.productDetails);
    cartItems.value = Map.from(CartBloc.instance.state.cartItems);

    // Listen to CartBloc state changes and sync ValueNotifier
    CartBloc.instance.stream.listen((state) {
      productDetails.clear();
      productDetails.addAll(state.productDetails);
      cartItems.value = Map.from(state.cartItems);
    });
  }

  final ValueNotifier<Map<String, int>> cartItems =
      ValueNotifier(Map.from(CartBloc.instance.state.cartItems));
  final Map<String, Map<String, dynamic>> productDetails =
      Map.from(CartBloc.instance.state.productDetails);

  String? get currentStoreId {
    for (final entry in cartItems.value.entries) {
      if (entry.value > 0) {
        final details = productDetails[entry.key];
        final sId = details?['storeId']?.toString();
        if (sId != null && sId.isNotEmpty) return sId;
      }
    }
    return null;
  }

  String? get currentStoreName {
    for (final entry in cartItems.value.entries) {
      if (entry.value > 0) {
        final details = productDetails[entry.key];
        final sName = details?['storeName']?.toString() ?? details?['storeTitle']?.toString();
        if (sName != null && sName.isNotEmpty) return sName;
      }
    }
    return null;
  }

  int getStock(Map<String, dynamic> product) {
    if (product['stock'] != null) {
      return (product['stock'] as num).toInt();
    }
    final badge = product['stockBadge']?.toString() ?? '';
    final match = RegExp(r'(\d+)').firstMatch(badge);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 3;
    }
    return 5;
  }

  int getStockById(String productId) {
    final details = productDetails[productId];
    if (details != null) {
      return getStock(details);
    }
    return 5;
  }

  bool canIncrement(Map<String, dynamic> product, {int? currentQty}) {
    final id = product['id']?.toString() ?? '';
    final qty = currentQty ?? getQuantity(id);
    return qty < getStock(product);
  }

  bool canIncrementById(String productId) {
    final qty = getQuantity(productId);
    final stock = getStockById(productId);
    return qty < stock;
  }

  bool addToCart(Map<String, dynamic> product, {int qty = 1, String? productId, BuildContext? context}) {
    final id = productId ?? product['id']?.toString() ?? product['productId']?.toString() ?? '';
    if (id.isEmpty) return false;

    // Multi-Store check: Prevent mixing products from different stores in the same cart
    final incomingStoreId = product['storeId']?.toString();
    final existingStoreId = currentStoreId;
    final hasActiveCart = cartItems.value.values.any((q) => q > 0);

    if (hasActiveCart &&
        existingStoreId != null &&
        incomingStoreId != null &&
        incomingStoreId.isNotEmpty &&
        incomingStoreId != existingStoreId) {
      if (context != null) {
        final existingName = currentStoreName ?? 'another store';
        final incomingName = product['storeName']?.toString() ?? product['storeTitle']?.toString() ?? 'this store';
        showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Replace cart items?'),
            content: Text(
              'Your cart already contains items from "$existingName". Would you like to discard them and add items from "$incomingName"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Replace Cart', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ).then((confirmed) {
          if (confirmed == true) {
            clear();
            addToCart(
              product,
              qty: qty,
              productId: productId,
              context: (context.mounted) ? context : null,
            );
          }
        });
      }
      return false;
    }

    final stock = getStock(product);

    if (stock <= 0) {
      if (context != null) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item is currently out of stock'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return false;
    }

    final currentQty = getQuantity(id);
    final newQty = currentQty + qty;
    if (newQty > stock) {
      if (context != null) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Only $stock items available in stock'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return false;
    }

    if (product.isNotEmpty) {
      final normalized = {
        ...product,
        'id': id,
        'productId': id,
        if (product['name'] != null && product['title'] == null) 'title': product['name'],
        if (product['imageUrl'] != null && product['image'] == null) 'image': product['imageUrl'],
      };
      productDetails[id] = {...productDetails[id] ?? {}, ...normalized};
      CartBloc.instance.add(AddToCartEvent(id, normalized));
    } else {
      CartBloc.instance.add(AddToCartEvent(id, {'id': id, 'productId': id}));
    }
    return true;
  }

  bool updateQuantity(Map<String, dynamic> product, int qty, {String? productId, BuildContext? context}) {
    final id = productId ?? product['id']?.toString() ?? product['productId']?.toString() ?? '';
    if (id.isEmpty) return false;
    final stock = getStock(product);

    if (qty > stock) {
      if (context != null) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Maximum stock limit reached ($stock units)'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return false;
    }

    if (product.isNotEmpty) {
      productDetails[id] = {...productDetails[id] ?? {}, ...product, 'id': id};
    }
    CartBloc.instance.add(UpdateQuantityEvent(
      id,
      qty,
      details: product.isNotEmpty ? product : productDetails[id],
    ));
    return true;
  }

  bool updateQuantityById(String productId, int qty, {BuildContext? context}) {
    if (productId.isEmpty) return false;
    final stock = getStockById(productId);

    if (qty > stock) {
      if (context != null) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Maximum stock limit reached ($stock units)'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return false;
    }

    final details = productDetails[productId] ?? {'id': productId};
    CartBloc.instance.add(UpdateQuantityEvent(productId, qty, details: details));
    return true;
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
    productDetails.addAll(CartBloc.instance.state.productDetails);
    favoriteIds.value = Set.from(CartBloc.instance.state.favoriteIds);

    // Listen to CartBloc state changes and sync ValueNotifier
    CartBloc.instance.stream.listen((state) {
      productDetails.clear();
      productDetails.addAll(state.productDetails);
      favoriteIds.value = Set.from(state.favoriteIds);
    });
  }

  final ValueNotifier<Set<String>> favoriteIds =
      ValueNotifier(Set.from(CartBloc.instance.state.favoriteIds));
  final Map<String, Map<String, dynamic>> productDetails =
      Map.from(CartBloc.instance.state.productDetails);

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
