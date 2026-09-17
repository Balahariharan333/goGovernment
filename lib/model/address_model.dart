class AddressModel {
  String? id;
  String type;
  String description;
  String phone;
  String? name;
  String? floor;
  String? landmark;
  String? imagePath;
  bool isDefault;

  AddressModel({
    this.id,
    required this.type,
    required this.description,
    required this.phone,
    this.name,
    this.floor,
    this.landmark,
    this.imagePath,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'description': description,
      'phone': phone,
      'name': name,
      'floor': floor,
      'landmark': landmark,
      'imagePath': imagePath,
      'isDefault': isDefault,
    };
  }

  factory AddressModel.fromMap(Map<String, dynamic> map) {
    return AddressModel(
      id: (map['id'] ?? map['addressId'] ?? map['_id'])?.toString(),
      type: map['type']?.toString() ?? 'Home',
      description: map['description']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      name: map['name']?.toString(),
      floor: map['floor']?.toString(),
      landmark: map['landmark']?.toString(),
      imagePath: map['imagePath']?.toString(),
      isDefault: map['isDefault'] == true,
    );
  }
}
