import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widget/common_background.dart';
import '../../widget/custom_text.dart';
import '../../widget/common_map.dart';
import '../../hive/hive_service.dart';
import 'address_book_screen.dart';

class SelectDeliveryLocationScreen extends StatefulWidget {
  final AddressModel? editAddress;

  const SelectDeliveryLocationScreen({
    super.key,
    this.editAddress,
  });

  @override
  State<SelectDeliveryLocationScreen> createState() => _SelectDeliveryLocationScreenState();
}

class _SelectDeliveryLocationScreenState extends State<SelectDeliveryLocationScreen> {
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();

  String _addressText = 'Select delivery address location';
  String _selectedType = 'Home'; // 'Home', 'Office', 'Others'
  bool _isKeyboardVisible = false;
  XFile? _landmarkImage;
  String? _existingImagePath;

  @override
  void initState() {
    super.initState();
    if (widget.editAddress != null) {
      final addr = widget.editAddress!;
      _selectedType = addr.type;
      _addressText = addr.description;
      _phoneController.text = addr.phone;
      _landmarkController.text = addr.landmark ?? '';
      _existingImagePath = addr.imagePath;
    } else {
      if (HiveService.userName.isNotEmpty) {
        _nameController.text = HiveService.userName;
      }
      if (HiveService.userPhone.isNotEmpty) {
        _phoneController.text = HiveService.userPhone;
      }
    }
  }

