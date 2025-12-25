import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/providers/donation_provider.dart';
import '../../../data/models/donation_model.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/cards.dart';

class DonationHistoryScreen extends ConsumerWidget {
  const DonationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donationsAsync = ref.watch(userDonationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.donationHistory)),
      body: donationsAsync.when(
        loading: () => const ShimmerList(),
        error: (error, _) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.refresh(userDonationsProvider),
        ),
        data: (donations) {
          if (donations.isEmpty) {
            return const EmptyState(
              icon: Icons.volunteer_activism,
              title: 'No Donations Yet',
              subtitle: 'Your donation history will appear here',
            );
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            itemCount: donations.length,
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: true,
            cacheExtent: 500,
            itemBuilder: (context, index) {
              final donation = donations[index];
              return _DonationCard(donation: donation);
            },
          );
        },
      ),
    );
  }
}

class _DonationCard extends StatelessWidget {
  final Donation donation;

  const _DonationCard({required this.donation});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.water_drop,
                    color: AppColors.primary,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donation.recipientName,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        donation.hospitalName,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  status: donation.isVerified ? 'verified' : 'pending',
                ),
              ],
            ),
            SizedBox(height: 12.h),
            const Divider(height: 1),
            SizedBox(height: 12.h),
            Row(
              children: [
                _buildInfoItem(
                  Icons.calendar_today,
                  donation.donationDate.formattedDate,
                ),
                SizedBox(width: 24.w),
                _buildInfoItem(
                  Icons.water_drop_outlined,
                  '${donation.units} units',
                ),
                SizedBox(width: 24.w),
                _buildInfoItem(Icons.bloodtype, donation.bloodGroup),
              ],
            ),
            if (donation.notes != null && donation.notes!.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note,
                      size: 16.sp,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        donation.notes!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.sp, color: AppColors.textSecondary),
        SizedBox(width: 4.w),
        Text(
          text,
          style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
