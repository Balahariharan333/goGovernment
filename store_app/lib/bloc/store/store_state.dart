import 'package:equatable/equatable.dart';
import '../../model/store_model.dart';

abstract class StoreState extends Equatable {
  const StoreState();

  @override
  List<Object?> get props => [];
}

class StoreInitial extends StoreState {}

class StoreLoading extends StoreState {}

class StoreLoaded extends StoreState {
  final StoreModel store;
  const StoreLoaded(this.store);

  @override
  List<Object?> get props => [store];
}

class StoreNotFound extends StoreState {
  final String identifier;
  const StoreNotFound(this.identifier);

  @override
  List<Object?> get props => [identifier];
}

class StoreSubmitting extends StoreState {}

class StoreSubmitSuccess extends StoreState {
  final StoreModel store;
  const StoreSubmitSuccess(this.store);

  @override
  List<Object?> get props => [store];
}

class StoreError extends StoreState {
  final String message;
  const StoreError(this.message);

  @override
  List<Object?> get props => [message];
}
