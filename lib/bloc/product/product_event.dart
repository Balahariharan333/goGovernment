import 'package:equatable/equatable.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

class LoadProducts extends ProductEvent {
  final String storeId;
  final String storeType; // 'medical' or 'vegstore'
  const LoadProducts({required this.storeId, required this.storeType});

  @override
  List<Object?> get props => [storeId, storeType];
}

class FilterProducts extends ProductEvent {
  final String query;
  const FilterProducts(this.query);

  @override
  List<Object?> get props => [query];
}
