import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/responsive_helper.dart';
import '../../../widget/common_background.dart';
import '../../../widget/custom_text.dart';
import '../../../widget/common_cart_badge.dart';
import 'product_details_screen.dart';
import 'cart_screen.dart';
import '../../../service/cart_manager.dart';
import '../../../widget/common_wishlist_button.dart';

class AllProductsScreen extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> products;
  final String storeType;

  const AllProductsScreen({
    super.key,
    required this.title,
    required this.products,
    required this.storeType,
  });

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  String _searchQuery = '';
  late final VoidCallback _cartListener;
  late final VoidCallback _favListener;

  @override
  void initState() {
    super.initState();
    _cartListener = () {
      if (mounted) setState(() {});
    };
    _favListener = () {
      if (mounted) setState(() {});
    };
    CartManager.instance.cartItems.addListener(_cartListener);
    WishlistManager.instance.favoriteIds.addListener(_favListener);
  }

  @override
  void dispose() {
    CartManager.instance.cartItems.removeListener(_cartListener);
    WishlistManager.instance.favoriteIds.removeListener(_favListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int totalCartCount = CartManager.instance.totalCartCount;

    final filteredProducts = widget.products.where((p) {
      final name = p['title'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.screenColor,
      body: CommonBackground(
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // Scrollable Product List Grid
              Positioned.fill(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.w(20),
                    vertical: Responsive.h(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: Responsive.h(60)),

                      // Search bar
                      Container(
                        height: Responsive.h(48),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(Responsive.w(14)),
                          border: Border.all(
                            color: AppColors.outliner,
                            width: Responsive.w(1.2),
                          ),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.w(16),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                onChanged: (val) {
                                  setState(() {
                                    _searchQuery = val;
                                  });
                                },
                                decoration: const InputDecoration(
                                  hintText: 'Search item',
                                  hintStyle: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            const Icon(Icons.search, color: Colors.grey),
                          ],
                        ),
                      ),
                      SizedBox(height: Responsive.h(20)),

                      // Grid of Products
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: Responsive.w(12),
                          mainAxisSpacing: Responsive.h(12),
                          childAspectRatio: 0.72,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return _buildProductCard(product);
                        },
                      ),
                      SizedBox(height: Responsive.h(80)),
                    ],
                  ),
                ),
              ),

              // Custom Header Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: Responsive.h(60),
                  color: AppColors.screenColor.withValues(alpha: 0.95),
                  padding: EdgeInsets.symmetric(horizontal: Responsive.w(20)),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: Responsive.w(44),
                          height: Responsive.w(44),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.outliner,
                              width: Responsive.w(1.5),
                            ),
                          ),
                          child: Icon(
                            Icons.chevron_left,
                            color: AppColors.black,
                            size: Responsive.w(24),
                          ),
                        ),
                      ),
                      SizedBox(width: Responsive.w(12)),
                      CustomText.header(
                        widget.title,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ],
                  ),
                ),
              ),

              Positioned(
                bottom: Responsive.h(20),
                right: Responsive.w(20),
                child: CommonCartBadge(
                  itemCount: totalCartCount,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CartScreen(storeType: widget.storeType),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final String id = product['id'];
    final int qty = CartManager.instance.getQuantity(id);
    final int stock = CartManager.instance.getStock(product);
    final bool isOutOfStock = stock <= 0;
    final bool isMaxStock = qty >= stock;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Responsive.w(20)),
        border: Border.all(color: AppColors.outliner, width: Responsive.w(1.2)),
      ),
      padding: EdgeInsets.all(Responsive.w(10)),
      child: Stack(
        children: [
          // Heart icon + Badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (product['stockBadge'] != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.w(6),
                        vertical: Responsive.h(3),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(Responsive.w(6)),
                      ),
                      child: CustomText.title(
                        product['stockBadge'],
                        color: const Color(0xFF4CAF50),
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else
                    const Spacer(),
                  CommonWishlistButton(product: product),
                ],
              ),
              const Spacer(),
            ],
          ),

          // Main details
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailsScreen(
                        product: product,
                        storeType: widget.storeType,
                      ),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: Responsive.h(12)),
                    Center(
                      child: Image.asset(product['image'], height: Responsive.h(90), fit: BoxFit.contain),
                    ),
                    SizedBox(height: Responsive.h(8)),
                    CustomText.title(product['title'], fontSize: 12, fontWeight: FontWeight.bold, maxLines: 1),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.arrow_downward, color: Color(0xFF4CAF50), size: 10),
                  const Text('68% ', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 10, fontWeight: FontWeight.bold)),
                  Text('₹307 ', style: TextStyle(fontSize: 10, decoration: TextDecoration.lineThrough, color: Colors.grey)),
                  const Text('₹99', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: Responsive.h(8)),

              // Cart actions
              if (isOutOfStock)
                Container(
                  height: Responsive.h(28),
                  padding: EdgeInsets.symmetric(horizontal: Responsive.w(8)),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(Responsive.w(14)),
                  ),
                  child: Center(
                    child: Text(
                      'Out of Stock',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              else if (qty > 0)
                Container(
                  height: Responsive.h(32),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(Responsive.w(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          CartManager.instance.updateQuantity(product, qty - 1, context: context);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.w(8),
                          ),
                          child: const Icon(
                            Icons.remove,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                      Text(
                        qty.toString().padLeft(2, '0'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          CartManager.instance.updateQuantity(product, qty + 1, context: context);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.w(8),
                          ),
                          child: Icon(
                            Icons.add,
                            color: isMaxStock ? Colors.white.withValues(alpha: 0.4) : Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      CartManager.instance.addToCart(product, qty: 1, context: context);
                    },
                    child: Container(
                      width: Responsive.w(28),
                      height: Responsive.w(28),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.primary,
                        size: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
