import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widget/custom_text.dart';
import 'complaint_details_screen.dart';
import '../home/notification/notification_screen.dart';
import '../../bloc/report/report_bloc.dart';
import '../../bloc/report/report_event.dart';
import '../../bloc/report/report_state.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  // Mock list of reports
  final List<Map<String, dynamic>> _myActivityReports = [
    {
      'userName': 'Ramesh',
      'userAddress': '552, 2nd Floor 16th Main, 15th Cross Rd, 4th Sector, HSR Layout, Bengaluru, Karnataka 560102',
      'id': 'ertyuiohgf',
      'category': 'Road Damage',
      'description': 'The road is completely damaged and it is difficult for us to ride our vehicles safely. Kindly repair the road and resolve this issue as soon as possible.',
      'status': 'Under Review',
      'statusColor': const Color(0xFFFF5252),
    },
    {
      'userName': 'Ramesh',
      'userAddress': '552, 2nd Floor 16th Main, 15th Cross Rd, 4th Sector, HSR Layout, Bengaluru, Karnataka 560102',
      'id': 'ertyuiohgf',
      'category': 'Road Damage',
      'description': 'The road is completely damaged and it is difficult for us to ride our vehicles safely. Kindly repair the road and resolve this issue as soon as possible.',
      'status': 'In Progress',
      'statusColor': const Color(0xFFFF9100),
    },
    {
      'userName': 'Ramesh',
      'userAddress': '552, 2nd Floor 16th Main, 15th Cross Rd, 4th Sector, HSR Layout, Bengaluru, Karnataka 560102',
      'id': 'ertyuiohgf',
      'category': 'Road Damage',
      'description': 'The road is completely damaged and it is difficult for us to ride our vehicles safely. Kindly repair the road and resolve this issue as soon as possible.',
      'status': 'Resolved',
      'statusColor': const Color(0xFF4CAF50),
    },
  ];

  final List<Map<String, dynamic>> _otherActivityReports = [
    {
      'userName': 'Suresh Kumar',
      'userAddress': '124, 5th Cross Rd, 1st Sector, HSR Layout, Bengaluru, Karnataka 560102',
      'id': 'lkjhgfdsa1',
      'category': 'Streetlight Outage',
      'description': 'The streetlights in this area are not working properly, making it difficult for residents to walk safely at night. Kindly inspect and resolve the issue.',
      'status': 'Under Review',
      'statusColor': const Color(0xFFFF5252),
    },
    {
      'userName': 'Mahesh Hegde',
      'userAddress': '78, 19th Main Rd, 3rd Sector, HSR Layout, Bengaluru, Karnataka 560102',
      'id': 'poiuytrew2',
      'category': 'Garbage & Waste',
      'description': 'Garbage has not been cleared for the last three days. It smells terrible and is attracting stray dogs. Please resolve this immediately.',
      'status': 'In Progress',
      'statusColor': const Color(0xFFFF9100),
    },
    {
      'userName': 'Ganesh Prasad',
      'userAddress': '411, 24th Cross Rd, HSR Layout, Bengaluru, Karnataka 560102',
      'id': 'mnbvcxzlk3',
      'category': 'Drainage Overflow',
      'description': 'Sewer water is leaking onto the main road near the school boundary. Please send clean-up crews and fix the blockage.',
      'status': 'Resolved',
      'statusColor': const Color(0xFF4CAF50),
    },
  ];

  List<Map<String, dynamic>> _filteredReports(bool isMyActivity, String selectedFilter) {
    final baseList = isMyActivity ? _myActivityReports : _otherActivityReports;
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
        final filteredList = _filteredReports(isMyActivity, selectedFilter);

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
                _buildNotificationBell(),
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationScreen(),
          ),
        );
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

  Widget _buildReportCard(BuildContext context, Map<String, dynamic> report) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ComplaintDetailsScreen(
              userName: report['userName'],
              status: report['status'],
              statusColor: report['statusColor'],
            ),
          ),
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
                        report['userName'],
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      SizedBox(height: Responsive.h(2)),
                      CustomText.subtitle(
                        report['userAddress'],
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
              'ID: ${report['id']}',
              fontSize: 11,
              color: AppColors.grayFont,
            ),
            SizedBox(height: Responsive.h(6)),

            // Category
            CustomText.title(
              report['category'],
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            SizedBox(height: Responsive.h(4)),

            // Description
            CustomText.body(
              report['description'],
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
                    text: report['status'],
                    style: TextStyle(
                      color: report['statusColor'],
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
                Icon(Icons.thumb_up_outlined,
                    size: Responsive.w(16), color: AppColors.grayFont),
                SizedBox(width: Responsive.w(4)),
                CustomText.subtitle('0', fontSize: 12, color: AppColors.grayFont),
                SizedBox(width: Responsive.w(20)),
                Icon(Icons.chat_bubble_outline,
                    size: Responsive.w(16), color: AppColors.grayFont),
                SizedBox(width: Responsive.w(4)),
                CustomText.subtitle('0', fontSize: 12, color: AppColors.grayFont),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
