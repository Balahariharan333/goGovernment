import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../bloc/product/product_bloc.dart';
import '../../bloc/product/product_event.dart';
import '../../bloc/product/product_state.dart';
import '../../model/product_model.dart';
import '../../network/store_api_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widget/common_background.dart';
import '../../widget/custom_text.dart';

class AddProductScreen extends StatefulWidget {
  final String storeId;
  final String storeCategory;
  final ProductModel? initialProduct;

  const AddProductScreen({
    super.key,
    required this.storeId,
    required this.storeCategory,
    this.initialProduct,
  });

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  bool get _isEditing => widget.initialProduct != null;

  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _origPriceController;
  late TextEditingController _stockController;
  late TextEditingController _unitController;
  late TextEditingController _brandController;
  late TextEditingController _packOfController;
  late TextEditingController _typeController;
  late TextEditingController _shelfLifeController;
  late TextEditingController _formFactorController;
  late TextEditingController _originController;
  late TextEditingController _descriptionController;
  late TextEditingController _subsidyLimitController;

  String _selectedCategory = 'general';
  bool _isSubsidized = false;
  File? _pickedImage;
  String? _uploadedImageUrl;
  bool _isUploadingImage = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final p = widget.initialProduct;
    if (p != null) {
      _selectedCategory = p.category.isNotEmpty ? p.category : (widget.storeCategory.isNotEmpty ? widget.storeCategory : 'general');
      _titleController = TextEditingController(text: p.title);
      _priceController = TextEditingController(text: p.price.toStringAsFixed(0));
      _origPriceController = TextEditingController(text: p.originalPrice > 0 ? p.originalPrice.toStringAsFixed(0) : '');
      _stockController = TextEditingController(text: p.stock.toString());
      _unitController = TextEditingController(text: p.unit);
      _brandController = TextEditingController(text: p.brand);
      _packOfController = TextEditingController(text: p.packOf);
      _typeController = TextEditingController(text: p.type);
      _shelfLifeController = TextEditingController(text: p.shelfLife);
      _formFactorController = TextEditingController(text: p.formFactor);
      _originController = TextEditingController(text: p.origin);
      _descriptionController = TextEditingController(text: p.description);
      _subsidyLimitController = TextEditingController(text: p.subsidyLimit);
      _isSubsidized = p.isSubsidized;
      if (p.image.isNotEmpty) {
        _uploadedImageUrl = p.image;
      }
    } else {
      _selectedCategory = widget.storeCategory.isNotEmpty ? widget.storeCategory : 'general';
      _titleController = TextEditingController();
      _priceController = TextEditingController();
      _origPriceController = TextEditingController();
      _stockController = TextEditingController(text: '10');
      _unitController = TextEditingController(text: '1 Units');
      _brandController = TextEditingController(text: 'Unbranded');
      _packOfController = TextEditingController(text: '1');
      _typeController = TextEditingController();
      _shelfLifeController = TextEditingController(text: '7 Days');
      _formFactorController = TextEditingController(text: 'Whole');
      _originController = TextEditingController(text: 'India');
      _descriptionController = TextEditingController();
      _subsidyLimitController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _origPriceController.dispose();
    _stockController.dispose();
    _unitController.dispose();
    _brandController.dispose();
    _packOfController.dispose();
    _typeController.dispose();
    _shelfLifeController.dispose();
    _formFactorController.dispose();
    _originController.dispose();
    _descriptionController.dispose();
    _subsidyLimitController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 75);
      if (picked != null) {
        setState(() {
          _pickedImage = File(picked.path);
          _isUploadingImage = true;
        });

        final uploaded = await StoreApiService.uploadProductImage(picked.path);
        setState(() {
          _isUploadingImage = false;
          if (uploaded != null) {
            _uploadedImageUrl = uploaded;
          }
        });
      }
    } catch (e) {
      setState(() => _isUploadingImage = false);
    }
  }

  // ================= 🧪 MOCK DATA PRESETS FOR RAPID TESTING ================= //
  static final List<Map<String, dynamic>> _mockPresets = [
    {
      'presetName': '🍉 Watermelon (Citizen App)',
      'title': 'Watermelon striped',
      'category': 'vegstore',
      'unit': '1 Units (2-3 kg)',
      'price': '83',
      'originalPrice': '106',
      'stock': '15',
      'brand': 'Karnataka Horticulture',
      'packOf': '1',
      'type': 'Watermelon striped',
      'shelfLife': '7 Days',
      'formFactor': 'Whole',
      'origin': 'India',
      'isSubsidized': false,
      'subsidyLimit': '',
      'description': 'Sweet, juicy farm-harvested watermelon with high hydration and rich antioxidant content.',
      'image': 'assets/images/product1.png',
    },
    {
      'presetName': '🌾 Ration Sona Masoori Rice',
      'title': 'Govt Ration Sona Masoori Rice',
      'category': 'ration',
      'unit': '5 kg Bag',
      'price': '125',
      'originalPrice': '220',
      'stock': '50',
      'brand': 'Civil Supplies Corp',
      'packOf': '1',
      'type': 'Raw Rice Grade A',
      'shelfLife': '6 Months',
      'formFactor': 'Grain',
      'origin': 'Tamil Nadu, India',
      'isSubsidized': true,
      'subsidyLimit': '10 kg per ration card',
      'description': 'Subsidized fine polished grain rice supplied by Civil Supplies Department for ration cardholders.',
      'image': 'assets/images/product2.png',
    },
    {
      'presetName': '🍬 PDS Crystal Sugar',
      'title': 'Refined Crystal Sugar (M-30)',
      'category': 'ration',
      'unit': '1 kg Pack',
      'price': '25',
      'originalPrice': '44',
      'stock': '35',
      'brand': 'State Sugar Federation',
      'packOf': '1',
      'type': 'White Crystal Sugar',
      'shelfLife': '12 Months',
      'formFactor': 'Crystal',
      'origin': 'India',
      'isSubsidized': true,
      'subsidyLimit': '2 kg per card',
      'description': 'PDS subsidized premium white sugar for essential family ration quota.',
      'image': 'assets/images/product3.png',
    },
    {
      'presetName': '💊 Paracetamol 500mg',
      'title': 'Paracetamol IP 500mg Tablets',
      'category': 'medical',
      'unit': '10 Tablets / Strip',
      'price': '18',
      'originalPrice': '40',
      'stock': '80',
      'brand': 'Jan Aushadhi / Cipla',
      'packOf': '1 Strip',
      'type': 'Antipyretic',
      'shelfLife': '24 Months',
      'formFactor': 'Tablet',
      'origin': 'India',
      'isSubsidized': true,
      'subsidyLimit': '3 Strips per citizen',
      'description': 'Affordable generic fever and mild pain relief tablets with quality certification.',
      'image': 'assets/images/product1.png',
    },
    {
      'presetName': '🥛 Pasteurized Milk',
      'title': 'Standardized Pasteurized Milk',
      'category': 'dairy',
      'unit': '500 ml Pouch',
      'price': '26',
      'originalPrice': '28',
      'stock': '40',
      'brand': 'Aavin Daily',
      'packOf': '1',
      'type': 'Toned Milk 4.5% Fat',
      'shelfLife': '2 Days',
      'formFactor': 'Liquid',
      'origin': 'India',
      'isSubsidized': false,
      'subsidyLimit': '',
      'description': 'Daily morning fresh pasteurized milk rich in calcium and essential vitamins.',
      'image': 'assets/images/product2.png',
    },
    {
      'presetName': '🍅 Country Tomatoes',
      'title': 'Organic Country Tomatoes',
      'category': 'vegstore',
      'unit': '1 kg Bag',
      'price': '34',
      'originalPrice': '50',
      'stock': '25',
      'brand': 'Local Farmers Collective',
      'packOf': '1',
      'type': 'Country Hybrid',
      'shelfLife': '5 Days',
      'formFactor': 'Fresh Whole',
      'origin': 'India',
      'isSubsidized': false,
      'subsidyLimit': '',
      'description': 'Freshly picked tangy country tomatoes suitable for daily culinary curries and salads.',
      'image': 'assets/images/product3.png',
    },
  ];

  void _applyMockPreset(Map<String, dynamic> data) {
    setState(() {
      _titleController.text = data['title'] ?? '';
      _selectedCategory = data['category'] ?? widget.storeCategory;
      _unitController.text = data['unit'] ?? '';
      _priceController.text = data['price'] ?? '';
      _origPriceController.text = data['originalPrice'] ?? '';
      _stockController.text = data['stock'] ?? '10';
      _brandController.text = data['brand'] ?? 'Unbranded';
      _packOfController.text = data['packOf'] ?? '1';
      _typeController.text = data['type'] ?? '';
      _shelfLifeController.text = data['shelfLife'] ?? '7 Days';
      _formFactorController.text = data['formFactor'] ?? 'Whole';
      _originController.text = data['origin'] ?? 'India';
      _isSubsidized = data['isSubsidized'] == true;
      _subsidyLimitController.text = data['subsidyLimit'] ?? '';
      _descriptionController.text = data['description'] ?? '';
      _uploadedImageUrl = data['image'] ?? '';
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.bolt_rounded, color: Colors.amber, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('Autofilled demo: "${data['title']}"! Tap Add Product below.')),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final origPrice = double.tryParse(_origPriceController.text.trim()) ?? 0.0;
    final stock = int.tryParse(_stockController.text.trim()) ?? 10;

    final product = ProductModel(
      productId: _isEditing ? widget.initialProduct!.productId : '',
      storeId: widget.storeId,
      title: _titleController.text.trim(),
      category: _selectedCategory,
      unit: _unitController.text.trim(),
      price: price,
      originalPrice: origPrice > 0 ? origPrice : price,
      stock: stock,
      image: _uploadedImageUrl ?? widget.initialProduct?.image ?? '',
      brand: _brandController.text.trim(),
      packOf: _packOfController.text.trim(),
      type: _typeController.text.trim(),
      shelfLife: _shelfLifeController.text.trim(),
      formFactor: _formFactorController.text.trim(),
      origin: _originController.text.trim(),
      isSubsidized: _isSubsidized,
      subsidyLimit: _isSubsidized ? _subsidyLimitController.text.trim() : '',
      description: _descriptionController.text.trim(),
      isAvailable: stock > 0,
    );

    if (_isEditing) {
      context.read<ProductBloc>().add(UpdateProductEvent(product));
    } else {
      context.read<ProductBloc>().add(AddProductEvent(product));
    }
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return BlocListener<ProductBloc, ProductState>(
      listener: (context, state) {
        if (state is ProductSubmitSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        } else if (state is ProductError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.screenColor,
        appBar: AppBar(
          backgroundColor: AppColors.screenColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.black, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: CustomText.title(_isEditing ? 'Edit Store Product' : 'Add New Store Product', fontSize: 16, color: AppColors.black),
          centerTitle: true,
          actions: [
            if (!_isEditing)
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.only(right: Responsive.w(12)),
                ),
                icon: const Icon(Icons.bolt_rounded, size: 18, color: Colors.amber),
                label: const Text(
                  'Demo Fill',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                onPressed: () {
                  final matching = _mockPresets.firstWhere(
                    (p) => p['category'] == widget.storeCategory,
                    orElse: () => _mockPresets.first,
                  );
                  _applyMockPreset(matching);
                },
              ),
          ],
        ),
        body: CommonBackground(
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: Responsive.w(20), vertical: Responsive.h(12)),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🧪 Quick Demo Autofill Bar for Rapid Testing
                    Container(
                      margin: EdgeInsets.only(bottom: Responsive.h(16)),
                      padding: EdgeInsets.all(Responsive.w(12)),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF1E293B),
                            Color(0xFF0F172A),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(Responsive.w(16)),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.science_outlined, color: Colors.amber, size: 18),
                              SizedBox(width: Responsive.w(6)),
                              CustomText.title('Testing Presets (1-Tap Auto-Fill)', fontSize: 12, color: Colors.white),
                            ],
                          ),
                          SizedBox(height: Responsive.h(10)),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: _mockPresets.map((preset) {
                                return Padding(
                                  padding: EdgeInsets.only(right: Responsive.w(8)),
                                  child: ActionChip(
                                    backgroundColor: const Color(0xFF334155),
                                    side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                    label: Text(
                                      preset['presetName'],
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                    onPressed: () => _applyMockPreset(preset),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Product Photo Picker
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (ctx) => SafeArea(
                              child: Wrap(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.photo_camera_rounded, color: AppColors.primary),
                                    title: const Text('Take Photo with Camera'),
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      _pickImage(ImageSource.camera);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                                    title: const Text('Choose from Gallery'),
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      _pickImage(ImageSource.gallery);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: Responsive.w(110),
                          height: Responsive.w(110),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(Responsive.w(20)),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.5),
                              width: 1.5,
                              style: BorderStyle.solid,
                            ),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: _isUploadingImage
                              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                              : (_pickedImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(Responsive.w(20)),
                                      child: Image.file(_pickedImage!, fit: BoxFit.cover),
                                    )
                                  : (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(Responsive.w(20)),
                                          child: _uploadedImageUrl!.startsWith('assets/')
                                              ? Image.asset(
                                                  _uploadedImageUrl!,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (ctx, err, st) => const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 36),
                                                )
                                              : Image.network(
                                                  _uploadedImageUrl!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (ctx, err, st) => const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 36),
                                                ),
                                        )
                                      : Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_a_photo_outlined, size: 28, color: AppColors.primary),
                                            SizedBox(height: Responsive.h(6)),
                                            CustomText.body('Product Photo', fontSize: 11, color: AppColors.grayFont),
                                          ],
                                        ))),
                        ),
                      ),
                    ),

                    SizedBox(height: Responsive.h(20)),

                    // 1. Basic Information
                    _buildSectionHeader('Basic Product Details'),
                    _buildInputField(
                      controller: _titleController,
                      label: 'Product Title / Name',
                      hint: 'e.g. Sona Masoori Rice, Paracetamol 500mg',
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Product name is required' : null,
                    ),
                    SizedBox(height: Responsive.h(12)),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            controller: _unitController,
                            label: 'Unit / Packaging',
                            hint: 'e.g. 1 kg, 500 g, 1 Units',
                          ),
                        ),
                        SizedBox(width: Responsive.w(12)),
                        Expanded(
                          child: _buildInputField(
                            controller: _brandController,
                            label: 'Brand / Manufacturer',
                            hint: 'e.g. Govt PDS, Cipla',
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: Responsive.h(20)),

                    // 2. Pricing & Stock
                    _buildSectionHeader('Pricing & Available Stock'),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            controller: _priceController,
                            label: 'Selling Price (₹)',
                            hint: 'e.g. 99',
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Selling price required';
                              if (double.tryParse(v.trim()) == null) return 'Invalid number';
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: Responsive.w(12)),
                        Expanded(
                          child: _buildInputField(
                            controller: _origPriceController,
                            label: 'Original MRP (₹)',
                            hint: 'e.g. 150',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Responsive.h(12)),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            controller: _stockController,
                            label: 'Total Stock Quantity',
                            hint: 'e.g. 25',
                            keyboardType: TextInputType.number,
                            validator: (v) => (v == null || int.tryParse(v.trim()) == null) ? 'Enter valid stock count' : null,
                          ),
                        ),
                        SizedBox(width: Responsive.w(12)),
                        Expanded(
                          child: _buildInputField(
                            controller: _packOfController,
                            label: 'Pack Of',
                            hint: 'e.g. 1, 2, 4',
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: Responsive.h(20)),

                    // 3. Citizen App Specifications
                    _buildSectionHeader('Citizen App Highlights & Specs'),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            controller: _shelfLifeController,
                            label: 'Shelf Life',
                            hint: 'e.g. 7 Days, 6 Months',
                          ),
                        ),
                        SizedBox(width: Responsive.w(12)),
                        Expanded(
                          child: _buildInputField(
                            controller: _formFactorController,
                            label: 'Form Factor',
                            hint: 'e.g. Whole, Liquid, Tablet',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Responsive.h(12)),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            controller: _typeController,
                            label: 'Sub-Type / Variety',
                            hint: 'e.g. Raw Rice, Antibiotic',
                          ),
                        ),
                        SizedBox(width: Responsive.w(12)),
                        Expanded(
                          child: _buildInputField(
                            controller: _originController,
                            label: 'Country of Origin',
                            hint: 'e.g. India',
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: Responsive.h(20)),

                    // 4. Government Subsidy Quota
                    _buildSectionHeader('Government Subsidy Status'),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: Responsive.w(16), vertical: Responsive.h(12)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(Responsive.w(16)),
                        border: Border.all(color: AppColors.outliner.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText.title('Govt Subsidized Item', fontSize: 13, color: AppColors.black),
                                  SizedBox(height: Responsive.h(2)),
                                  CustomText.body('Apply public distribution / PDS quota', fontSize: 11, color: AppColors.grayFont),
                                ],
                              ),
                              Switch(
                                value: _isSubsidized,
                                activeThumbColor: AppColors.primary,
                                onChanged: (v) => setState(() => _isSubsidized = v),
                              ),
                            ],
                          ),
                          if (_isSubsidized) ...[
                            SizedBox(height: Responsive.h(10)),
                            _buildInputField(
                              controller: _subsidyLimitController,
                              label: 'Monthly Citizen Quota',
                              hint: 'e.g. 5 kg per ration card / month',
                            ),
                          ],
                        ],
                      ),
                    ),

                    SizedBox(height: Responsive.h(20)),

                    // 5. Description
                    _buildSectionHeader('Product Description & Key Features'),
                    _buildInputField(
                      controller: _descriptionController,
                      label: 'Description',
                      hint: 'Enter detailed specifications, usage advice, or features for citizens...',
                      maxLines: 3,
                    ),

                    SizedBox(height: Responsive.h(30)),

                    // Submit Button
                    BlocBuilder<ProductBloc, ProductState>(
                      builder: (context, state) {
                        final isLoading = state is ProductSubmitting;
                        return SizedBox(
                          width: double.infinity,
                          height: Responsive.h(50),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(Responsive.w(16)),
                              ),
                              elevation: 0,
                            ),
                            onPressed: isLoading ? null : _submit,
                            child: isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(_isEditing ? Icons.check_circle_outline_rounded : Icons.add_circle_outline_rounded, color: Colors.white, size: 20),
                                      SizedBox(width: Responsive.w(8)),
                                      CustomText.title(_isEditing ? 'Save Product Changes' : 'Add Product to Catalog', fontSize: 15, color: Colors.white),
                                    ],
                                  ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: Responsive.h(20)),
                  ],
                ),
              ),
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
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
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(horizontal: Responsive.w(14), vertical: Responsive.h(12)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Responsive.w(14)),
              borderSide: BorderSide(color: AppColors.outliner.withValues(alpha: 0.6)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Responsive.w(14)),
              borderSide: BorderSide(color: AppColors.outliner.withValues(alpha: 0.6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Responsive.w(14)),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
