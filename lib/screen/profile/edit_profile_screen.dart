import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widget/common_background.dart';
import '../../widget/custom_text.dart';
import '../../bloc/profile/profile_bloc.dart';
import '../../bloc/profile/profile_event.dart';
import '../../hive/hive_service.dart';
import '../home/main_screen.dart';

class EditProfileScreen extends StatefulWidget {
  final String initialName;
  final String initialEmail;
  final bool isRegistration;

  const EditProfileScreen({
    super.key,
    this.initialName = '',
    this.initialEmail = '',
    this.isRegistration = false,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  bool _isModified = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);

    _nameController.addListener(_checkModification);
    _emailController.addListener(_checkModification);
  }

  void _checkModification() {
    setState(() {
      _isModified = _nameController.text.trim() != widget.initialName ||
          _emailController.text.trim() != widget.initialEmail;
    });
  }

  static final RegExp _emailRegExp =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  bool get _isValidEmail {
    final email = _emailController.text.trim();
    return _emailRegExp.hasMatch(email);
  }

  bool get _canSubmit {
    final name = _nameController.text.trim();
    if (widget.isRegistration) {
      return name.length >= 2 && _isValidEmail;
    }
    return _isModified && name.length >= 2 && _isValidEmail;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    if (!_canSubmit) return;

    if (widget.isRegistration) {
      await HiveService.setLoggedIn(true);
      if (!mounted) return;
      context.read<ProfileBloc>().add(UpdateProfileEvent(name, email));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Registration completed successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Responsive.w(12)),
          ),
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (route) => false,
      );
    } else {
      Navigator.pop(context, {
        'name': name,
        'email': email,
      });
    }
  }

  Future<bool> _showExitConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Responsive.w(16)),
        ),
        title: CustomText.header('Exit App', fontSize: 18, fontWeight: FontWeight.bold),
        content: CustomText.title('Are you sure you want to exit the application?', fontSize: 14),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: CustomText.title('Cancel', color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: CustomText.title('Exit', color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      backgroundColor: AppColors.screenColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: Responsive.w(70),
        leading: Padding(
          padding: EdgeInsets.only(left: Responsive.w(20)),
          child: Center(
            child: GestureDetector(
              onTap: () async {
                if (widget.isRegistration) {
                  final shouldExit = await _showExitConfirmationDialog();
                  if (shouldExit) {
                    SystemNavigator.pop();
                  }
                } else {
                  Navigator.pop(context);
                }
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
          ),
        ),
        title: CustomText.header(
          widget.isRegistration ? 'Registration' : 'Edit Profile',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.black,
        ),
        centerTitle: false,
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
                        SizedBox(height: Responsive.h(20)),
                        // Square avatar with rounded corners and edit badge
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: Responsive.w(120),
                              height: Responsive.w(120),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(Responsive.w(28)),
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: Responsive.w(2),
                                ),
                                image: const DecorationImage(
                                  image: AssetImage('assets/images/avatar.png'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: -Responsive.w(8),
                              right: -Responsive.w(8),
                              child: Container(
                                padding: EdgeInsets.all(Responsive.w(6)),
                                decoration: const BoxDecoration(
                                  color: AppColors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: Icon(
                                  Icons.edit_outlined,
                                  color: AppColors.black,
                                  size: Responsive.w(18),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: Responsive.h(32)),

                        // Name input container
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
                            controller: _nameController,
                            style: TextStyle(
                              fontSize: Responsive.sp(15),
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Enter Name',
                            ),
                          ),
                        ),
                        SizedBox(height: Responsive.h(16)),

                        // Email input container
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(Responsive.w(16)),
                                border: Border.all(
                                  color: (_emailController.text.isNotEmpty && !_isValidEmail)
                                      ? AppColors.error
                                      : AppColors.outliner.withValues(alpha: 0.5),
                                  width: Responsive.w(1.2),
                                ),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: Responsive.w(16),
                                vertical: Responsive.h(4),
                              ),
                              child: TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(
                                  fontSize: Responsive.sp(15),
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.black,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Enter Email',
                                ),
                              ),
                            ),
                            if (_emailController.text.isNotEmpty && !_isValidEmail) ...[
                              SizedBox(height: Responsive.h(4)),
                              Padding(
                                padding: EdgeInsets.only(left: Responsive.w(8)),
                                child: CustomText.subtitle(
                                  'Please enter a valid email (e.g. name@example.com)',
                                  fontSize: 11,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Submit Button
                GestureDetector(
                  onTap: _submit,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    height: Responsive.h(50),
                    margin: EdgeInsets.only(bottom: Responsive.h(20)),
                    decoration: BoxDecoration(
                      color: _canSubmit ? AppColors.primary : const Color(0xFFF4EDE8),
                      borderRadius: BorderRadius.circular(Responsive.w(25)),
                      boxShadow: _canSubmit
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : null,
                    ),
                    child: Center(
                      child: CustomText.title(
                        widget.isRegistration ? 'Complete Registration' : 'Submit',
                        color: _canSubmit ? Colors.white : const Color(0xFFC0B3AC),
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

    if (widget.isRegistration) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final shouldExit = await _showExitConfirmationDialog();
          if (shouldExit) {
            SystemNavigator.pop();
          }
        },
        child: scaffold,
      );
    }
    return scaffold;
  }
}