  Future<void> _pickLandmarkImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Responsive.w(20))),
      ),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library, color: AppColors.primary, size: Responsive.w(24)),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.of(bc).pop();
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() {
                      _landmarkImage = image;
                      _existingImagePath = null;
                    });
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera, color: AppColors.primary, size: Responsive.w(24)),
                title: const Text('Take a Photo'),
                onTap: () async {
                  Navigator.of(bc).pop();
                  final XFile? image = await picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    setState(() {
                      _landmarkImage = image;
                      _existingImagePath = null;
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _houseController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Detect keyboard visibility to toggle layouts statefully
    _isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    final bool isFormValid = _nameController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.screenColor,
      body: CommonBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // 1. Custom App Bar
              Container(
                height: Responsive.h(60),
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
                      'Select delivery location',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ],
                ),
              ),

              // 2. Scrollable Body
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Map View portion (hide when keyboard is active to maximize input view space)
                      if (!_isKeyboardVisible) ...[
                        SizedBox(
                          height: Responsive.h(220),
                          width: double.infinity,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: CommonMap(
                                  mapState: MapState.directions,
                                  isWalkMode: false,
                                ),
                              ),
                              // Floating Center Pin Marker
                              Center(
                                child: Container(
                                  margin: EdgeInsets.only(bottom: Responsive.h(30)),
                                  child: Icon(
                                    Icons.location_on,
                                    color: AppColors.primary,
                                    size: Responsive.w(38),
                                  ),
                                ),
                              ),
                              // "Use current location" overlay button
                              Positioned(
                                bottom: Responsive.h(12),
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: Responsive.w(16),
                                      vertical: Responsive.h(8),
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(Responsive.w(20)),
                                      border: Border.all(
                                        color: AppColors.primary,
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.my_location,
                                          color: AppColors.primary,
                                          size: Responsive.w(14),
                                        ),
                                        SizedBox(width: Responsive.w(6)),
                                        CustomText.title(
                                          'Use current location',
                                          color: AppColors.primary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: Responsive.h(16)),
                      ],

                      // Address Form input inputs
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: Responsive.w(20)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header location detail
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: AppColors.primary,
                                  size: Responsive.w(18),
                                ),
                                SizedBox(width: Responsive.w(8)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CustomText.title(
                                        'User details',
                                        fontSize: 11,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      SizedBox(height: Responsive.h(2)),
                                      CustomText.title(
                                        _addressText,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        height: 1.35,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: Responsive.h(16)),

                            // Floor / House no
                            _buildInputBox(
                              controller: _houseController,
                              hint: 'E.g. Floor, House no.',
                            ),
                            SizedBox(height: Responsive.h(12)),

                            // User Name*
                            _buildInputBox(
                              controller: _nameController,
                              hint: 'User Name*',
                              icon: Icons.person_outline,
                              onChanged: (val) => setState(() {}),
                            ),
                            SizedBox(height: Responsive.h(12)),

                            // User Number*
                            _buildInputBox(
                              controller: _phoneController,
                              hint: 'User Number*',
                              icon: Icons.phone_android_outlined,
                              keyboardType: TextInputType.phone,
                              onChanged: (val) => setState(() {}),
                            ),
                            SizedBox(height: Responsive.h(16)),

                            // Save address as pills
                            CustomText.title(
                              'Save address as',
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                            SizedBox(height: Responsive.h(8)),
                            Row(
                              children: [
                                _buildTypePill('Home', Icons.home_outlined),
                                SizedBox(width: Responsive.w(10)),
                                _buildTypePill('Office', Icons.business_outlined),
                                SizedBox(width: Responsive.w(10)),
                                _buildTypePill('Others', Icons.place_outlined),
                              ],
                            ),
                            SizedBox(height: Responsive.h(16)),

                            // Door number / Landmark (Optional)
                            _buildInputBox(
                              controller: _landmarkController,
                              hint: 'Door number, Landmark (Optional)',
                            ),
                            SizedBox(height: Responsive.h(16)),

                            // Add an image / Preview container
                            if (_landmarkImage != null || (_existingImagePath != null && _existingImagePath!.isNotEmpty))
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(Responsive.w(10)),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(Responsive.w(12)),
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(Responsive.w(8)),
                                      child: _landmarkImage != null
                                          ? Image.file(
                                              File(_landmarkImage!.path),
                                              width: Responsive.w(44),
                                              height: Responsive.h(44),
                                              fit: BoxFit.cover,
                                            )
                                          : (_existingImagePath!.startsWith('assets/')
                                              ? Image.asset(
                                                  _existingImagePath!,
                                                  width: Responsive.w(44),
                                                  height: Responsive.h(44),
                                                  fit: BoxFit.cover,
                                                )
                                              : Image.file(
                                                  File(_existingImagePath!),
                                                  width: Responsive.w(44),
                                                  height: Responsive.h(44),
                                                  fit: BoxFit.cover,
                                                )),
                                    ),
                                    SizedBox(width: Responsive.w(12)),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CustomText.title(
                                            'Landmark Photo Attached',
                                            color: AppColors.primary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          const Text(
                                            'Tap delete to remove or choose another',
                                            style: TextStyle(color: Colors.grey, fontSize: 8),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: AppColors.error, size: 20),
                                      onPressed: () {
                                        setState(() {
                                          _landmarkImage = null;
                                          _existingImagePath = null;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              )
                            else
                              GestureDetector(
                                onTap: () => _pickLandmarkImage(context),
                                child: Container(
                                  width: double.infinity,
                                  height: Responsive.h(50),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(Responsive.w(12)),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(alpha: 0.5),
                                      style: BorderStyle.solid,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_a_photo_outlined,
                                        color: AppColors.primary,
                                        size: Responsive.w(16),
                                      ),
                                      SizedBox(width: Responsive.w(8)),
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CustomText.title(
                                            'Add an image',
                                            color: AppColors.primary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          const Text(
                                            'This helps our experts find your exact location faster',
                                            style: TextStyle(color: Colors.grey, fontSize: 8),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            SizedBox(height: Responsive.h(100)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Sticky Bottom Save Address CTA Button
      bottomNavigationBar: Container(
        color: AppColors.white,
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.w(20),
          vertical: Responsive.h(16),
        ),
        child: GestureDetector(
          onTap: isFormValid
              ? () {
                  final newAddr = AddressModel(
                    type: _selectedType,
                    description: _houseController.text.trim().isNotEmpty
                        ? '${_houseController.text.trim()}, $_addressText'
                        : _addressText,
                    phone: _phoneController.text.trim(),
                    landmark: _landmarkController.text.trim(),
                    imagePath: _landmarkImage?.path ?? _existingImagePath,
                  );
                  Navigator.pop(context, newAddr);
                }
              : null,
          child: Container(
            height: Responsive.h(48),
            decoration: BoxDecoration(
              color: isFormValid ? AppColors.primary : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(Responsive.w(24)),
              border: Border.all(
                color: isFormValid ? AppColors.primary : Colors.grey.shade300,
                width: 1.2,
              ),
            ),
            child: Center(
              child: CustomText.title(
                'Save address',
                color: isFormValid ? Colors.white : Colors.grey,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBox({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      height: Responsive.h(48),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Responsive.w(12)),
        border: Border.all(
          color: AppColors.outliner,
          width: 1.2,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: Responsive.w(16)),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          if (icon != null)
            Icon(
              icon,
              color: AppColors.primary,
              size: Responsive.w(18),
            ),
        ],
      ),
    );
  }

  Widget _buildTypePill(String type, IconData icon) {
    final bool isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.w(16),
          vertical: Responsive.h(8),
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF2EC) : AppColors.white,
          borderRadius: BorderRadius.circular(Responsive.w(16)),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : Colors.grey,
              size: Responsive.w(14),
            ),
            SizedBox(width: Responsive.w(6)),
            CustomText.title(
              type,
              color: isSelected ? AppColors.primary : Colors.grey.shade700,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
      ),
    );
  }
}
