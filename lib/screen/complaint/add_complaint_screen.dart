import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widget/common_background.dart';
import '../../widget/custom_text.dart';
import '../../bloc/complaint/complaint_bloc.dart';
import '../../bloc/complaint/complaint_event.dart';
import '../../bloc/complaint/complaint_state.dart';
import '../../bloc/report/report_bloc.dart';
import '../../bloc/report/report_event.dart';
import '../../bloc/transaction/transaction_bloc.dart';
import '../../bloc/transaction/transaction_event.dart';

class AddComplaintScreen extends StatefulWidget {
  final String? category;

  const AddComplaintScreen({
    super.key,
    this.category,
  });

  @override
  State<AddComplaintScreen> createState() => _AddComplaintScreenState();
}

class _AddComplaintScreenState extends State<AddComplaintScreen> {
  final TextEditingController _descriptionController = TextEditingController();

  final List<String> _categories = [
    'Roads & Transportation',
    'Garbage & Waste Management',
    'Streetlights & Electricity',
    'Water Supply',
    'Drainage & Sewage',
    'Cleanliness & Sanitation',
    'Parks & Public Spaces',
    'Environmental Issues',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      context.read<ComplaintBloc>().add(SelectComplaintCategoryEvent(widget.category!));
    }
    _descriptionController.addListener(_updateState);
  }

  @override
  void dispose() {
    _descriptionController.removeListener(_updateState);
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateState() {
    setState(() {});
  }

  Future<void> _pickImage(BuildContext context) async {
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
                title: CustomText.body('Photo Library'),
                onTap: () async {
                  Navigator.of(bc).pop();
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    if (!context.mounted) return;
                    context.read<ComplaintBloc>().add(PickComplaintImageEvent(image));
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera, color: AppColors.primary, size: Responsive.w(24)),
                title: CustomText.body('Camera'),
                onTap: () async {
                  Navigator.of(bc).pop();
                  final XFile? image = await picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    if (!context.mounted) return;
                    context.read<ComplaintBloc>().add(PickComplaintImageEvent(image));
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
              onTap: () {
                context.read<ComplaintBloc>().add(ClearComplaintEvent());
                Navigator.pop(context);
              },
              child: Container(
                width: Responsive.w(40),
                height: Responsive.w(40),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(Responsive.w(12)),
                  border: Border.all(
                    color: AppColors.outliner,
                    width: Responsive.w(1.2),
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
          widget.category ?? 'Add Complaint',
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: false,
      ),
      body: BlocConsumer<ComplaintBloc, ComplaintState>(
        listener: (context, state) {
          if (state.isSubmitted) {
            context.read<ReportBloc>().add(LoadReportsEvent());

            // Reward citizen coins for reporting complaint
            final rewardTx = {
              'id': 'REW-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
              'title': 'Complaint coins',
              'subtitle': 'Earned through reporting · ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
              'amount': '+200',
              'isPositive': true,
              'status': 'Credited',
              'date': 'Today',
              'items': [],
              'address': 'Grievance Redressal Reward',
              'listingPrice': '₹0.00',
              'sellingPrice': '₹200.00',
              'grandTotal': '₹200.00',
              'paid': '₹200.00',
            };
            context.read<TransactionBloc>().add(AddCoinsEvent(200));
            context.read<TransactionBloc>().add(AddTransactionEvent(rewardTx));

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Complaint Submitted & 200 Coins Earned!'),
                backgroundColor: AppColors.success,
              ),
            );
            context.read<ComplaintBloc>().add(ClearComplaintEvent());
            Navigator.pop(context);
          }
        },
        builder: (context, state) {
          final String selectedCategory = state.selectedCategory.isNotEmpty ? state.selectedCategory : (widget.category ?? '');
          final XFile? imageFile = state.imageFile;
          final bool isSubmitting = state.isSubmitting;

          final bool isFormValid = selectedCategory.isNotEmpty &&
              _descriptionController.text.trim().isNotEmpty &&
              !isSubmitting;

          return CommonBackground(
            child: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.w(20),
                    vertical: Responsive.h(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Map container
                      Container(
                        height: Responsive.h(180),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(Responsive.w(24)),
                          border: Border.all(
                            color: AppColors.outliner,
                            width: Responsive.w(1.5),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: MapPainter(),
                              ),
                            ),
                            // Compass Floating button in map
                            Positioned(
                              top: Responsive.h(12),
                              right: Responsive.w(12),
                              child: Container(
                                width: Responsive.w(38),
                                height: Responsive.w(38),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: Responsive.w(6),
                                      offset: Offset(0, Responsive.h(2)),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.my_location,
                                  color: AppColors.primary,
                                  size: Responsive.w(20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: Responsive.h(20)),

                      // 2. Current Location section
                      CustomText.subtitle(
                        'Current Location',
                        fontSize: 13,
                        color: AppColors.grayFont,
                        fontWeight: FontWeight.bold,
                      ),
                      SizedBox(height: Responsive.h(8)),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(Responsive.w(16)),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(Responsive.w(16)),
                          border: Border.all(
                            color: AppColors.outliner,
                            width: Responsive.w(1.5),
                          ),
                        ),
                        child: CustomText.body(
                          '552, 2nd Floor 16th Main, 15th Cross Rd, 4th Sector, HSR Layout, Bengaluru, Karnataka 560102',
                          fontSize: 13,
                          color: const Color(0xFF333333),
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                      SizedBox(height: Responsive.h(20)),

                      // 3. Add Category Section (Only if not preselected)
                      if (widget.category == null) ...[
                        CustomText.subtitle(
                          'Add Category',
                          fontSize: 13,
                          color: AppColors.grayFont,
                          fontWeight: FontWeight.bold,
                        ),
                        SizedBox(height: Responsive.h(8)),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(Responsive.w(16)),
                            border: Border.all(
                              color: AppColors.outliner,
                              width: Responsive.w(1.5),
                            ),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: Responsive.w(16)),
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedCategory.isNotEmpty ? selectedCategory : null,
                            hint: CustomText.body(
                              'Select Category',
                              color: Colors.grey,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            items: _categories.map((String cat) {
                              return DropdownMenuItem<String>(
                                value: cat,
                                child: CustomText.body(cat),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                context.read<ComplaintBloc>().add(SelectComplaintCategoryEvent(value));
                              }
                            },
                          ),
                        ),
                        SizedBox(height: Responsive.h(20)),
                      ],

                      // 4. Description section
                      CustomText.subtitle(
                        'Please provide a brief description about the complaint',
                        fontSize: 13,
                        color: AppColors.grayFont,
                        fontWeight: FontWeight.bold,
                      ),
                      SizedBox(height: Responsive.h(8)),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 4,
                        style: TextStyle(
                          fontSize: Responsive.sp(14),
                          color: AppColors.black,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.white,
                          hintText: 'Enter details about the issue...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: Responsive.sp(14),
                          ),
                          contentPadding: EdgeInsets.all(Responsive.w(16)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Responsive.w(16)),
                            borderSide: BorderSide(
                              color: AppColors.outliner,
                              width: Responsive.w(1.5),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Responsive.w(16)),
                            borderSide: BorderSide(
                              color: AppColors.outliner,
                              width: Responsive.w(1.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(Responsive.w(16)),
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: Responsive.w(1.5),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: Responsive.h(20)),

                      // 5. Add a photo section
                      CustomText.subtitle(
                        'Add a photo',
                        fontSize: 13,
                        color: AppColors.grayFont,
                        fontWeight: FontWeight.bold,
                      ),
                      SizedBox(height: Responsive.h(8)),
                      GestureDetector(
                        onTap: () => _pickImage(context),
                        child: Container(
                          height: Responsive.h(120),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(Responsive.w(16)),
                            border: Border.all(
                              color: AppColors.outliner,
                              width: Responsive.w(1.5),
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: imageFile != null
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(
                                      File(imageFile.path),
                                      fit: BoxFit.cover,
                                    ),
                                    Positioned(
                                      top: Responsive.h(8),
                                      right: Responsive.w(8),
                                      child: GestureDetector(
                                        onTap: () {
                                          context.read<ComplaintBloc>().add(ClearComplaintEvent());
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(Responsive.w(4)),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: Responsive.w(18),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Center(
                                  child: Container(
                                    width: Responsive.w(44),
                                    height: Responsive.w(44),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFBF8F6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.add_a_photo_outlined,
                                      color: AppColors.black,
                                      size: Responsive.w(20),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: Responsive.h(16)),

                      // 6. Disclaimer
                      Center(
                        child: CustomText.subtitle(
                          'Add a description and photo to submit your complaint',
                          fontSize: 11,
                          color: AppColors.grayFont,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: Responsive.h(12)),

                      // 7. Submit button
                      GestureDetector(
                        onTap: isFormValid
                            ? () {
                                final categoryToSubmit = selectedCategory.isNotEmpty
                                    ? selectedCategory
                                    : (widget.category ?? 'Roads & Transportation');
                                context.read<ComplaintBloc>().add(
                                      SubmitComplaintEvent(
                                        description: _descriptionController.text.trim(),
                                        category: categoryToSubmit,
                                        location: '552, 2nd Floor 16th Main, 15th Cross Rd, 4th Sector, HSR Layout, Bengaluru, Karnataka 560102',
                                        imagePath: imageFile?.path,
                                      ),
                                    );
                              }
                            : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: Responsive.h(52),
                          decoration: BoxDecoration(
                            color: isFormValid ? const Color(0xFFFFF6F3) : Colors.grey[200],
                            borderRadius: BorderRadius.circular(Responsive.w(26)),
                            border: Border.all(
                              color: isFormValid ? AppColors.primary : Colors.grey[300]!,
                              width: Responsive.w(1.5),
                            ),
                          ),
                          child: Center(
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.0,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                    ),
                                  )
                                : CustomText.title(
                                    'Submit',
                                    color: isFormValid ? AppColors.primary : Colors.grey[400]!,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                          ),
                        ),
                      ),
                      SizedBox(height: Responsive.h(40)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Custom Painter to render a stylized, high-fidelity local map
class MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Draw light gray block representing building blocks
    final paintBlock = Paint()
      ..color = const Color(0xFFFBF8F6)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.05, h * 0.05, w * 0.38, h * 0.38), const Radius.circular(12)), paintBlock);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.55, h * 0.05, w * 0.4, h * 0.28), const Radius.circular(12)), paintBlock);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.05, h * 0.55, w * 0.42, h * 0.4), const Radius.circular(12)), paintBlock);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.58, h * 0.45, w * 0.37, h * 0.5), const Radius.circular(12)), paintBlock);

    // Draw white background roads
    final paintRoad = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16.0
      ..strokeCap = StrokeCap.round;

    // Vertical road
    canvas.drawLine(Offset(w * 0.5, -10), Offset(w * 0.5, h + 10), paintRoad);
    // Horizontal road
    canvas.drawLine(Offset(-10, h * 0.48), Offset(w + 10, h * 0.48), paintRoad);

    // Draw inner thin road divider line
    final paintDivider = Paint()
      ..color = const Color(0xFFEFECE9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(w * 0.5, -10), Offset(w * 0.5, h + 10), paintDivider);
    canvas.drawLine(Offset(-10, h * 0.48), Offset(w + 10, h * 0.48), paintDivider);

    // Draw park block (soft green zone)
    final paintPark = Paint()
      ..color = const Color(0xFFE2F0D9)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.7, h * 0.1, w * 0.2, h * 0.2), const Radius.circular(8)), paintPark);

    // Draw radar wave circle around pin
    final paintRadar = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.48), 28.0, paintRadar);
    canvas.drawCircle(Offset(w * 0.5, h * 0.48), 14.0, paintRadar);

    // Location pin (red dot)
    final paintPin = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.48), 7.0, paintPin);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
