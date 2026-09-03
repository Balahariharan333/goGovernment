import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/responsive_helper.dart';
import '../../../widget/common_background.dart';
import '../../../widget/custom_text.dart';
import '../../../widget/common_cart_badge.dart';
import '../../../constants/route_constants.dart';
import '../../../service/cart_manager.dart';
import '../../../widget/common_wishlist_button.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final String storeType; // 'medical' or 'vegstore'

  const ProductDetailsScreen({
    super.key,
    required this.product,
    required this.storeType,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  bool _isHighlightsExpanded = false; // Start collapsed
  bool _isAllDetailsExpanded = false; // Start collapsed
  bool _isSpecsMoreExpanded = false; // Sub-section specs toggle
  String _selectedTab = 'Specs'; // 'Specs' or 'Mfg'

  late final VoidCallback _cartListener;
  late final VoidCallback _favListener;

  int get _quantity => CartManager.instance.getQuantity(widget.product['id']);
  int get _cartCount => CartManager.instance.totalCartCount;

  // Similar products mock list
  late final List<Map<String, dynamic>> _similarProducts;

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

    // Register product details
    CartManager.instance.productDetails[widget.product['id']] = widget.product;

    if (widget.storeType == 'medical') {
      _similarProducts = [
        {'id': 'sm1', 'title': 'Watermelon striped', 'image': 'assets/images/product1.png', 'isFav': false, 'qty': 0},
        {'id': 'sm2', 'title': 'Watermelon striped', 'image': 'assets/images/product1.png', 'isFav': true, 'qty': 1},
        {'id': 'sm3', 'title': 'Watermelon striped', 'image': 'assets/images/product1.png', 'isFav': false, 'qty': 0},
      ];
    } else {
      _similarProducts = [
        {'id': 'sv1', 'title': 'Watermelon striped', 'image': 'assets/images/product2.png', 'isFav': false, 'qty': 0},
        {'id': 'sv2', 'title': 'Watermelon striped', 'image': 'assets/images/product3.png', 'isFav': true, 'qty': 1},
        {'id': 'sv3', 'title': 'Watermelon striped', 'image': 'assets/images/product2.png', 'isFav': false, 'qty': 0},
      ];
    }
  }

  @override
  void dispose() {
    CartManager.instance.cartItems.removeListener(_cartListener);
    WishlistManager.instance.favoriteIds.removeListener(_favListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int stock = CartManager.instance.getStock(widget.product);

    return Scaffold(
      backgroundColor: AppColors.screenColor,
      body: CommonBackground(
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // 1. Scrollable Product Details list
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
                      // Space for custom appBar
                      SizedBox(height: Responsive.h(60)),

                      // Delivery Estimate Row
                      Row(
                        children: [
                          Icon(
                            Icons.bolt,
                            color: const Color(0xFF4CAF50),
                            size: Responsive.w(18),
                          ),
                          SizedBox(width: Responsive.w(4)),
                          CustomText.title(
                            '25-30 mins',
                            color: const Color(0xFF4CAF50),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ],
                      ),
                      SizedBox(height: Responsive.h(12)),

                      // Centered Product Hero Image
                      Center(
                        child: Image.asset(
                          widget.product['image'],
                          height: Responsive.h(220),
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: Responsive.h(12)),

                      // Carousel Indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          return Container(
                            width: Responsive.w(6),
                            height: Responsive.w(6),
                            margin: EdgeInsets.symmetric(horizontal: Responsive.w(3)),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: index == 0 ? AppColors.primary : Colors.grey.shade300,
                            ),
                          );
                        }),
                      ),
                      SizedBox(height: Responsive.h(20)),

                      // Add to Cart Button (white button with orange border or quantity dial)
                      _buildCartActionButton(),
                      SizedBox(height: Responsive.h(20)),

                      // Stock alert if low
                      if (stock <= 3) ...[
                        Container(
                          margin: EdgeInsets.only(bottom: Responsive.h(8)),
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.w(8),
                            vertical: Responsive.h(4),
                          ),
                          decoration: BoxDecoration(
                            color: stock <= 0
                                ? const Color(0xFFFFEBEE)
                                : const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(Responsive.w(6)),
                            border: Border.all(
                              color: stock <= 0
                                  ? const Color(0xFFFFCDD2)
                                  : Colors.orange.shade300,
                            ),
                          ),
                          child: Text(
                            stock <= 0
                                ? 'Out of stock'
                                : 'Hurry, only $stock left in stock!',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: stock <= 0
                                  ? Colors.red.shade700
                                  : Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],

                      // Product Title
                      CustomText.header(
                        '${widget.product['title']} ( 1 Units)',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      SizedBox(height: Responsive.h(8)),

                      // Pricing Details Row
                      Row(
                        children: [
                          CustomText.title(
                            '68% OFF  ',
                            color: const Color(0xFF4CAF50),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          Text(
                            '₹307 ',
                            style: TextStyle(
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          SizedBox(width: Responsive.w(4)),
                          CustomText.header(
                            '₹99',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ],
                      ),
                      SizedBox(height: Responsive.h(12)),

                      // Quantity Pill & Cart Badge Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText.subtitle(
                                'Selected Quantity: 1 Units',
                                fontSize: 11,
                                color: AppColors.grayFont,
                              ),
                              SizedBox(height: Responsive.h(8)),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade900,
                                  borderRadius: BorderRadius.circular(Responsive.w(12)),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: Responsive.w(16),
                                  vertical: Responsive.h(8),
                                ),
                                child: CustomText.title(
                                  '1 Units',
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: Responsive.h(4)),
                              CustomText.title(
                                '3 left',
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ],
                          ),

                          // Common Cart Badge on the right
                          CommonCartBadge(
                            itemCount: _cartCount,
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                RouteConstants.cart,
                                arguments: widget.storeType,
                              );
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: Responsive.h(20)),

                      // Dropdown Panel 1: Product Highlights
                      _buildHighlightsAccordion(),
                      const Divider(),

                      // Dropdown Panel 2: All Details
                      _buildAllDetailsAccordion(),
                      const Divider(),
                      SizedBox(height: Responsive.h(16)),

                      // Section similar products
                      _buildCrossSellSection('Similar products'),
                      SizedBox(height: Responsive.h(24)),

                      // Section you may also like
                      _buildCrossSellSection('You May Also Like..'),
                      SizedBox(height: Responsive.h(24)),

                      // Bottom Trust/Value Badges
                      _buildTrustBadgesRow(),
                      SizedBox(height: Responsive.h(60)),
                    ],
                  ),
                ),
              ),

              // 2. Custom App Bar overlay
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: Responsive.h(60),
                  color: AppColors.screenColor.withValues(alpha: 0.95),
                  padding: EdgeInsets.symmetric(horizontal: Responsive.w(20)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
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
                            'Near Stores',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          CommonWishlistButton(
                            product: widget.product,
                            isCircleStyle: true,
                          ),
                          SizedBox(width: Responsive.w(8)),
                          Container(
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
                              Icons.share_outlined,
                              color: AppColors.black,
                              size: Responsive.w(20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartActionButton() {
    final int qty = _quantity;
    final int stock = CartManager.instance.getStock(widget.product);
    final bool isOutOfStock = stock <= 0;
    final bool isMaxStock = qty >= stock;

    if (isOutOfStock) {
      return Container(
        width: double.infinity,
        height: Responsive.h(48),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(Responsive.w(24)),
          border: Border.all(
            color: Colors.grey.shade400,
            width: Responsive.w(1.5),
          ),
        ),
        child: Center(
          child: CustomText.title(
            'Out of Stock',
            color: Colors.grey.shade600,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (qty > 0) {
      return Container(
        height: Responsive.h(48),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(Responsive.w(24)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.remove, color: Colors.white),
              onPressed: () {
                CartManager.instance.updateQuantity(widget.product, qty - 1, context: context);
              },
            ),
            CustomText.title(
              qty.toString().padLeft(2, '0'),
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            IconButton(
              icon: Icon(
                Icons.add,
                color: isMaxStock ? Colors.white.withValues(alpha: 0.4) : Colors.white,
              ),
              onPressed: () {
                CartManager.instance.updateQuantity(widget.product, qty + 1, context: context);
              },
            ),
          ],
        ),
      );
    } else {
      return GestureDetector(
        onTap: () {
          CartManager.instance.addToCart(widget.product, qty: 1, context: context);
        },
        child: Container(
          width: double.infinity,
          height: Responsive.h(48),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(Responsive.w(24)),
            border: Border.all(
              color: AppColors.primary,
              width: Responsive.w(1.5),
            ),
          ),
          child: Center(
            child: CustomText.title(
              'Add',
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildHighlightsAccordion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isHighlightsExpanded = !_isHighlightsExpanded;
            });
          },
          child: Container(
            color: Colors.transparent,
            padding: EdgeInsets.symmetric(vertical: Responsive.h(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText.title('Product Highlights', fontSize: 14, fontWeight: FontWeight.bold),
                    SizedBox(height: Responsive.h(2)),
                    CustomText.subtitle('Key features, expiry, usage and more', fontSize: 11, color: Colors.grey),
                  ],
                ),
                Icon(
                  _isHighlightsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
        if (_isHighlightsExpanded)
          Padding(
            padding: EdgeInsets.only(top: Responsive.h(8), bottom: Responsive.h(12)),
            child: Container(
              padding: EdgeInsets.all(Responsive.w(16)),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(Responsive.w(16)),
              ),
              child: Column(
                children: [
                  _buildSpecRow('Pack of', '1', 'Brand', 'Unbranded'),
                  const Divider(),
                  _buildSpecRow('Type', widget.storeType == 'medical' ? 'Medicine' : 'Watermelon', 'Quantity', '1 Units'),
                  const Divider(),
                  _buildSpecRow('Shelf Life', '7 Days', 'Form Factor', 'Whole'),
                  const Divider(),
                  _buildSpecRow('Organic', 'No', 'Origin', 'India'),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSpecRow(String key1, String val1, String key2, String val2) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText.subtitle(key1, fontSize: 10, color: Colors.grey),
              SizedBox(height: Responsive.h(2)),
              CustomText.title(val1, fontSize: 12, fontWeight: FontWeight.bold),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText.subtitle(key2, fontSize: 10, color: Colors.grey),
              SizedBox(height: Responsive.h(2)),
              CustomText.title(val2, fontSize: 12, fontWeight: FontWeight.bold),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAllDetailsAccordion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isAllDetailsExpanded = !_isAllDetailsExpanded;
            });
          },
          child: Container(
            color: Colors.transparent,
            padding: EdgeInsets.symmetric(vertical: Responsive.h(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText.title('All details', fontSize: 14, fontWeight: FontWeight.bold),
                    SizedBox(height: Responsive.h(2)),
                    CustomText.subtitle('Features, description and more', fontSize: 11, color: Colors.grey),
                  ],
                ),
                Icon(
                  _isAllDetailsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
        if (_isAllDetailsExpanded)
          Padding(
            padding: EdgeInsets.only(top: Responsive.h(8), bottom: Responsive.h(12)),
            child: Column(
              children: [
                // Tabs
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTab = 'Specs';
                          });
                        },
                        child: Container(
                          height: Responsive.h(38),
                          decoration: BoxDecoration(
                            color: _selectedTab == 'Specs' ? const Color(0xFF4CAF50) : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(Responsive.w(8)),
                          ),
                          child: Center(
                            child: CustomText.title(
                              'Specifications',
                              color: _selectedTab == 'Specs' ? Colors.white : Colors.grey.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: Responsive.w(12)),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTab = 'Mfg';
                          });
                        },
                        child: Container(
                          height: Responsive.h(38),
                          decoration: BoxDecoration(
                            color: _selectedTab == 'Mfg' ? const Color(0xFF4CAF50) : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(Responsive.w(8)),
                          ),
                          child: Center(
                            child: CustomText.title(
                              'Manufacturer info',
                              color: _selectedTab == 'Mfg' ? Colors.white : Colors.grey.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.h(16)),

                // Tab Content
                Container(
                  padding: EdgeInsets.all(Responsive.w(16)),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(Responsive.w(16)),
                  ),
                  width: double.infinity,
                  child: _selectedTab == 'Specs'
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText.subtitle('Generic name', fontSize: 10, color: Colors.grey),
                            SizedBox(height: Responsive.h(2)),
                            CustomText.title(widget.storeType == 'medical' ? 'Medicine' : 'Fruit', fontSize: 12, fontWeight: FontWeight.bold),
                            const Divider(),
                            CustomText.subtitle('Country of origin', fontSize: 10, color: Colors.grey),
                            SizedBox(height: Responsive.h(2)),
                            CustomText.title('India', fontSize: 12, fontWeight: FontWeight.bold),
                            if (_isSpecsMoreExpanded) ...[
                              const Divider(),
                              CustomText.subtitle('Net Quantity', fontSize: 10, color: Colors.grey),
                              SizedBox(height: Responsive.h(2)),
                              CustomText.title('1 Unit / Standard Pack', fontSize: 12, fontWeight: FontWeight.bold),
                              const Divider(),
                              CustomText.subtitle('Storage Instructions', fontSize: 10, color: Colors.grey),
                              SizedBox(height: Responsive.h(2)),
                              CustomText.title('Store in a cool, ventilated place away from direct sunlight', fontSize: 11, fontWeight: FontWeight.bold),
                              const Divider(),
                              CustomText.subtitle('Customer Care', fontSize: 10, color: Colors.grey),
                              SizedBox(height: Responsive.h(2)),
                              CustomText.title('support@gogovernment.in | 1800-425-0000', fontSize: 11, fontWeight: FontWeight.bold),
                            ],
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText.subtitle('Name and address of the Manufacturer', fontSize: 10, color: Colors.grey),
                            SizedBox(height: Responsive.h(2)),
                            CustomText.title(
                              '552, 2nd Floor 16th Main, 15th Cross Rd, 4th Sector, HSR Layout, Bengaluru, Karnataka 560102',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            const Divider(),
                            CustomText.subtitle('Name and address of the Packer', fontSize: 10, color: Colors.grey),
                            SizedBox(height: Responsive.h(2)),
                            CustomText.title(
                              '552, 2nd Floor 16th Main, 15th Cross Rd, 4th Sector, HSR Layout, Bengaluru, Karnataka 560102',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            if (_isSpecsMoreExpanded) ...[
                              const Divider(),
                              CustomText.subtitle('Marketed By', fontSize: 10, color: Colors.grey),
                              SizedBox(height: Responsive.h(2)),
                              CustomText.title('Karnataka State Agro & Civic Supplies Ltd.', fontSize: 11, fontWeight: FontWeight.bold),
                              const Divider(),
                              CustomText.subtitle('License & Compliance', fontSize: 10, color: Colors.grey),
                              SizedBox(height: Responsive.h(2)),
                              CustomText.title('Govt Certified Quality Assured · FSSAI / Drug Lic. #9823412', fontSize: 11, fontWeight: FontWeight.bold),
                            ],
                          ],
                        ),
                ),
                SizedBox(height: Responsive.h(12)),

                // See more button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSpecsMoreExpanded = !_isSpecsMoreExpanded;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: Responsive.w(16), vertical: Responsive.h(8)),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(Responsive.w(16)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomText.title(_isSpecsMoreExpanded ? 'See less' : 'See more', fontSize: 12, color: Colors.grey.shade700),
                        Icon(
                          _isSpecsMoreExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          size: 16,
                          color: Colors.grey.shade700,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCrossSellSection(String heading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText.header(heading, fontSize: 15, fontWeight: FontWeight.bold),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed(
                  RouteConstants.allProducts,
                  arguments: {
                    'title': heading,
                    'products': _similarProducts,
                    'storeType': widget.storeType,
                  },
                );
              },
              child: CustomText.title('View All', color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SizedBox(height: Responsive.h(12)),
        SizedBox(
          height: Responsive.h(200),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _similarProducts.length,
            itemBuilder: (context, index) {
              final prod = _similarProducts[index];
              return Padding(
                padding: EdgeInsets.only(right: Responsive.w(12)),
                child: _buildCrossSellCard(prod, index),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCrossSellCard(Map<String, dynamic> prod, int index) {
    final String id = prod['id'];
    final int qty = CartManager.instance.getQuantity(id);

    return Container(
      width: Responsive.w(140),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Responsive.w(16)),
        border: Border.all(color: AppColors.outliner, width: 1.2),
      ),
      padding: EdgeInsets.all(Responsive.w(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heart icon + Image
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (index == 1)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: Responsive.w(4), vertical: Responsive.h(2)),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(Responsive.w(4)),
                  ),
                  child: const Text('Only 3 left', style: TextStyle(color: Colors.green, fontSize: 7, fontWeight: FontWeight.bold)),
                )
              else
                const Spacer(),
              CommonWishlistButton(
                product: prod,
                size: 16,
              ),
            ],
          ),
          SizedBox(height: Responsive.h(4)),
          Center(
            child: Image.asset(prod['image'], height: Responsive.h(60), fit: BoxFit.contain),
          ),
          const Spacer(),
          CustomText.title(prod['title'], fontSize: 11, maxLines: 1),
          SizedBox(height: Responsive.h(2)),
          Row(
            children: [
              const Icon(Icons.arrow_downward, color: Colors.green, size: 8),
              const Text('68% ', style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold)),
              Text('₹307 ', style: TextStyle(color: Colors.grey.shade400, fontSize: 8, decoration: TextDecoration.lineThrough)),
              const Text('₹99', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: Responsive.h(6)),

          // Qty selector
          if (qty > 0)
            Container(
              height: Responsive.h(28),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(Responsive.w(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.remove, color: Colors.white, size: 12),
                    onPressed: () {
                      CartManager.instance.updateQuantity(prod, qty - 1);
                    },
                  ),
                  Text(qty.toString().padLeft(2, '0'), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.add, color: Colors.white, size: 12),
                    onPressed: () {
                      CartManager.instance.updateQuantity(prod, qty + 1);
                    },
                  ),
                ],
              ),
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  CartManager.instance.updateQuantity(prod, 1);
                },
                child: Container(
                  width: Responsive.w(24),
                  height: Responsive.w(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 1.2),
                  ),
                  child: const Icon(Icons.add, color: AppColors.primary, size: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrustBadgesRow() {
    return SizedBox(
      height: Responsive.h(70),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildTrustBadgeCard(Icons.cancel_presentation_outlined, 'Doorstep\nCancellation'),
          _buildTrustBadgeCard(Icons.assignment_return_outlined, '7-Day\nReturn'),
          _buildTrustBadgeCard(Icons.local_shipping_outlined, 'Cash on\nDelivery'),
          _buildTrustBadgeCard(Icons.verified_outlined, 'GOV\nAssured'),
        ],
      ),
    );
  }

  Widget _buildTrustBadgeCard(IconData icon, String label) {
    return Padding(
      padding: EdgeInsets.only(right: Responsive.w(10)),
      child: Container(
        width: Responsive.w(86),
        padding: EdgeInsets.all(Responsive.w(8)),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(Responsive.w(12)),
          border: Border.all(color: AppColors.outliner, width: 1.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: Responsive.w(18)),
            SizedBox(height: Responsive.h(4)),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
