class AddressModel {
  String type;
  String description;
  String phone;

  AddressModel({
    required this.type,
    required this.description,
    required this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'description': description,
      'phone': phone,
    };
  }

  factory AddressModel.fromMap(Map<String, dynamic> map) {
    return AddressModel(
      type: map['type']?.toString() ?? 'Home',
      description: map['description']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
    );
  }
}
