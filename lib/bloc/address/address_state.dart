import '../../hive/hive_service.dart';
import '../../model/address_model.dart';

class AddressState {
  final List<AddressModel> addresses;
  final AddressModel? selectedAddress;

  AddressState({
    required this.addresses,
    this.selectedAddress,
  });

  factory AddressState.initial() {
    final stored = HiveService.getSavedAddresses();
    if (stored.isNotEmpty) {
      final list = stored.map((m) => AddressModel.fromMap(m)).toList();
      final selectedIdx = HiveService.getSelectedAddressIndex();
      final validIdx = (selectedIdx >= 0 && selectedIdx < list.length) ? selectedIdx : 0;
      return AddressState(
        addresses: list,
        selectedAddress: list.isNotEmpty ? list[validIdx] : null,
      );
    }

    final defaultAddresses = [
      AddressModel(
        type: "Home",
        description: "552, 2nd Floor 18th Main, 15th Cross Rd, 4th Sector, HSR Layout, Bengaluru, Karnataka 560102",
        phone: "+91 98765 12345",
      ),
      AddressModel(
        type: "Office",
        description: "552, 2nd Floor 18th Main, 15th Cross Rd, 4th Sector, HSR Layout, Bengaluru, Karnataka 560102",
        phone: "+91 98765 12345",
      ),
      AddressModel(
        type: "Others",
        description: "552, 2nd Floor 18th Main, 15th Cross Rd, 4th Sector, HSR Layout, Bengaluru, Karnataka 560102",
        phone: "+91 98765 12345",
      ),
    ];
    // Persist default addresses in background
    HiveService.saveAddresses(defaultAddresses.map((a) => a.toMap()).toList());

    return AddressState(
      addresses: defaultAddresses,
      selectedAddress: defaultAddresses.first,
    );
  }

  AddressState copyWith({
    List<AddressModel>? addresses,
    AddressModel? selectedAddress,
  }) {
    return AddressState(
      addresses: addresses ?? this.addresses,
      selectedAddress: selectedAddress ?? this.selectedAddress,
    );
  }
}
