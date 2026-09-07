import 'package:flutter_bloc/flutter_bloc.dart';
import '../../hive/hive_service.dart';
import '../../model/address_model.dart';
import 'address_event.dart';
import 'address_state.dart';

class AddressBloc extends Bloc<AddressEvent, AddressState> {
  AddressBloc() : super(AddressState.initial()) {
    on<LoadAddressesEvent>((event, emit) {
      final stored = HiveService.getSavedAddresses();
      final list = stored.map((m) => AddressModel.fromMap(m)).toList();
      final selectedIdx = HiveService.getSelectedAddressIndex();
      final validIdx = (selectedIdx >= 0 && selectedIdx < list.length) ? selectedIdx : (list.isNotEmpty ? 0 : -1);
      emit(AddressState(
        addresses: list,
        selectedAddress: validIdx != -1 ? list[validIdx] : null,
      ));
    });

    on<AddAddressEvent>((event, emit) {
      final updatedList = List<AddressModel>.from(state.addresses)..add(event.address);
      HiveService.saveAddresses(updatedList.map((a) => a.toMap()).toList());
      final newSelected = event.address;
      final idx = updatedList.indexWhere((a) => a.description.trim() == newSelected.description.trim());
      HiveService.setSelectedAddressIndex(idx != -1 ? idx : 0);
      emit(AddressState(
        addresses: updatedList,
        selectedAddress: newSelected,
      ));
    });

    on<UpdateAddressEvent>((event, emit) {
      final updatedList = List<AddressModel>.from(state.addresses);
      if (event.index >= 0 && event.index < updatedList.length) {
        final oldAddr = updatedList[event.index];
        updatedList[event.index] = event.address;
        HiveService.saveAddresses(updatedList.map((a) => a.toMap()).toList());

        AddressModel? newSelected = state.selectedAddress;
        if (newSelected != null && newSelected.description.trim() == oldAddr.description.trim()) {
          newSelected = event.address;
          HiveService.setSelectedAddressIndex(event.index);
        }
        emit(AddressState(
          addresses: updatedList,
          selectedAddress: newSelected,
        ));
      }
    });

    on<DeleteAddressEvent>((event, emit) {
      final updatedList = List<AddressModel>.from(state.addresses)
        ..removeWhere((a) => a.description.trim() == event.address.description.trim());
      HiveService.saveAddresses(updatedList.map((a) => a.toMap()).toList());

      AddressModel? newSelected = state.selectedAddress;
      if (newSelected != null &&
          (newSelected.description.trim() == event.address.description.trim() ||
           !updatedList.any((a) => a.description.trim() == newSelected!.description.trim()))) {
        newSelected = updatedList.isNotEmpty ? updatedList.first : null;
      }

      final newIdx = newSelected != null ? updatedList.indexOf(newSelected) : -1;
      HiveService.setSelectedAddressIndex(newIdx);

      emit(AddressState(
        addresses: updatedList,
        selectedAddress: newSelected,
      ));
    });

    on<SelectActiveAddressEvent>((event, emit) {
      final idx = state.addresses.indexWhere((a) => a.description == event.address.description);
      if (idx != -1) {
        HiveService.setSelectedAddressIndex(idx);
      }
      emit(state.copyWith(selectedAddress: event.address));
    });
  }
}
