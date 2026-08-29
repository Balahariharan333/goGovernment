import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/responsive_helper.dart';
import '../../../widget/common_background.dart';
import '../../../widget/custom_text.dart';
import '../../../bloc/feedback/feedback_bloc.dart';
import '../../../bloc/feedback/feedback_event.dart';
import '../../../bloc/feedback/feedback_state.dart';

class FeedbackSurveyScreen extends StatefulWidget {
  const FeedbackSurveyScreen({super.key});

  @override
  State<FeedbackSurveyScreen> createState() => _FeedbackSurveyScreenState();
}

class _FeedbackSurveyScreenState extends State<FeedbackSurveyScreen> {
  final List<Map<String, dynamic>> _surveyData = [
    {
      'question': '1. How would you rate the road condition near your home?',
      'options': ['Excellent', 'Good', 'Poor', 'Very Poor'],
    },
    {
      'question': '2. How often is garbage collected in your area?',
      'options': ['Daily', 'Alternate Days', 'Weekly', 'Rarely'],
    },
    {
      'question': '3. Are streetlights working properly in your locality?',
      'options': ['All Working', 'Most Working', 'Few Working', 'Not Working'],
    },
    {
      'question': '4. How clean are the streets near your home?',
      'options': ['Very Clean', 'Clean', 'Average', 'Dirty'],
    },
  ];

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
          'Feedback Survey',
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: false,
      ),
      body: BlocBuilder<FeedbackBloc, FeedbackState>(
        builder: (context, state) {
          final int q1Selected = state.q1Selected;
          final int q2Selected = state.q2Selected;
          final int q3Selected = state.q3Selected;
          final int q4Selected = state.q4Selected;

          int getSelectedOption(int questionIndex) {
            if (questionIndex == 0) return q1Selected;
            if (questionIndex == 1) return q2Selected;
            if (questionIndex == 2) return q3Selected;
            if (questionIndex == 3) return q4Selected;
            return -1;
          }

          return CommonBackground(
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      margin: EdgeInsets.fromLTRB(
                        Responsive.w(16),
                        Responsive.h(8),
                        Responsive.w(16),
                        Responsive.h(16),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(Responsive.w(24)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(Responsive.w(24)),
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.w(18),
                            vertical: Responsive.h(18),
                          ),
                          itemCount: _surveyData.length + 1, // Add 1 for the Submit button
                          itemBuilder: (context, index) {
                            if (index == _surveyData.length) {
                              return _buildSubmitButton(context, q1Selected, q2Selected, q3Selected, q4Selected);
                            }

                            final questionItem = _surveyData[index];
                            final String questionText = questionItem['question'];
                            final List<String> options = questionItem['options'];
                            final int selectedIndex = getSelectedOption(index);

                            return Padding(
                              padding: EdgeInsets.only(bottom: Responsive.h(24)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText.title(
                                    questionText,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.black,
                                    height: 1.35,
                                  ),
                                  SizedBox(height: Responsive.h(14)),
                                  Column(
                                    children: List.generate(options.length, (optIdx) {
                                      final bool isSelected = selectedIndex == optIdx;
                                      return GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () {
                                          context.read<FeedbackBloc>().add(
                                                SelectOptionEvent(index, optIdx),
                                              );
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.only(bottom: Responsive.h(12)),
                                          child: Row(
                                            children: [
                                              // Custom radio selector indicator
                                              Container(
                                                width: Responsive.w(18),
                                                height: Responsive.w(18),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: isSelected
                                                      ? AppColors.primary
                                                      : const Color(0xFFF5F5F5),
                                                ),
                                              ),
                                              SizedBox(width: Responsive.w(12)),
                                              Expanded(
                                                child: CustomText.body(
                                                  options[optIdx],
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context, int q1, int q2, int q3, int q4) {
    return Padding(
      padding: EdgeInsets.only(top: Responsive.h(10), bottom: Responsive.h(20)),
      child: GestureDetector(
        onTap: () {
          if (q1 == -1 || q2 == -1 || q3 == -1 || q4 == -1) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Please answer all questions before submitting.'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Responsive.w(12)),
                ),
              ),
            );
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Feedback submitted successfully!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Responsive.w(12)),
              ),
            ),
          );
          context.read<FeedbackBloc>().add(SubmitFeedbackEvent());
          Navigator.pop(context);
        },
        child: Container(
          width: double.infinity,
          height: Responsive.h(50),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(Responsive.w(25)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: CustomText.title(
              'Submit Feedback',
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
