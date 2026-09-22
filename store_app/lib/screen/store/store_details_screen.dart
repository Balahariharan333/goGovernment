import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/store/store_bloc.dart';
import '../../bloc/store/store_event.dart';
import '../../bloc/store/store_state.dart';
import '../../model/store_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widget/common_background.dart';
import '../../widget/custom_text.dart';

class StoreDetailsScreen extends StatefulWidget {
  final StoreModel store;

  const StoreDetailsScreen({
    super.key,
    required this.store,
  });

  @override
  State<StoreDetailsScreen> createState() => _StoreDetailsScreenState();
}

class _StoreDetailsScreenState extends State<StoreDetailsScreen> {
  late StoreModel _store;

  @override
  void initState() {
    super.initState();
    _store = widget.store;
  }

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

  void _showEditProfileModal(BuildContext context, StoreModel currentStore) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: currentStore.name);
    final ownerCtrl = TextEditingController(text: currentStore.ownerName);
    final phoneCtrl = TextEditingController(text: currentStore.phone);
    final emailCtrl = TextEditingController(text: currentStore.email);
    final addressCtrl = TextEditingController(text: currentStore.address);
    final pincodeCtrl = TextEditingController(text: currentStore.pincode);
    final openCtrl = TextEditingController(text: currentStore.timings['open'] ?? '08:00 AM');
    final closeCtrl = TextEditingController(text: currentStore.timings['close'] ?? '08:30 PM');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: Responsive.w(20), vertical: Responsive.h(20)),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: Responsive.w(40),
                    height: Responsive.h(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: Responsive.h(16)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText.header('Edit Store Profile', fontSize: 17, color: AppColors.black),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.grayFont),
                      onPressed: () => Navigator.pop(bottomSheetContext),
                    ),
                  ],
                ),
                CustomText.body(
                  'Update store info and business hours seen by local citizens.',
                  fontSize: 12,
                  color: AppColors.grayFont,
                ),
                SizedBox(height: Responsive.h(18)),

                // Store Name
                _buildSheetInput(
                  controller: nameCtrl,
                  label: 'Store Name',
                  hint: 'e.g. Annapurna Fair Price Store #12',
                  icon: Icons.storefront_rounded,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Store name required' : null,
                ),
                SizedBox(height: Responsive.h(14)),

                // Owner Name
                _buildSheetInput(
                  controller: ownerCtrl,
                  label: 'Store Owner / Licensee Name',
                  hint: 'Full name as per trade license',
                  icon: Icons.person_outline_rounded,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Owner name required' : null,
                ),
                SizedBox(height: Responsive.h(14)),

                // Phone & Email in row
                Row(
                  children: [
                    Expanded(
                      child: _buildSheetInput(
                        controller: phoneCtrl,
                        label: 'Support Phone',
                        hint: '10-digit number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    SizedBox(width: Responsive.w(12)),
                    Expanded(
                      child: _buildSheetInput(
                        controller: emailCtrl,
                        label: 'Contact Email',
                        hint: 'owner@gmail.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.h(14)),

                // Address & Pincode
                _buildSheetInput(
                  controller: addressCtrl,
                  label: 'Store Physical Address',
                  hint: 'Ward number, Street, Landmark',
                  icon: Icons.location_on_outlined,
                  maxLines: 2,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Address required' : null,
                ),
                SizedBox(height: Responsive.h(14)),
                _buildSheetInput(
                  controller: pincodeCtrl,
                  label: 'Pincode',
                  hint: 'e.g. 600001',
                  icon: Icons.pin_drop_outlined,
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: Responsive.h(14)),

                // Business Timings
                CustomText.title('Operating Timings', fontSize: 13, color: AppColors.black),
                SizedBox(height: Responsive.h(6)),
                Row(
                  children: [
                    Expanded(
                      child: _buildSheetInput(
                        controller: openCtrl,
                        label: 'Opens At',
                        hint: '08:00 AM',
                        icon: Icons.access_time_rounded,
                      ),
                    ),
                    SizedBox(width: Responsive.w(12)),
                    Expanded(
                      child: _buildSheetInput(
                        controller: closeCtrl,
                        label: 'Closes At',
                        hint: '08:30 PM',
                        icon: Icons.access_time_filled_rounded,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.h(24)),

                // Save CTA Button
                SizedBox(
                  width: double.infinity,
                  height: Responsive.h(48),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      Navigator.pop(bottomSheetContext);

                      final updates = {
                        'name': nameCtrl.text.trim(),
                        'ownerName': ownerCtrl.text.trim(),
                        'phone': phoneCtrl.text.trim(),
                        'email': emailCtrl.text.trim(),
                        'address': addressCtrl.text.trim(),
                        'pincode': pincodeCtrl.text.trim(),
                        'timings': {
                          'open': openCtrl.text.trim(),
                          'close': closeCtrl.text.trim(),
                        },
                      };

                      context.read<StoreBloc>().add(
                            UpdateStoreProfileEvent(
                              storeId: currentStore.storeId,
                              updates: updates,
                            ),
                          );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Store profile updated successfully! 🎉'),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Save Profile Changes',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: Responsive.h(12)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSheetInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText.body(label, fontSize: 11, color: AppColors.grayFont),
        SizedBox(height: Responsive.h(4)),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(fontSize: 13, color: AppColors.black),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: EdgeInsets.symmetric(horizontal: Responsive.w(12), vertical: Responsive.h(10)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Responsive.w(12)),
              borderSide: BorderSide(color: AppColors.outliner.withValues(alpha: 0.6)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Responsive.w(12)),
              borderSide: BorderSide(color: AppColors.outliner.withValues(alpha: 0.6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Responsive.w(12)),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return BlocConsumer<StoreBloc, StoreState>(
      listener: (context, state) {
        if (state is StoreLoaded) {
          setState(() => _store = state.store);
        }
      },
      builder: (context, state) {
        if (state is StoreLoaded) {
          _store = state.store;
        }
        final statusColor = _getStatusColor(_store.status);

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
            actions: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.only(right: Responsive.w(12)),
                ),
                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                label: const Text(
                  'Edit',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                onPressed: () => _showEditProfileModal(context, _store),
              ),
            ],
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
                                    CustomText.header(_store.name, fontSize: 17, color: AppColors.black),
                                    SizedBox(height: Responsive.h(4)),
                                    CustomText.body(
                                      'ID: ${_store.storeId}',
                                      fontSize: 12,
                                      color: AppColors.grayFont,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                                tooltip: 'Edit Store Details',
                                onPressed: () => _showEditProfileModal(context, _store),
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
                                label: _store.category.toUpperCase(),
                                icon: Icons.category_outlined,
                                color: AppColors.primary,
                              ),
                              _buildBadge(
                                label: _store.status.toUpperCase(),
                                icon: _store.status == 'approved'
                                    ? Icons.verified_rounded
                                    : (_store.status == 'rejected' ? Icons.cancel_outlined : Icons.hourglass_top_rounded),
                                color: statusColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: Responsive.h(18)),

                    // Store Owner Information Section
                    _buildSectionHeader('Store Owner & Merchant Credentials'),
                    _buildInfoCard([
                      _buildInfoRow(
                        Icons.person_rounded,
                        'Owner / Licensee Name',
                        _store.ownerName.isNotEmpty ? _store.ownerName : 'Not Set',
                        trailingBadge: 'Authorized Merchant',
                      ),
                      _buildInfoRow(
                        Icons.phone_rounded,
                        'Support Phone',
                        _store.phone,
                      ),
                      if (_store.email.isNotEmpty)
                        _buildInfoRow(
                          Icons.email_rounded,
                          'Email Address',
                          _store.email,
                        ),
                      _buildInfoRow(
                        Icons.verified_user_rounded,
                        'PDS / Trade Authorization',
                        'Registered Merchant #${_store.storeId}',
                        valueColor: const Color(0xFF16A34A),
                      ),
                    ]),

                    SizedBox(height: Responsive.h(18)),

                    // Store Location & Address Section
                    _buildSectionHeader('Physical Location & Address'),
                    _buildInfoCard([
                      _buildInfoRow(Icons.location_on_outlined, 'Store Address', _store.address),
                      if (_store.pincode.isNotEmpty)
                        _buildInfoRow(Icons.pin_drop_outlined, 'Pincode', _store.pincode),
                      _buildInfoRow(
                        Icons.explore_outlined,
                        'Coordinates',
                        'Lat: ${_store.lat.toStringAsFixed(4)}, Lng: ${_store.lng.toStringAsFixed(4)}',
                      ),
                    ]),

                    SizedBox(height: Responsive.h(18)),

                    // Operating Hours & Online Visibility
                    _buildSectionHeader('Operating Hours & Citizen Visibility'),
                    _buildInfoCard([
                      _buildInfoRow(
                        Icons.access_time_rounded,
                        'Business Timings',
                        '${_store.timings['open'] ?? '08:00 AM'} - ${_store.timings['close'] ?? '08:30 PM'}',
                      ),
                      _buildInfoRow(
                        Icons.wifi_tethering_rounded,
                        'Live Citizen App Visibility',
                        _store.isOnline ? 'Online (Accepting Orders)' : 'Offline (Hidden)',
                        valueColor: _store.isOnline ? const Color(0xFF16A34A) : Colors.grey,
                      ),
                    ]),

                    SizedBox(height: Responsive.h(18)),

                    // Government License & Compliance
                    _buildSectionHeader('Government License & Compliance'),
                    _buildInfoCard([
                      _buildInfoRow(
                        Icons.badge_outlined,
                        'Trade / Municipal License No.',
                        _store.storeId.isNotEmpty ? (_store.storeId) : 'Verified on File',
                      ),
                      _buildInfoRow(
                        Icons.verified_user_outlined,
                        'Verification Status',
                        _store.status == 'approved' ? 'Officially Certified by Municipal Corp' : 'Under Review',
                        valueColor: statusColor,
                      ),
                    ]),

                    SizedBox(height: Responsive.h(18)),

                    // Bank & Settlement Account Details
                    _buildSectionHeader('Direct Subsidy Settlement Account'),
                    _buildInfoCard([
                      _buildInfoRow(
                        Icons.account_balance_outlined,
                        'Bank Name',
                        _store.bankDetails.bankName.isNotEmpty ? _store.bankDetails.bankName : 'Configured',
                      ),
                      _buildInfoRow(
                        Icons.credit_card_outlined,
                        'Account Number',
                        _store.bankDetails.accountNumber.isNotEmpty
                            ? '•••• •••• ${_store.bankDetails.accountNumber.length > 4 ? _store.bankDetails.accountNumber.substring(_store.bankDetails.accountNumber.length - 4) : _store.bankDetails.accountNumber}'
                            : 'On Record',
                      ),
                      _buildInfoRow(
                        Icons.domain_verification_outlined,
                        'IFSC Code',
                        _store.bankDetails.ifscCode.isNotEmpty ? _store.bankDetails.ifscCode : 'On Record',
                      ),
                      if (_store.bankDetails.accountHolderName.isNotEmpty)
                        _buildInfoRow(
                          Icons.person_pin_outlined,
                          'Account Holder',
                          _store.bankDetails.accountHolderName,
                        ),
                    ]),

                    SizedBox(height: Responsive.h(24)),

                    // Edit Profile Action Button at Bottom
                    SizedBox(
                      width: double.infinity,
                      height: Responsive.h(48),
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text(
                          'Edit Store Details & Hours',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        onPressed: () => _showEditProfileModal(context, _store),
                      ),
                    ),

                    SizedBox(height: Responsive.h(30)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    String? trailingBadge,
  }) {
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
        if (trailingBadge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
            ),
            child: Text(
              trailingBadge,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF16A34A),
              ),
            ),
          ),
      ],
    );
  }
}
