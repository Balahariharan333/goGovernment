import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../../network/api_client.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  List<Map<String, dynamic>> _allProducts = [];

  ProductBloc() : super(ProductInitial()) {
    on<LoadProducts>((event, emit) async {
      emit(ProductLoading());
      try {
        final url = '${ApiClient.baseUrl}/products/store/${event.storeId}';
        final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final rawProducts = (data['products'] as List? ?? []);

          _allProducts = rawProducts
              .where((p) => p['isAvailable'] != false)
              .map<Map<String, dynamic>>((p) {
            final double price = (p['price'] as num?)?.toDouble() ?? 0.0;
            final double origPrice = (p['originalPrice'] as num?)?.toDouble() ?? price;
            final int stock = (p['stock'] as num?)?.toInt() ?? 0;

            int discount = 0;
            if (p['discountPercentage'] is num) {
              discount = (p['discountPercentage'] as num).toInt();
            } else if (p['discountPercentage'] is String) {
              final match = RegExp(r'\d+').firstMatch(p['discountPercentage']);
              if (match != null) {
                discount = int.tryParse(match.group(0) ?? '') ?? 0;
              }
            }
            if (discount == 0 && origPrice > price && origPrice > 0) {
              discount = (((origPrice - price) / origPrice) * 100).round();
            }

            String stockBadge = '';
            if (stock <= 0) {
              stockBadge = 'Out of Stock';
            } else if (stock <= 3) {
              stockBadge = 'Only $stock left';
            }

            return {
              'id': p['productId'] ?? p['_id'] ?? '',
              'title': p['title'] ?? 'Product',
              'price': price,
              'originalPrice': origPrice,
              'discountPercentage': discount,
              'stock': stock,
              'unit': p['unit'] ?? '1 Units',
              'image': (p['image'] != null && p['image'].toString().trim().isNotEmpty)
                  ? p['image'].toString().trim()
                  : '',
              'stockBadge': stockBadge.isNotEmpty ? stockBadge : null,
              'brand': p['brand'] ?? 'Unbranded',
              'packOf': p['packOf'] ?? '1',
              'type': p['type'] ?? (event.storeType == 'medical' ? 'Medicine' : 'Grocery'),
              'shelfLife': p['shelfLife'] ?? '7 Days',
              'formFactor': p['formFactor'] ?? 'Standard',
              'origin': p['origin'] ?? 'India',
              'description': p['description'] ?? '',
              'isSubsidized': p['isSubsidized'] == true,
              'subsidyLimit': p['subsidyLimit'],
              'storeId': p['storeId'] ?? event.storeId,
            };
          }).toList();

          emit(ProductLoaded(_allProducts));
        } else {
          _allProducts = [];
          emit(const ProductLoaded([]));
        }
      } catch (e) {
        _allProducts = [];
        emit(const ProductLoaded([]));
      }
    });

    on<FilterProducts>((event, emit) {
      if (event.query.trim().isEmpty) {
        emit(ProductLoaded(_allProducts));
      } else {
        final query = event.query.toLowerCase();
        final filtered = _allProducts.where((p) {
          final title = (p['title'] ?? '').toString().toLowerCase();
          final brand = (p['brand'] ?? '').toString().toLowerCase();
          return title.contains(query) || brand.contains(query);
        }).toList();
        emit(ProductLoaded(filtered));
      }
    });
  }
}
