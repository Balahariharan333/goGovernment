import 'package:flutter_bloc/flutter_bloc.dart';
import '../../model/product_model.dart';
import '../../network/product_api_service.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  static final ProductBloc instance = ProductBloc._internal();
  factory ProductBloc() => instance;

  List<ProductModel> _currentProducts = [];

  ProductBloc._internal() : super(ProductInitial()) {
    on<LoadStoreProductsEvent>((event, emit) async {
      emit(ProductLoading());
      final prods = await ProductApiService.getProductsByStore(event.storeId);
      _currentProducts = prods;
      emit(ProductLoaded(List.from(_currentProducts)));
    });

    on<AddProductEvent>((event, emit) async {
      emit(ProductSubmitting());
      final res = await ProductApiService.addProduct(event.product);
      if (res != null && res['success'] == true && res['product'] != null) {
        final newProd = ProductModel.fromJson(res['product'] as Map<String, dynamic>);
        _currentProducts.insert(0, newProd);
        emit(ProductSubmitSuccess(newProd, message: res['message'] ?? 'Product added successfully!'));
        emit(ProductLoaded(List.from(_currentProducts)));
      } else {
        emit(ProductError(res?['error'] ?? 'Failed to add product'));
        emit(ProductLoaded(List.from(_currentProducts)));
      }
    });

    on<ToggleProductAvailabilityEvent>((event, emit) async {
      final success = await ProductApiService.toggleAvailability(event.productId, event.isAvailable);
      if (success) {
        final idx = _currentProducts.indexWhere((p) => p.productId == event.productId);
        if (idx != -1) {
          _currentProducts[idx] = _currentProducts[idx].copyWith(isAvailable: event.isAvailable);
          emit(ProductLoaded(List.from(_currentProducts)));
        }
      }
    });

    on<DeleteProductEvent>((event, emit) async {
      final success = await ProductApiService.deleteProduct(event.productId);
      if (success) {
        _currentProducts.removeWhere((p) => p.productId == event.productId);
        emit(ProductLoaded(List.from(_currentProducts)));
      }
    });
  }
}
