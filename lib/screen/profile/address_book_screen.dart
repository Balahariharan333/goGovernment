import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widget/common_background.dart';
import '../../widget/custom_text.dart';
import 'select_delivery_location_screen.dart';
import '../../bloc/address/address_bloc.dart';
import '../../bloc/address/address_event.dart';
import '../../bloc/address/address_state.dart';
import '../../model/address_model.dart';
export '../../model/address_model.dart';

class AddressBookScreen extends StatefulWidget {
  final bool isSelectionMode;

  const AddressBookScreen({
    super.key,
    this.isSelectionMode = false,
  });

  @override
  State<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends State<AddressBookScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: Responsive.w(70),
        leading: Padding(
          padding: EdgeInsets.only(left: Responsive.w(20)),
          child: Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
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
          ),
        ),
        title: CustomText.header(
          'Address Book',
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: false,
      ),
      body: BlocBuilder<AddressBloc, AddressState>(
        builder: (context, state) {
          final addresses = state.addresses;

          // Filter addresses locally by search query
          final filteredAddresses = addresses.where((addr) {
            final query = _searchQuery.toLowerCase().trim();
            if (query.isEmpty) return true;
            return addr.type.toLowerCase().contains(query) ||
                addr.description.toLowerCase().contains(query) ||
                addr.phone.toLowerCase().contains(query);
          }).toList();

          return CommonBackground(
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: Responsive.w(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: Responsive.h(16)),
                    // Search Location bar
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.w(16),
                        vertical: Responsive.h(4),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(Responsive.w(16)),
                        border: Border.all(
                          color: AppColors.outliner.withValues(alpha: 0.5),
                          width: Responsive.w(1.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            color: AppColors.grayFont,
                            size: Responsive.w(20),
                          ),
                          SizedBox(width: Responsive.w(12)),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) {
                                setState(() {
                                  _searchQuery = val;
                                });
                              },
                              style: TextStyle(
                                fontSize: Responsive.sp(14),
                                color: AppColors.black,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Search location',
                              ),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: Responsive.w(8)),
                                child: Icon(
                                  Icons.clear,
                                  color: AppColors.grayFont,
                                  size: Responsive.w(18),
                                ),
                              ),
                            ),
                          Icon(
                            Icons.my_location,
                            color: AppColors.primary,
                            size: Responsive.w(20),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: Responsive.h(24)),

                    // "Saved Addresses" title
                    CustomText.header(
                      'Saved Addresses',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    SizedBox(height: Responsive.h(16)),

                    // List of addresses
                    Expanded(
                      child: filteredAddresses.isEmpty
                          ? Center(
                              child: CustomText.body('No saved addresses found'),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: filteredAddresses.length,
                              itemBuilder: (context, index) {
                                final address = filteredAddresses[index];
                                final originalIndex = addresses.indexOf(address);
                                return Padding(
                                  padding: EdgeInsets.only(bottom: Responsive.h(14)),
                                  child: _buildAddressCard(context, originalIndex, address),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          final newAddr = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SelectDeliveryLocationScreen(),
            ),
          );
          if (newAddr != null && newAddr is AddressModel) {
            if (context.mounted) {
              context.read<AddressBloc>().add(AddAddressEvent(newAddr));
            }
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, int index, AddressModel address) {
    IconData iconData = Icons.home_outlined;
    if (address.type.toLowerCase() == 'office') {
      iconData = Icons.business_outlined;
    } else if (address.type.toLowerCase() == 'others') {
      iconData = Icons.place_outlined;
    }

    return GestureDetector(
      onTap: widget.isSelectionMode
          ? () {
              Navigator.pop(context, address);
            }
          : null,
      child: Container(
        padding: EdgeInsets.all(Responsive.w(16)),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(Responsive.w(20)),
          border: Border.all(
            color: AppColors.outliner,
            width: Responsive.w(1.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon indicator inside orange-peach soft background circle
            Container(
              width: Responsive.w(40),
              height: Responsive.w(40),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF2EC),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                color: AppColors.primary,
                size: Responsive.w(20),
              ),
            ),
            SizedBox(width: Responsive.w(12)),

            // Address info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText.title(
                    address.type,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: Responsive.h(6)),
                  CustomText.body(
                    address.description,
                    fontSize: 12,
                    color: AppColors.grayFont,
                    height: 1.35,
                  ),
                  SizedBox(height: Responsive.h(8)),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: Responsive.sp(12),
                        color: AppColors.grayFont,
                      ),
                      children: [
                        const TextSpan(text: 'Phone Number: '),
                        TextSpan(
                          text: address.phone,
                          style: const TextStyle(
                            color: AppColors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: Responsive.w(8)),

            // More options popup button
            PopupMenuButton<String>(
              color: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Responsive.w(12)),
                side: const BorderSide(color: AppColors.outliner, width: 1),
              ),
              elevation: 2,
              padding: EdgeInsets.zero,
              onSelected: (value) async {
                if (value == 'edit') {
                  final editedAddr = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SelectDeliveryLocationScreen(
                        editAddress: address,
                      ),
                    ),
                  );
                  if (editedAddr != null && editedAddr is AddressModel) {
                    if (context.mounted) {
                      context.read<AddressBloc>().add(UpdateAddressEvent(index, editedAddr));
                    }
                  }
                } else if (value == 'delete') {
                  context.read<AddressBloc>().add(DeleteAddressEvent(address));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Address deleted successfully'),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Responsive.w(12)),
                        ),
                      ),
                    );
                  }
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  value: 'edit',
                  height: Responsive.h(36),
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: Responsive.w(18), color: AppColors.black),
                      SizedBox(width: Responsive.w(8)),
                      CustomText.body('Edit Address', fontSize: 13),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  height: Responsive.h(36),
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: Responsive.w(18), color: AppColors.error),
                      SizedBox(width: Responsive.w(8)),
                      CustomText.body('Delete Address', fontSize: 13, color: AppColors.error),
                    ],
                  ),
                ),
              ],
              child: Icon(
                Icons.more_vert,
                color: AppColors.grayFont,
                size: Responsive.w(22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
