import '../../screen/profile/address_book_screen.dart';

class AddressState {
  final List<AddressModel> addresses;
  final AddressModel? selectedAddress;

  AddressState({
    required this.addresses,
    this.selectedAddress,
  });

  factory AddressState.initial() {
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
