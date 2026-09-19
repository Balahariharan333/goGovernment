import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/rider_auth_bloc.dart';
import '../../bloc/auth/rider_auth_event.dart';
import '../../bloc/auth/rider_auth_state.dart';
import '../../constants/route_constants.dart';
import '../../utils/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widget/common_background.dart';
import '../../widget/custom_text.dart';

class RiderOtpScreen extends StatefulWidget {
  final String phone;
  final String? initialOtp;

  const RiderOtpScreen({
    super.key,
    required this.phone,
    this.initialOtp,
  });

  @override
  State<RiderOtpScreen> createState() => _RiderOtpScreenState();
}

class _RiderOtpScreenState extends State<RiderOtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    // OTP is not autofilled; the rider types the 4-digit code after seeing the notification.
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _enteredOtp => _controllers.map((c) => c.text).join();

  void _verifyOtp() {
    if (_enteredOtp.length == 4) {
      context.read<RiderAuthBloc>().add(
            VerifyRiderOtpEvent(
              phone: widget.phone,
              otp: _enteredOtp,
            ),
          );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete 4-digit OTP'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocConsumer<RiderAuthBloc, RiderAuthState>(
        listener: (context, state) {
          if (state is RiderProfilePendingState) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              RouteConstants.profileSetup,
              (route) => false,
            );
          } else if (state is RiderAuthSuccessState) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              RouteConstants.dashboard,
              (route) => false,
            );
          } else if (state is RiderAuthFailureState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is RiderAuthLoading;

          return CommonBackground(
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: Responsive.w(24)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: Responsive.h(20)),
                    CustomText.heading(
                      'Verify Mobile Number',
                      fontSize: Responsive.sp(22),
                      fontWeight: FontWeight.bold,
                    ),
                    SizedBox(height: Responsive.h(8)),
                    Row(
                      children: [
                        CustomText.body(
                          'Code sent to ',
                          fontSize: Responsive.sp(14),
                        ),
                        CustomText.title(
                          widget.phone,
                          fontSize: Responsive.sp(14),
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                    SizedBox(height: Responsive.h(36)),

                    // 4-Digit Input Boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(4, (index) {
                        return SizedBox(
                          width: Responsive.w(58),
                          height: Responsive.h(64),
                          child: TextFormField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: TextStyle(
                              fontSize: Responsive.sp(22),
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: AppColors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(Responsive.w(14)),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(Responsive.w(14)),
                                borderSide: const BorderSide(color: AppColors.primary, width: 2),
                              ),
                            ),
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: (value) {
                              if (value.isNotEmpty && index < 3) {
                                _focusNodes[index + 1].requestFocus();
                              } else if (value.isEmpty && index > 0) {
                                _focusNodes[index - 1].requestFocus();
                              }
                              if (_enteredOtp.length == 4) {
                                _verifyOtp();
                              }
                            },
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: Responsive.h(32)),

                    // Verify Button
                    SizedBox(
                      width: double.infinity,
                      height: Responsive.h(52),
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Responsive.w(14)),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Verify & Continue',
                                style: TextStyle(
                                  fontSize: Responsive.sp(16),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: Responsive.h(20)),

                    // Resend Link
                    Center(
                      child: TextButton(
                        onPressed: () {
                          context.read<RiderAuthBloc>().add(SendRiderOtpEvent(widget.phone));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('A new OTP has been sent!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                        child: CustomText.title(
                          'Resend OTP Code',
                          fontSize: Responsive.sp(14),
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
