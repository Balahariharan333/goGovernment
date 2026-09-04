import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widget/custom_text.dart';
import '../../bloc/profile/profile_bloc.dart';
import '../../constants/route_constants.dart';
import '../../bloc/report/report_bloc.dart';
import '../../bloc/report/report_state.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  Color _getStatusColor(dynamic colorVal, String? status) {
    if (colorVal is int) return Color(colorVal);
    if (colorVal is Color) return colorVal;
    switch ((status ?? '').toLowerCase()) {
      case 'resolved':
        return const Color(0xFF4CAF50);
      case 'in progress':
        return const Color(0xFFFF9100);
      default:
        return const Color(0xFFFF5252);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = context.watch<ProfileBloc>().state;
    final String name = profileState.name.trim();
    final bool hasName = name.isNotEmpty;
    final String greetingTitle = hasName ? '${_getGreeting()}, $name..' : '${_getGreeting()}! Welcome';
    final String greetingSubtitle = hasName
        ? 'Here are today\'s actions for you'
        : 'Tap your profile to set up your details';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Custom Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText.header(
                    greetingTitle,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: Responsive.h(4)),
                  CustomText.subtitle(
                    greetingSubtitle,
                    fontSize: 14,
                    color: AppColors.grayFont,
                  ),
                ],
              ),
            ),
            SizedBox(width: Responsive.w(12)),
            _buildNotificationBell(context),
          ],
        ),
        SizedBox(height: Responsive.h(24)),

        // 2. Action Grid (2x2)
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: Responsive.w(16),
          mainAxisSpacing: Responsive.w(16),
          childAspectRatio: 1.2,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed(RouteConstants.feedbackSurvey);
              },
              child: _buildActionCard(
                imagePath: 'assets/images/feedback.png',
                label: 'Near Feedback',
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed(RouteConstants.nearStores);
              },
              child: _buildActionCard(
                imagePath: 'assets/images/stores.png',
                label: 'Near Stores',
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed(RouteConstants.nearBusStop);
              },
              child: _buildActionCard(
                imagePath: 'assets/images/Bus.png',
                label: 'Near Bus Stop',
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed(RouteConstants.nearToilet);
              },
              child: _buildActionCard(
                imagePath: 'assets/images/toilet.png',
                label: 'Near Toilet',
              ),
            ),
          ],
        ),
        SizedBox(height: Responsive.h(28)),

        // 3. Active Complaint Section
        BlocBuilder<ReportBloc, ReportState>(
          builder: (context, reportState) {
            final myReports = reportState.myReports;

            // Empty state when user has no reports
            if (myReports.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText.header(
                    'Civic Complaints',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: Responsive.h(4)),
                  CustomText.subtitle(
                    'Track and resolve neighborhood issues',
                    fontSize: 13,
                    color: AppColors.grayFont,
                  ),
                  SizedBox(height: Responsive.h(16)),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(Responsive.w(28)),
                      border: Border.all(
                        color: AppColors.outliner,
                        width: Responsive.w(1.5),
                      ),
                    ),
                    padding: EdgeInsets.all(Responsive.w(20)),
                    child: Column(
                      children: [
                        Container(
                          width: Responsive.w(56),
                          height: Responsive.w(56),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF2EC),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.assignment_turned_in_outlined,
                            color: AppColors.primary,
                            size: Responsive.w(28),
                          ),
                        ),
                        SizedBox(height: Responsive.h(12)),
                        CustomText.title(
                          'No Active Complaints',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        SizedBox(height: Responsive.h(6)),
                        CustomText.body(
                          'Notice broken streetlights, potholes, or sanitation issues near your home? Submit a report to get it resolved.',
                          textAlign: TextAlign.center,
                          color: AppColors.grayFont,
                          fontSize: 12,
                        ),
                        SizedBox(height: Responsive.h(16)),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context)
                                .pushNamed(RouteConstants.addComplaint);
                          },
                          child: Container(
                            width: double.infinity,
                            height: Responsive.h(48),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius:
                                  BorderRadius.circular(Responsive.w(24)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add,
                                    color: Colors.white,
                                    size: Responsive.w(20)),
                                SizedBox(width: Responsive.w(8)),
                                const Text(
                                  'File a Complaint',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            final Map<String, dynamic> latestReport = myReports.first;
            final String category = latestReport['category'] ?? 'Road Damage';
            final String reportId = latestReport['id']?.toString() ?? 'CMP000000';
            final String description = latestReport['description'] ?? '';
            final String address = latestReport['userAddress'] ?? 'No address provided';
            final String status = latestReport['status'] ?? 'Under Review';
            final Color statusColor =
                _getStatusColor(latestReport['statusColor'], status);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText.header(
                            category,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          SizedBox(height: Responsive.h(4)),
                          CustomText.subtitle(
                            'ID: $reportId',
                            fontSize: 13,
                            color: AppColors.grayFont,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: Responsive.w(12)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.w(12),
                        vertical: Responsive.h(5),
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(Responsive.w(12)),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.h(16)),

                // 4. Detail Info Card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(Responsive.w(28)),
                    border: Border.all(
                      color: AppColors.outliner,
                      width: Responsive.w(1.5),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.w(16),
                    vertical: Responsive.h(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text box container (grey bubble)
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(Responsive.w(16)),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.w(16),
                          vertical: Responsive.h(14),
                        ),
                        child: CustomText.body(
                          description,
                          color: const Color(0xFF4A4A4A),
                          height: 1.35,
                        ),
                      ),
                      SizedBox(height: Responsive.h(14)),
                      // Location detail row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: Responsive.w(42),
                            height: Responsive.h(42),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFF2EC),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.location_on_outlined,
                              color: AppColors.primary,
                              size: Responsive.w(20),
                            ),
                          ),
                          SizedBox(width: Responsive.w(12)),
                          Expanded(
                            child: CustomText.subtitle(
                              address,
                              fontSize: 13,
                              color: const Color(0xFF333333),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: Responsive.h(14)),
                      // View Status & Overlapping Floating Button
                      Stack(
                        alignment: Alignment.centerLeft,
                        clipBehavior: Clip.none,
                        children: [
                          FractionallySizedBox(
                            widthFactor: 0.86,
                            child: Container(
                              height: Responsive.h(52),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius:
                                    BorderRadius.circular(Responsive.w(26)),
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: Responsive.w(1.5),
                                ),
                              ),
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).pushNamed(
                                    RouteConstants.complaintDetails,
                                    arguments: {
                                      'report': latestReport,
                                      'userName': latestReport['userName'] ??
                                          (name.isNotEmpty ? name : 'Citizen'),
                                      'status': status,
                                      'statusColor': statusColor,
                                      'category': category,
                                      'description': description,
                                      'id': reportId,
                                      'imagePath': latestReport['imagePath'],
                                      'userAddress': address,
                                      'date': latestReport['date'] ?? 'Today',
                                    },
                                  );
                                },
                                borderRadius:
                                    BorderRadius.circular(Responsive.w(26)),
                                child: Center(
                                  child: CustomText.title(
                                    'View Status',
                                    color: AppColors.black,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context)
                                    .pushNamed(RouteConstants.addComplaint);
                              },
                              child: Container(
                                width: Responsive.w(54),
                                height: Responsive.h(54),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius:
                                      BorderRadius.circular(Responsive.w(20)),
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: Responsive.w(1.5),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      blurRadius: Responsive.w(8),
                                      offset: Offset(0, Responsive.h(4)),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.add,
                                  color: AppColors.primary,
                                  size: Responsive.w(32),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildNotificationBell(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(RouteConstants.notification);
      },
      child: Container(
        padding: EdgeInsets.all(Responsive.w(10)),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(Responsive.w(14)),
          border: Border.all(
            color: AppColors.outliner,
            width: Responsive.w(1.5),
          ),
        ),
        child: Icon(
          Icons.notifications_outlined,
          color: AppColors.black,
          size: Responsive.w(26),
        ),
      ),
    );
  }

  Widget _buildActionCard({required String imagePath, required String label}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Responsive.w(28)),
        border: Border.all(color: AppColors.outliner, width: Responsive.w(1.5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            imagePath,
            width: Responsive.w(40),
            height: Responsive.w(40),
            fit: BoxFit.contain,
          ),
          SizedBox(height: Responsive.h(12)),
          CustomText.title(
            label,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ],
      ),
    );
  }
}
