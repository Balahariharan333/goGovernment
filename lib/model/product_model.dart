class ProductModel {
  final String id;
  final String title;
  final String price;
  final String originalPrice;
  final String image;
  final String unit;
  final double rating;
  final int reviewsCount;
  final String category;
  final String? discount;
  final String description;
  final int stock;

  ProductModel({
    required this.id,
    required this.title,
    required this.price,
    this.originalPrice = '',
    required this.image,
    this.unit = '1 kg',
    this.rating = 4.5,
    this.reviewsCount = 0,
    this.category = '',
    this.discount,
    this.description = '',
    this.stock = 5,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'originalPrice': originalPrice,
      'image': image,
      'unit': unit,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'category': category,
      'discount': discount,
      'description': description,
      'stock': stock,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      price: map['price']?.toString() ?? '',
      originalPrice: map['originalPrice']?.toString() ?? '',
      image: map['image']?.toString() ?? '',
      unit: map['unit']?.toString() ?? '1 kg',
      rating: (map['rating'] as num?)?.toDouble() ?? 4.5,
      reviewsCount: (map['reviewsCount'] as num?)?.toInt() ?? 0,
      category: map['category']?.toString() ?? '',
      discount: map['discount']?.toString(),
      description: map['description']?.toString() ?? '',
      stock: (map['stock'] as num?)?.toInt() ?? 5,
    );
  }
}
