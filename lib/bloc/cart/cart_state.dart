class CartState {
  final Map<String, int> cartItems;
  final Map<String, Map<String, dynamic>> productDetails;
  final Set<String> favoriteIds;

  CartState({
    required this.cartItems,
    required this.productDetails,
    required this.favoriteIds,
  });

  factory CartState.initial() {
    return CartState(
      cartItems: {},
      productDetails: {},
      favoriteIds: {},
    );
  }

  CartState copyWith({
    Map<String, int>? cartItems,
    Map<String, Map<String, dynamic>>? productDetails,
    Set<String>? favoriteIds,
  }) {
    return CartState(
      cartItems: cartItems ?? this.cartItems,
      productDetails: productDetails ?? this.productDetails,
      favoriteIds: favoriteIds ?? this.favoriteIds,
    );
  }

  int get totalCartCount {
    int total = 0;
    cartItems.forEach((_, qty) => total += qty);
    return total;
  }
}
