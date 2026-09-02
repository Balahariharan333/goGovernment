import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widget/custom_text.dart';
import 'edit_profile_screen.dart';
import 'edit_phone_screen.dart';
import 'address_book_screen.dart';
import 'wishlist_screen.dart';
import 'language_screen.dart';
import '../auth/login_screen.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/profile/profile_bloc.dart';
import '../../bloc/profile/profile_event.dart';
import '../../bloc/profile/profile_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Responsive.w(28)),
          ),
          child: Padding(
            padding: EdgeInsets.all(Responsive.w(24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText.header(
                  'Are you sure you want to log out of your account?',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  textAlign: TextAlign.center,
                  height: 1.4,
                ),
                SizedBox(height: Responsive.h(24)),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: Responsive.h(44),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(Responsive.w(22)),
                            border: Border.all(
                              color: AppColors.grayFont.withValues(alpha: 0.5),
                              width: Responsive.w(1.2),
                            ),
                          ),
                          child: Center(
                            child: CustomText.title(
                              'Cancel',
                              color: AppColors.grayFont,
                              fontSize: 14,
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
                          context.read<AuthBloc>().add(LogoutEvent());
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Logged out successfully!'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(Responsive.w(12)),
                              ),
                            ),
                          );
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        child: Container(
                          height: Responsive.h(44),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(Responsive.w(22)),
                            border: Border.all(
                              color: AppColors.primary,
                              width: Responsive.w(1.2),
                            ),
                          ),
                          child: Center(
                            child: CustomText.title(
                              'Log Out',
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Responsive.w(28)),
          ),
          child: Padding(
            padding: EdgeInsets.all(Responsive.w(24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText.header(
                  'Are you sure you want to delete your account?',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  textAlign: TextAlign.center,
                  height: 1.4,
                ),
                SizedBox(height: Responsive.h(24)),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: Responsive.h(44),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(Responsive.w(22)),
                            border: Border.all(
                              color: AppColors.grayFont.withValues(alpha: 0.5),
                              width: Responsive.w(1.2),
                            ),
                          ),
                          child: Center(
                            child: CustomText.title(
                              'Cancel',
                              color: AppColors.grayFont,
                              fontSize: 14,
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
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Account deleted successfully!'),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(Responsive.w(12)),
                              ),
                            ),
                          );
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        child: Container(
                          height: Responsive.h(44),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(Responsive.w(22)),
                            border: Border.all(
                              color: AppColors.error,
                              width: Responsive.w(1.2),
                            ),
                          ),
                          child: Center(
                            child: CustomText.title(
                              'Delete Account',
                              color: AppColors.error,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        final String name = state.name;
        final String email = state.email;
        final String phone = state.phone;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Full width curved header with reserved layout height
            SizedBox(
              height: Responsive.h(244),
              child: Transform.translate(
                offset: Offset(0, -Responsive.h(16)),
                child: OverflowBox(
                  maxWidth: screenWidth,
                  minWidth: screenWidth,
                  child: Container(
                    width: screenWidth,
                    height: Responsive.h(260),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.outliner, // Lighter peach/orange on the left
                          AppColors.primary,  // Darker orange-red on the right
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(Responsive.w(36)),
                        bottomRight: Radius.circular(Responsive.w(36)),
                      ),
                    ),
                    padding: EdgeInsets.only(
                      top: Responsive.h(16),
                      left: Responsive.w(20),
                      right: Responsive.w(20),
                    ),
                    child: Column(
                      children: [
                        // App bar items
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomText.header(
                              'Profile',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            // Rounded Edit Profile button
                            GestureDetector(
                              onTap: () async {
                                final res = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditProfileScreen(
                                      initialName: name,
                                      initialEmail: email,
                                    ),
                                  ),
                                );
                                 if (res != null && res is Map<String, String>) {
                                  if (!context.mounted) return;
                                  context.read<ProfileBloc>().add(
                                        UpdateProfileEvent(
                                          res['name']!,
                                          res['email']!,
                                        ),
                                      );
                                }
                              },
                              child: Container(
                                width: Responsive.w(40),
                                height: Responsive.w(40),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(Responsive.w(12)),
                                ),
                                child: Icon(
                                  Icons.edit_outlined,
                                  color: AppColors.black,
                                  size: Responsive.w(20),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: Responsive.h(10)),
                        // Avatar and Suriyaprakash Info
                        Container(
                          width: Responsive.w(80),
                          height: Responsive.w(80),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.white,
                              width: Responsive.w(2),
                            ),
                            image: const DecorationImage(
                              image: AssetImage('assets/images/avatar.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(height: Responsive.h(10)),
                        CustomText.header(
                          name,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        SizedBox(height: Responsive.h(2)),
                        CustomText.subtitle(
                          email,
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: Responsive.h(12)),

            // Menu Options list
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildProfileOption(
                      icon: Icons.phone_outlined,
                      title: phone,
                      onTap: () async {
                        final res = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditPhoneScreen(
                              initialPhone: phone,
                            ),
                          ),
                        );
                        if (res != null && res is String) {
                          if (!context.mounted) return;
                          context.read<ProfileBloc>().add(UpdatePhoneEvent(res));
                        }
                      },
                    ),
                    SizedBox(height: Responsive.h(10)),
                    _buildProfileOption(
                      icon: Icons.map_outlined,
                      title: 'Address Book',
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddressBookScreen(),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: Responsive.h(6)),
                    _buildProfileOption(
                      icon: Icons.favorite_outline,
                      title: 'Wishlist',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WishlistScreen(),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: Responsive.h(6)),
                    _buildProfileOption(
                      icon: Icons.translate_outlined,
                      title: 'Language',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LanguageScreen(),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: Responsive.h(6)),
                    _buildProfileOption(
                      icon: Icons.star_outline,
                      title: 'Rate Us',
                      onTap: () {},
                    ),
                    SizedBox(height: Responsive.h(6)),
                    _buildProfileOption(
                      icon: Icons.logout_outlined,
                      title: 'Logout',
                      onTap: () => _showLogoutDialog(context),
                    ),
                    SizedBox(height: Responsive.h(6)),
                    _buildProfileOption(
                      icon: Icons.delete_outline,
                      title: 'Delete',
                      onTap: () => _showDeleteDialog(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    Color color = AppColors.black,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: Responsive.w(20), vertical: Responsive.h(16)),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(Responsive.w(20)),
          border: Border.all(color: AppColors.outliner, width: Responsive.w(1.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: Responsive.w(24)),
                SizedBox(width: Responsive.w(16)),
                CustomText.title(title, fontSize: 15, color: color, fontWeight: FontWeight.w500),
              ],
            ),
            Icon(Icons.chevron_right_outlined, color: color.withValues(alpha: 0.5), size: Responsive.w(24)),
          ],
        ),
      ),
    );
  }
}
