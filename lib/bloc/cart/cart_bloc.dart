import 'package:flutter_bloc/flutter_bloc.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  static final CartBloc instance = CartBloc._();

  CartBloc._() : super(CartState.initial()) {
    on<AddToCartEvent>((event, emit) {
      final updatedCart = Map<String, int>.from(state.cartItems);
      final updatedDetails = Map<String, Map<String, dynamic>>.from(state.productDetails);

      updatedCart[event.productId] = (updatedCart[event.productId] ?? 0) + 1;
      updatedDetails[event.productId] = event.details;

      emit(state.copyWith(
        cartItems: updatedCart,
        productDetails: updatedDetails,
      ));
    });

    on<RemoveFromCartEvent>((event, emit) {
      final updatedCart = Map<String, int>.from(state.cartItems);
      final updatedDetails = Map<String, Map<String, dynamic>>.from(state.productDetails);

      if (updatedCart.containsKey(event.productId)) {
        final currentQty = updatedCart[event.productId]!;
        if (currentQty > 1) {
          updatedCart[event.productId] = currentQty - 1;
        } else {
          updatedCart.remove(event.productId);
          updatedDetails.remove(event.productId);
        }
      }

      emit(state.copyWith(
        cartItems: updatedCart,
        productDetails: updatedDetails,
      ));
    });

    on<UpdateQuantityEvent>((event, emit) {
      final updatedCart = Map<String, int>.from(state.cartItems);
      final updatedDetails = Map<String, Map<String, dynamic>>.from(state.productDetails);

      if (event.quantity > 0) {
        updatedCart[event.productId] = event.quantity;
      } else {
        updatedCart.remove(event.productId);
        updatedDetails.remove(event.productId);
      }

      emit(state.copyWith(
        cartItems: updatedCart,
        productDetails: updatedDetails,
      ));
    });

    on<ClearCartEvent>((event, emit) {
      emit(state.copyWith(
        cartItems: {},
        productDetails: {},
      ));
    });

    on<ToggleFavoriteEvent>((event, emit) {
      final updatedFavorites = Set<String>.from(state.favoriteIds);
      final updatedDetails = Map<String, Map<String, dynamic>>.from(state.productDetails);

      if (updatedFavorites.contains(event.productId)) {
        updatedFavorites.remove(event.productId);
      } else {
        updatedFavorites.add(event.productId);
        updatedDetails[event.productId] = event.details;
      }

      emit(state.copyWith(
        favoriteIds: updatedFavorites,
        productDetails: updatedDetails,
      ));
    });
  }
}
