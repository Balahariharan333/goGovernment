import 'package:flutter_bloc/flutter_bloc.dart';
import '../../hive/hive_service.dart';
import '../../model/address_model.dart';
import 'address_event.dart';
import 'address_state.dart';

class AddressBloc extends Bloc<AddressEvent, AddressState> {
  AddressBloc() : super(AddressState.initial()) {
    on<LoadAddressesEvent>((event, emit) {
      final stored = HiveService.getSavedAddresses();
      if (stored.isNotEmpty) {
        final list = stored.map((m) => AddressModel.fromMap(m)).toList();
        final selectedIdx = HiveService.getSelectedAddressIndex();
        final validIdx = (selectedIdx >= 0 && selectedIdx < list.length) ? selectedIdx : 0;
        emit(state.copyWith(
          addresses: list,
          selectedAddress: list.isNotEmpty ? list[validIdx] : null,
        ));
      }
    });

    on<AddAddressEvent>((event, emit) {
      final updatedList = List<AddressModel>.from(state.addresses)..add(event.address);
      HiveService.saveAddresses(updatedList.map((a) => a.toMap()).toList());
      emit(state.copyWith(addresses: updatedList));
    });

    on<UpdateAddressEvent>((event, emit) {
      final updatedList = List<AddressModel>.from(state.addresses);
      if (event.index >= 0 && event.index < updatedList.length) {
        updatedList[event.index] = event.address;
        HiveService.saveAddresses(updatedList.map((a) => a.toMap()).toList());
      }
      emit(state.copyWith(addresses: updatedList));
    });

    on<DeleteAddressEvent>((event, emit) {
      final updatedList = List<AddressModel>.from(state.addresses)..remove(event.address);
      HiveService.saveAddresses(updatedList.map((a) => a.toMap()).toList());
      emit(state.copyWith(addresses: updatedList));
    });

    on<SelectActiveAddressEvent>((event, emit) {
      final idx = state.addresses.indexOf(event.address);
      if (idx != -1) {
        HiveService.setSelectedAddressIndex(idx);
      }
      emit(state.copyWith(selectedAddress: event.address));
    });
  }
}
