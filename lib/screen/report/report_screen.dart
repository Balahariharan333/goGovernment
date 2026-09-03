import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widget/custom_text.dart';
import '../../constants/route_constants.dart';
import '../../bloc/report/report_bloc.dart';
import '../../bloc/report/report_event.dart';
import '../../bloc/report/report_state.dart';
import '../../hive/hive_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ReportBloc>().add(LoadReportsEvent());
  }

  Color _getStatusColor(dynamic rawColor, String? status) {
    if (rawColor is Color) return rawColor;
    if (rawColor is int) return Color(rawColor);
    switch (status) {
      case 'Under Review':
        return const Color(0xFFFF5252);
      case 'In Progress':
        return const Color(0xFFFF9100);
      case 'Resolved':
        return const Color(0xFF4CAF50);
      default:
        return AppColors.primary;
    }
  }

  List<Map<String, dynamic>> _filteredReports(
    bool isMyActivity,
    String selectedFilter,
    List<Map<String, dynamic>> myReports,
    List<Map<String, dynamic>> otherReports,
  ) {
    final baseList = isMyActivity ? myReports : otherReports;
    if (selectedFilter == 'All') {
      return baseList;
    }
    return baseList.where((report) => report['status'] == selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportBloc, ReportState>(
      builder: (context, state) {
        final bool isMyActivity = state.isMyActivity;
        final String selectedFilter = state.selectedFilter;
        final filteredList = _filteredReports(
          isMyActivity,
          selectedFilter,
          state.myReports,
          state.otherReports,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. App Bar Header Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText.header(
                      'Reports',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    SizedBox(height: Responsive.h(4)),
                    CustomText.subtitle(
                      'Track and review citizen filings',
                      fontSize: 14,
                      color: AppColors.grayFont,
                    ),
                  ],
                ),
                Row(
                  children: [
                    // if (isMyActivity && state.myReports.isNotEmpty) ...[
                    //   GestureDetector(
                    //     onTap: () => _showClearComplaintsDialog(context),
                    //     child: Container(
                    //       padding: EdgeInsets.all(Responsive.w(10)),
                    //       decoration: BoxDecoration(
                    //         color: AppColors.white,
                    //         borderRadius:
                    //             BorderRadius.circular(Responsive.w(14)),
                    //         border: Border.all(
                    //           color: AppColors.error.withValues(alpha: 0.3),
                    //           width: Responsive.w(1.2),
                    //         ),
                    //       ),
                    //       child: Icon(
                    //         Icons.delete_sweep_outlined,
                    //         color: AppColors.error,
                    //         size: Responsive.w(22),
                    //       ),
                    //     ),
                    //   ),
                    //   SizedBox(width: Responsive.w(8)),
                    // ],
                    _buildNotificationBell(),
                  ],
                ),
              ],
            ),
            SizedBox(height: Responsive.h(20)),

            // 2. Custom Double-Tab Capsule Bar
            Container(
              width: double.infinity,
              height: Responsive.h(50),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2EC), // Peach background capsule
                borderRadius: BorderRadius.circular(Responsive.w(16)),
              ),
              padding: EdgeInsets.all(Responsive.w(4)),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        context.read<ReportBloc>().add(ToggleActivityTypeEvent(true));
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isMyActivity ? AppColors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(Responsive.w(12)),
                          border: isMyActivity
                              ? Border.all(color: AppColors.primary, width: Responsive.w(1.5))
                              : null,
                        ),
                        child: Center(
                          child: CustomText.title(
                            'My Activity',
                            color: isMyActivity ? AppColors.primary : AppColors.grayFont,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        context.read<ReportBloc>().add(ToggleActivityTypeEvent(false));
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: !isMyActivity ? AppColors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(Responsive.w(12)),
                          border: !isMyActivity
                              ? Border.all(color: AppColors.primary, width: Responsive.w(1.5))
                              : null,
                        ),
                        child: Center(
                          child: CustomText.title(
                            'Other Activity',
                            color: !isMyActivity ? AppColors.primary : AppColors.grayFont,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Responsive.h(20)),

            // 3. Horizontal Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildFilterChip(context, 'All', selectedFilter),
                  SizedBox(width: Responsive.w(10)),
                  _buildFilterChip(context, 'Under Review', selectedFilter),
                  SizedBox(width: Responsive.w(10)),
                  _buildFilterChip(context, 'In Progress', selectedFilter),
                  SizedBox(width: Responsive.w(10)),
                  _buildFilterChip(context, 'Resolved', selectedFilter),
                ],
              ),
            ),
            SizedBox(height: Responsive.h(20)),

            // 4. List of report cards
            if (filteredList.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: Responsive.h(40)),
                  child: CustomText.subtitle(
                    'No activity found',
                    fontSize: 14,
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final report = filteredList[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: Responsive.h(16)),
                    child: _buildReportCard(context, report),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationBell() {
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

  Widget _buildFilterChip(BuildContext context, String label, String selectedFilter) {
    final bool isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () {
        context.read<ReportBloc>().add(ChangeReportFilterEvent(label));
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.w(16),
          vertical: Responsive.h(8),
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.black : AppColors.white,
          borderRadius: BorderRadius.circular(Responsive.w(20)),
          border: Border.all(
            color: isSelected ? AppColors.black : AppColors.outliner,
            width: Responsive.w(1.5),
          ),
        ),
        child: CustomText.title(
          label,
          color: isSelected ? AppColors.white : AppColors.black,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showCommentsBottomSheet(BuildContext context, Map<String, dynamic> report) {
    final TextEditingController commentController = TextEditingController();
    final String reportId = report['id']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return BlocBuilder<ReportBloc, ReportState>(
          builder: (ctx, state) {
            final allReports = [...state.myReports, ...state.otherReports];
            final liveReport = allReports.firstWhere(
              (r) => r['id'] == reportId,
              orElse: () => report,
            );
            final List<dynamic> comments = List.from(liveReport['comments'] ?? []);

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                height: Responsive.h(480),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(Responsive.w(24)),
                  ),
                ),
                padding: EdgeInsets.all(Responsive.w(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: Responsive.w(40),
                        height: Responsive.h(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    SizedBox(height: Responsive.h(16)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomText.header(
                          'Comments (${comments.length})',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(bottomSheetContext),
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: comments.isEmpty
                          ? Center(
                              child: CustomText.subtitle(
                                'No comments yet. Be the first to comment!',
                                color: AppColors.grayFont,
                                fontSize: 13,
                              ),
                            )
                          : ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              itemCount: comments.length,
                              separatorBuilder: (context, index) => SizedBox(height: Responsive.h(12)),
                              itemBuilder: (context, index) {
                                final c = comments[index] is Map ? comments[index] as Map : {};
                                return Container(
                                  padding: EdgeInsets.all(Responsive.w(12)),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9F6F4),
                                    borderRadius: BorderRadius.circular(Responsive.w(12)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          CustomText.title(
                                            c['userName']?.toString() ?? 'Citizen',
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          CustomText.subtitle(
                                            c['date']?.toString() ?? 'Just now',
                                            fontSize: 10,
                                            color: AppColors.grayFont,
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: Responsive.h(4)),
                                      CustomText.body(
                                        c['comment']?.toString() ?? '',
                                        fontSize: 12,
                                        color: AppColors.black,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    SizedBox(height: Responsive.h(12)),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(Responsive.w(20)),
                              border: Border.all(
                                color: AppColors.outliner,
                                width: 1,
                              ),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: Responsive.w(16)),
                            child: TextField(
                              controller: commentController,
                              style: TextStyle(fontSize: Responsive.sp(14)),
                              decoration: const InputDecoration(
                                hintText: 'Write a comment...',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: Responsive.w(8)),
                        GestureDetector(
                          onTap: () {
                            final text = commentController.text.trim();
                            if (text.isNotEmpty) {
                              final profileName = HiveService.userName.isNotEmpty
                                  ? HiveService.userName
                                  : 'You';
                              context.read<ReportBloc>().add(
                                    AddCommentToReportEvent(
                                      reportId,
                                      text,
                                      userName: profileName,
                                    ),
                                  );
                              commentController.clear();
                            }
                          },
                          child: Container(
                            width: Responsive.w(44),
                            height: Responsive.w(44),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 18,
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
      },
    );
  }

  Widget _buildReportCard(BuildContext context, Map<String, dynamic> report) {
    final String reportId = report['id']?.toString() ?? '';
    final bool isLiked = report['isLiked'] == true;
    final int likesCount = (report['likesCount'] as num?)?.toInt() ?? 0;
    final List<dynamic> comments = List.from(report['comments'] ?? []);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          RouteConstants.complaintDetails,
          arguments: {
            'report': report,
            'userName': report['userName'] ?? 'User',
            'status': report['status'] ?? 'Under Review',
            'statusColor': _getStatusColor(report['statusColor'], report['status']),
            'category': report['category'] ?? 'Road Damage',
            'description': report['description'] ?? '',
            'id': reportId,
            'imagePath': report['imagePath'],
            'userAddress': report['userAddress'],
            'date': report['date'],
          },
        );
      },
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info row
            Row(
              children: [
                Container(
                  width: Responsive.w(38),
                  height: Responsive.w(38),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: AssetImage('assets/images/avatar.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: Responsive.w(10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText.title(
                        report['userName'] ?? 'User',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      SizedBox(height: Responsive.h(2)),
                      CustomText.subtitle(
                        report['userAddress'] ?? 'HSR Layout, Bengaluru',
                        fontSize: 10,
                        color: AppColors.grayFont,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.h(12)),

            // ID
            CustomText.subtitle(
              'ID: ${report['id'] ?? 'N/A'}',
              fontSize: 11,
              color: AppColors.grayFont,
            ),
            SizedBox(height: Responsive.h(6)),

            // Category
            CustomText.title(
              report['category'] ?? 'Road Damage',
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            SizedBox(height: Responsive.h(4)),

            // Description
            CustomText.body(
              report['description'] ?? '',
              fontSize: 12,
              color: Colors.grey.shade600,
              maxLines: 2,
            ),
            SizedBox(height: Responsive.h(10)),

            // Status line
            RichText(
              text: TextSpan(
                text: 'Status: ',
                style: TextStyle(
                  fontSize: Responsive.sp(12),
                  color: AppColors.black,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(
                    text: report['status'] ?? 'Under Review',
                    style: TextStyle(
                      color: _getStatusColor(report['statusColor'], report['status']),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Responsive.h(12)),

            // Divider
            Divider(color: Colors.grey.shade200, height: 1),
            SizedBox(height: Responsive.h(10)),

            // Like + Comment row
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (reportId.isNotEmpty) {
                      context.read<ReportBloc>().add(ToggleLikeReportEvent(reportId));
                    }
                  },
                  child: Row(
                    children: [
                      Icon(
                        isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                        size: Responsive.w(16),
                        color: isLiked ? AppColors.primary : AppColors.grayFont,
                      ),
                      SizedBox(width: Responsive.w(4)),
                      CustomText.subtitle(
                        '$likesCount',
                        fontSize: 12,
                        color: isLiked ? AppColors.primary : AppColors.grayFont,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: Responsive.w(20)),
                GestureDetector(
                  onTap: () => _showCommentsBottomSheet(context, report),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: Responsive.w(16),
                        color: AppColors.grayFont,
                      ),
                      SizedBox(width: Responsive.w(4)),
                      CustomText.subtitle(
                        '${comments.length}',
                        fontSize: 12,
                        color: AppColors.grayFont,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
