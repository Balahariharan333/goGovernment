import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/responsive_helper.dart';
import '../../../widget/common_background.dart';
import '../../../widget/custom_text.dart';
import '../../../widget/common_map.dart';
import '../../../widget/common_cart_badge.dart';
import '../../../constants/route_constants.dart';
import '../../../service/cart_manager.dart';
import '../../../service/location_service.dart';

class NearStoresScreen extends StatefulWidget {
  const NearStoresScreen({super.key});

  @override
  State<NearStoresScreen> createState() => _NearStoresScreenState();
}

class _NearStoresScreenState extends State<NearStoresScreen> {
  late final VoidCallback _cartListener;
  LatLng? _userPos;

  late List<Map<String, dynamic>> _stores;

  @override
  void initState() {
    super.initState();
    _initStores();
    _cartListener = () {
      if (mounted) setState(() {});
    };
    CartManager.instance.cartItems.addListener(_cartListener);
    _detectLocation();
  }

  void _initStores() {
    _stores = [
      {
        'id': '1',
        'title': 'Sanjivani Medicals',
        'address':
            '552, 2nd Floor 16th Main, 15th Cross Rd, 4th Sector, HSR Layout, Bengaluru, Karnataka 560102',
        'image': 'assets/images/medical.png',
        'type': 'medical',
        'lat': 12.9116,
        'lng': 77.6433,
        'distance': '1.2 km',
      },
      {
        'id': '2',
        'title': 'Bangalore Horticulture',
        'address':
            'No.12, 100 Feet Rd, near Doordarshan Kendra, Indiranagar, Bengaluru, Karnataka 560038',
        'image': 'assets/images/vegstore.png',
        'type': 'vegstore',
        'lat': 12.9719,
        'lng': 77.6412,
        'distance': '2.4 km',
      },
      {
        'id': '3',
        'title': 'Apothecary Pharmacy',
        'address':
            'Shop 4, ground floor, 5th Block, Koramangala, Bengaluru, Karnataka 560095',
        'image': 'assets/images/medical.png',
        'type': 'medical',
        'lat': 12.9352,
        'lng': 77.6245,
        'distance': '3.1 km',
      },
      {
        'id': '4',
        'title': 'Organic Veggie Store',
        'address':
            '45, 9th Main Rd, opposite Shalini Ground, 5th Block, Jayanagar, Bengaluru, Karnataka 560041',
        'image': 'assets/images/vegstore.png',
        'type': 'vegstore',
        'lat': 12.9250,
        'lng': 77.5838,
        'distance': '4.5 km',
      },
    ];
  }

  Future<void> _detectLocation() async {
    final Position? pos = await LocationService.getCurrentPosition(requestPermission: false);
    if (pos != null && mounted) {
      setState(() {
        _userPos = LatLng(pos.latitude, pos.longitude);
        for (var store in _stores) {
          final dist = LocationService.calculateDistance(
            pos.latitude,
            pos.longitude,
            store['lat'] as double,
            store['lng'] as double,
          );
          store['distance'] = LocationService.formatDistance(dist);
        }
      });
    }
  }

  @override
  void dispose() {
    CartManager.instance.cartItems.removeListener(_cartListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenColor,
      body: CommonBackground(
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // 1. Map Canvas
              Positioned.fill(
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: Responsive.h(280),
                      child: CommonMap(
                        mapState: MapState.list,
                        isWalkMode: false,
                        center: _userPos,
                        markers: _stores.map((store) {
                          final isMedical = store['type'] == 'medical';
                          return Marker(
                            point: LatLng(store['lat'] as double, store['lng'] as double),
                            width: 38,
                            height: 38,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).pushNamed(
                                  RouteConstants.storeDetails,
                                  arguments: {
                                    'storeId': store['id'],
                                    'storeName': store['title'],
                                    'storeAddress': store['address'],
                                    'storeImage': store['image'],
                                    'storeType': store['type'],
                                  },
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isMedical ? const Color(0xFFE53935) : const Color(0xFF4CAF50),
                                    width: 2,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                                  ],
                                ),
                                child: Icon(
                                  isMedical ? Icons.local_pharmacy : Icons.eco,
                                  color: isMedical ? const Color(0xFFE53935) : const Color(0xFF4CAF50),
                                  size: 18,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              // 2. Back Button Overlay
              Positioned(
                top: Responsive.h(10),
                left: Responsive.w(20),
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
                      'Near Stores',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ],
                ),
              ),

              // 3. Scrollable List of Stores
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                top: Responsive.h(290),
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.w(20),
                    vertical: Responsive.h(12),
                  ),
                  itemCount: _stores.length,
                  itemBuilder: (context, index) {
                    final store = _stores[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: Responsive.h(16)),
                      child: _buildStoreCard(store),
                    );
                  },
                ),
              ),

              Positioned(
                bottom: Responsive.h(20),
                right: Responsive.w(20),
                child: CommonCartBadge(
                  itemCount: CartManager.instance.totalCartCount,
                  onTap: () {
                    String storeType = 'vegstore';
                    if (CartManager.instance.cartItems.value.isNotEmpty) {
                      final firstId =
                          CartManager.instance.cartItems.value.keys.first;
                      if (firstId.startsWith('m')) {
                        storeType = 'medical';
                      }
                    }
                    Navigator.of(context).pushNamed(
                      RouteConstants.cart,
                      arguments: storeType,
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

  Widget _buildStoreCard(Map<String, dynamic> store) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          RouteConstants.storeDetails,
          arguments: {
            'storeId': store['id'],
            'storeName': store['title'],
            'storeAddress': store['address'],
            'storeImage': store['image'],
            'storeType': store['type'],
          },
        );
      },
      child: Container(
        padding: EdgeInsets.all(Responsive.w(16)),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(Responsive.w(20)),
          border: Border.all(
            color: AppColors.outliner,
            width: Responsive.w(1.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store Title & Distance Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CustomText.title(
                    store['title'],
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (store['distance'] != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.w(8),
                      vertical: Responsive.h(2),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(Responsive.w(10)),
                    ),
                    child: Text(
                      store['distance'],
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: Responsive.h(4)),

            // Address Subtitle
            CustomText.subtitle(
              store['address'],
              fontSize: 11,
              color: AppColors.grayFont,
              maxLines: 2,
            ),
            SizedBox(height: Responsive.h(12)),

            // Storefront Banner image with floating action cart bag button
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(Responsive.w(12)),
                  child: Image.asset(
                    store['image'],
                    width: double.infinity,
                    height: Responsive.h(120),
                    fit: BoxFit.cover,
                  ),
                ),
                if (store['hasCart'] == true)
                  Positioned(
                    right: Responsive.w(12),
                    bottom: -Responsive.h(10),
                    child: Container(
                      width: Responsive.w(36),
                      height: Responsive.w(36),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(Responsive.w(12)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        border: Border.all(
                          color: AppColors.primary,
                          width: Responsive.w(1.2),
                        ),
                      ),
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        color: AppColors.primary,
                        size: Responsive.w(18),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
