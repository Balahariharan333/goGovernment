import 'package:flutter_bloc/flutter_bloc.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  ProductBloc() : super(ProductInitial()) {
    on<LoadProducts>((event, emit) async {
      emit(ProductLoading());
      await Future.delayed(const Duration(milliseconds: 300)); // mock delay
      // Mock data based on store type
      final List<Map<String, dynamic>> mockProducts = event.storeType == 'medical'
          ? [
              {'id': 'm1', 'title': 'Watermelon striped', 'image': 'assets/images/product1.png', 'stockBadge': 'Only 3 left'},
              {'id': 'm2', 'title': 'Watermelon striped', 'image': 'assets/images/product1.png', 'stockBadge': 'Only 3 left'},
              {'id': 'm3', 'title': 'Watermelon striped', 'image': 'assets/images/product1.png', 'stockBadge': null},
            ]
          : [
              {'id': 'v1', 'title': 'Watermelon striped', 'image': 'assets/images/product2.png', 'stockBadge': null},
              {'id': 'v2', 'title': 'Watermelon striped', 'image': 'assets/images/product3.png', 'stockBadge': 'Only 3 left'},
            ];
      emit(ProductLoaded(mockProducts));
    });

    on<FilterProducts>((event, emit) async {
      if (state is ProductLoaded) {
        final loaded = state as ProductLoaded;
        final filtered = loaded.products.where((p) => p['title']
            .toString()
            .toLowerCase()
            .contains(event.query.toLowerCase()))
            .toList();
        emit(ProductLoaded(filtered));
      }
    });
  }
}
