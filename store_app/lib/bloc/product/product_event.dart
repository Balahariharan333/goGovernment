import '../../model/product_model.dart';

abstract class ProductEvent {}

class LoadStoreProductsEvent extends ProductEvent {
  final String storeId;
  LoadStoreProductsEvent(this.storeId);
}

class AddProductEvent extends ProductEvent {
  final ProductModel product;
  AddProductEvent(this.product);
}

class ToggleProductAvailabilityEvent extends ProductEvent {
  final String productId;
  final bool isAvailable;
  ToggleProductAvailabilityEvent({required this.productId, required this.isAvailable});
}

class DeleteProductEvent extends ProductEvent {
  final String productId;
  DeleteProductEvent(this.productId);
}
