import 'package:equatable/equatable.dart';
import '../../model/store_model.dart';

abstract class StoreEvent extends Equatable {
  const StoreEvent();

  @override
  List<Object?> get props => [];
}

class FetchMyStoreEvent extends StoreEvent {
  final String identifier;
  const FetchMyStoreEvent(this.identifier);

  @override
  List<Object?> get props => [identifier];
}

class RegisterStoreEvent extends StoreEvent {
  final StoreModel store;
  const RegisterStoreEvent(this.store);

  @override
  List<Object?> get props => [store];
}

class ToggleStoreOnlineEvent extends StoreEvent {
  final String storeId;
  final bool isOnline;
  const ToggleStoreOnlineEvent({required this.storeId, required this.isOnline});

  @override
  List<Object?> get props => [storeId, isOnline];
}

class RefreshStoreStatusEvent extends StoreEvent {
  final String identifier;
  const RefreshStoreStatusEvent(this.identifier);

  @override
  List<Object?> get props => [identifier];
}
