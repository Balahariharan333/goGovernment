class AddressModel {
  String type;
  String description;
  String phone;
  String? landmark;
  String? imagePath;

  AddressModel({
    required this.type,
    required this.description,
    required this.phone,
    this.landmark,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'description': description,
      'phone': phone,
      'landmark': landmark,
      'imagePath': imagePath,
    };
  }

  factory AddressModel.fromMap(Map<String, dynamic> map) {
    return AddressModel(
      type: map['type']?.toString() ?? 'Home',
      description: map['description']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      landmark: map['landmark']?.toString(),
      imagePath: map['imagePath']?.toString(),
    );
  }
}
