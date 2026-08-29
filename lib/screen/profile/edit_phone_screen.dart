import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widget/common_background.dart';
import '../../widget/custom_text.dart';
class EditPhoneScreen extends StatefulWidget {
  final String initialPhone;

  const EditPhoneScreen({
    super.key,
    required this.initialPhone,
  });

  @override
  State<EditPhoneScreen> createState() => _EditPhoneScreenState();
}

class _EditPhoneScreenState extends State<EditPhoneScreen> {
  late TextEditingController _phoneController;
  bool _isModified = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.initialPhone);
    _phoneController.addListener(_checkModification);
  }

  void _checkModification() {
    final bool modified = _phoneController.text.trim() != widget.initialPhone &&
        _phoneController.text.trim().isNotEmpty;
    if (modified != _isModified) {
      setState(() {
        _isModified = modified;
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_isModified) {
      Navigator.pop(context, _phoneController.text.trim());
    }
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
      ),
      body: CommonBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: Responsive.w(24)),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        SizedBox(height: Responsive.h(40)),
                        // Phone input container
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(Responsive.w(16)),
                            border: Border.all(
                              color: AppColors.outliner.withValues(alpha: 0.5),
                              width: Responsive.w(1.2),
                            ),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.w(16),
                            vertical: Responsive.h(4),
                          ),
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(
                              fontSize: Responsive.sp(15),
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Enter Phone Number',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Submit Button
                GestureDetector(
                  onTap: _submit,
                  child: Container(
                    width: double.infinity,
                    height: Responsive.h(50),
                    margin: EdgeInsets.only(bottom: Responsive.h(20)),
                    decoration: BoxDecoration(
                      color: _isModified ? AppColors.white : const Color(0xFFF4EDE8),
                      borderRadius: BorderRadius.circular(Responsive.w(25)),
                      border: Border.all(
                        color: _isModified ? AppColors.primary : Colors.transparent,
                        width: Responsive.w(1.5),
                      ),
                    ),
                    child: Center(
                      child: CustomText.title(
                        'Submit',
                        color: _isModified ? AppColors.primary : const Color(0xFFC0B3AC),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
