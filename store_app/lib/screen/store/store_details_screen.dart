import 'package:flutter/material.dart';
import '../../model/store_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widget/common_background.dart';
import '../../widget/custom_text.dart';

class StoreDetailsScreen extends StatelessWidget {
  final StoreModel store;

  const StoreDetailsScreen({
    super.key,
    required this.store,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF16A34A);
      case 'rejected':
        return const Color(0xFFDC2626);
      case 'pending':
      default:
        return const Color(0xFFD97706);
    }
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final statusColor = _getStatusColor(store.status);

    return Scaffold(
      backgroundColor: AppColors.screenColor,
      appBar: AppBar(
        backgroundColor: AppColors.screenColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: CustomText.title('Store Profile & Details', fontSize: 16, color: AppColors.black),
        centerTitle: true,
      ),
      body: CommonBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: Responsive.w(20), vertical: Responsive.h(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Store Identity Card
                Container(
                  padding: EdgeInsets.all(Responsive.w(18)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(Responsive.w(20)),
                    border: Border.all(color: AppColors.outliner.withValues(alpha: 0.6)),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: Responsive.w(56),
                            height: Responsive.w(56),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(Responsive.w(16)),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                            ),
                            child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 30),
                          ),
                          SizedBox(width: Responsive.w(14)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText.header(store.name, fontSize: 17, color: AppColors.black),
                                SizedBox(height: Responsive.h(4)),
                                CustomText.body(
                                  'ID: ${store.storeId}',
                                  fontSize: 12,
                                  color: AppColors.grayFont,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: Responsive.h(14)),
                      const Divider(height: 1),
                      SizedBox(height: Responsive.h(12)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildBadge(
                            label: store.category.toUpperCase(),
                            icon: Icons.category_outlined,
                            color: AppColors.primary,
                          ),
                          _buildBadge(
                            label: store.status.toUpperCase(),
                            icon: store.status == 'approved'
                                ? Icons.verified_rounded
                                : (store.status == 'rejected' ? Icons.cancel_outlined : Icons.hourglass_top_rounded),
                            color: statusColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: Responsive.h(18)),

                // Contact & Owner Section
                _buildSectionHeader('Owner & Contact Information'),
                _buildInfoCard([
                  _buildInfoRow(Icons.person_outline_rounded, 'Owner Name', store.ownerName),
                  _buildInfoRow(Icons.phone_outlined, 'Registered Phone', store.phone),
                  if (store.email.isNotEmpty)
                    _buildInfoRow(Icons.email_outlined, 'Email Address', store.email),
                ]),

                SizedBox(height: Responsive.h(18)),

                // Store Location & Address Section
                _buildSectionHeader('Physical Location & Address'),
                _buildInfoCard([
                  _buildInfoRow(Icons.location_on_outlined, 'Store Address', store.address),
                  if (store.pincode.isNotEmpty)
                    _buildInfoRow(Icons.pin_drop_outlined, 'Pincode', store.pincode),
                  _buildInfoRow(
                    Icons.explore_outlined,
                    'Coordinates',
                    'Lat: ${store.lat.toStringAsFixed(4)}, Lng: ${store.lng.toStringAsFixed(4)}',
                  ),
                ]),

                SizedBox(height: Responsive.h(18)),

                // Operating Hours
                _buildSectionHeader('Operating Hours'),
                _buildInfoCard([
                  _buildInfoRow(
                    Icons.access_time_rounded,
                    'Business Timings',
                    '${store.timings['open'] ?? '08:00 AM'} - ${store.timings['close'] ?? '08:30 PM'}',
                  ),
                  _buildInfoRow(
                    Icons.wifi_tethering_rounded,
                    'Live Citizen App Visibility',
                    store.isOnline ? 'Online (Accepting Orders)' : 'Offline (Hidden)',
                    valueColor: store.isOnline ? const Color(0xFF16A34A) : Colors.grey,
                  ),
                ]),

                SizedBox(height: Responsive.h(18)),

                // Licensing & Compliance
                _buildSectionHeader('Government License & Compliance'),
                _buildInfoCard([
                  _buildInfoRow(
                    Icons.badge_outlined,
                    'Trade / Municipal License No.',
                    store.storeId.isNotEmpty ? (store.storeId) : 'Verified on File',
                  ),
                  _buildInfoRow(
                    Icons.verified_user_outlined,
                    'Verification Status',
                    store.status == 'approved' ? 'Officially Certified by Municipal Corp' : 'Under Review',
                    valueColor: statusColor,
                  ),
                ]),

                SizedBox(height: Responsive.h(18)),

                // Bank & Settlement Account Details
                _buildSectionHeader('Subsidy Settlement Bank Account'),
                _buildInfoCard([
                  _buildInfoRow(
                    Icons.account_balance_outlined,
                    'Bank Name',
                    store.bankDetails.bankName.isNotEmpty ? store.bankDetails.bankName : 'Configured',
                  ),
                  _buildInfoRow(
                    Icons.credit_card_outlined,
                    'Account Number',
                    store.bankDetails.accountNumber.isNotEmpty
                        ? '•••• •••• ${store.bankDetails.accountNumber.length > 4 ? store.bankDetails.accountNumber.substring(store.bankDetails.accountNumber.length - 4) : store.bankDetails.accountNumber}'
                        : 'On Record',
                  ),
                  _buildInfoRow(
                    Icons.domain_verification_outlined,
                    'IFSC Code',
                    store.bankDetails.ifscCode.isNotEmpty ? store.bankDetails.ifscCode : 'On Record',
                  ),
                  if (store.bankDetails.accountHolderName.isNotEmpty)
                    _buildInfoRow(
                      Icons.person_pin_outlined,
                      'Account Holder',
                      store.bankDetails.accountHolderName,
                    ),
                ]),

                SizedBox(height: Responsive.h(30)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: Responsive.w(4), bottom: Responsive.h(8)),
      child: CustomText.title(title, fontSize: 13, color: AppColors.black),
    );
  }

  Widget _buildBadge({required String label, required IconData icon, required Color color}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Responsive.w(10), vertical: Responsive.h(5)),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Responsive.w(10)),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: Responsive.w(6)),
          CustomText.title(label, fontSize: 11, color: color),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> rows) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: Responsive.w(16), vertical: Responsive.h(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Responsive.w(16)),
        border: Border.all(color: AppColors.outliner.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1)
              Padding(
                padding: EdgeInsets.symmetric(vertical: Responsive.h(10)),
                child: const Divider(height: 1, color: Color(0xFFF1F5F9)),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.grayFont),
        SizedBox(width: Responsive.w(12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText.body(label, fontSize: 11, color: AppColors.grayFont),
              SizedBox(height: Responsive.h(2)),
              CustomText.title(
                value,
                fontSize: 13,
                color: valueColor ?? AppColors.black,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
