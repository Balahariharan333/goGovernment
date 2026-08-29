import 'package:flutter_bloc/flutter_bloc.dart';
import 'address_event.dart';
import 'address_state.dart';

class AddressBloc extends Bloc<AddressEvent, AddressState> {
  AddressBloc() : super(AddressState.initial()) {
    on<LoadAddressesEvent>((event, emit) {
      // Keep existing addresses
    });

    on<AddAddressEvent>((event, emit) {
      final updatedList = List.from(state.addresses)..add(event.address);
      emit(state.copyWith(addresses: List.castFrom(updatedList)));
    });

    on<UpdateAddressEvent>((event, emit) {
      final updatedList = List.from(state.addresses);
      if (event.index >= 0 && event.index < updatedList.length) {
        updatedList[event.index] = event.address;
      }
      emit(state.copyWith(addresses: List.castFrom(updatedList)));
    });

    on<DeleteAddressEvent>((event, emit) {
      final updatedList = List.from(state.addresses)..remove(event.address);
      emit(state.copyWith(addresses: List.castFrom(updatedList)));
    });

    on<SelectActiveAddressEvent>((event, emit) {
      emit(state.copyWith(selectedAddress: event.address));
    });
  }
}
