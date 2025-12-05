import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/extensions.dart';
import '../../data/models/blood_request_model.dart';
import '../../data/models/user_model.dart';
import '../../data/models/donation_model.dart';

/// Blood request card widget
class RequestCard extends StatelessWidget {
  final BloodRequest request;
  final VoidCallback? onTap;
  final double? distance;
  final bool showActions;

  const RequestCard({
    super.key,
    required this.request,
    this.onTap,
    this.distance,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Blood group badge
                  BloodGroupBadge(bloodGroup: request.bloodGroup, size: 48),
                  SizedBox(width: 12.w),
                  // Request info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (request.isEmergency || request.isSOS)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 2.h,
                                ),
                                margin: EdgeInsets.only(right: 8.w),
                                decoration: BoxDecoration(
                                  color: request.isSOS
                                      ? AppColors.sos
                                      : AppColors.emergency,
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Text(
                                  request.isSOS ? 'SOS' : 'EMERGENCY',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                request.patientName,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          request.hospitalName,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Urgency indicator
                  UrgencyBadge(urgency: request.urgencyLevel),
                ],
              ),
              SizedBox(height: 12.h),
              // Details row
              Row(
                children: [
                  _buildDetailChip(
                    Icons.water_drop,
                    '${request.unitsRequired} Units',
                  ),
                  SizedBox(width: 12.w),
                  _buildDetailChip(
                    Icons.access_time,
                    request.requiredBy.formattedDate,
                  ),
                  if (distance != null) ...[
                    SizedBox(width: 12.w),
                    _buildDetailChip(Icons.location_on, distance!.asDistance),
                  ],
                ],
              ),
              SizedBox(height: 8.h),
              // Status and time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StatusBadge(status: request.status),
                  Text(
                    request.createdAt.timeAgo,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text) {
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

/// Donor card widget
class DonorCard extends StatelessWidget {
  final UserModel donor;
  final VoidCallback? onTap;
  final double? distance;

  const DonorCard({super.key, required this.donor, this.onTap, this.distance});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // Profile image
              UserAvatar(
                imageUrl: donor.profileImageUrl,
                name: donor.name,
                size: 56,
              ),
              SizedBox(width: 12.w),
              // Donor info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donor.name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        if (donor.city != null) ...[
                          Icon(
                            Icons.location_on_outlined,
                            size: 14.sp,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            donor.city!,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (distance != null) ...[
                          SizedBox(width: 12.w),
                          Text(
                            distance!.asDistance,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.volunteer_activism,
                          size: 14.sp,
                          color: AppColors.success,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${donor.totalDonations} donations',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Blood group badge
              BloodGroupBadge(bloodGroup: donor.bloodGroup),
            ],
          ),
        ),
      ),
    );
  }
}

/// Donation history card
class DonationCard extends StatelessWidget {
  final Donation donation;
  final VoidCallback? onTap;

  const DonationCard({super.key, required this.donation, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // Blood group badge
              BloodGroupBadge(bloodGroup: donation.bloodGroup),
              SizedBox(width: 12.w),
              // Donation info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Donated to ${donation.recipientName}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      donation.hospitalName,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      donation.donationDate.formattedDate,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              // Units
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '${donation.units} units',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Blood group badge widget
class BloodGroupBadge extends StatelessWidget {
  final String bloodGroup;
  final double? size;

  const BloodGroupBadge({super.key, required this.bloodGroup, this.size});

  @override
  Widget build(BuildContext context) {
    final badgeSize = size ?? 40.0;

    return Container(
      width: badgeSize.w,
      height: badgeSize.h,
      decoration: BoxDecoration(
        color: AppColors.getBloodGroupColor(bloodGroup).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: AppColors.getBloodGroupColor(bloodGroup),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          bloodGroup,
          style: TextStyle(
            fontSize: (badgeSize * 0.35).sp,
            fontWeight: FontWeight.bold,
            color: AppColors.getBloodGroupColor(bloodGroup),
          ),
        ),
      ),
    );
  }
}

/// Urgency badge widget
class UrgencyBadge extends StatelessWidget {
  final String urgency;

  const UrgencyBadge({super.key, required this.urgency});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.getUrgencyColor(urgency).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        urgency.toUpperCase(),
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.getUrgencyColor(urgency),
        ),
      ),
    );
  }
}

/// Status badge widget
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        status.capitalize,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.getStatusColor(status),
        ),
      ),
    );
  }
}

/// User avatar widget
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double? size;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = size ?? 40.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: avatarSize.w,
        height: avatarSize.h,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withOpacity(0.1),
        ),
        clipBehavior: Clip.antiAlias,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildPlaceholder(avatarSize),
                errorWidget: (context, url, error) =>
                    _buildPlaceholder(avatarSize),
              )
            : _buildPlaceholder(avatarSize),
      ),
    );
  }

  Widget _buildPlaceholder(double avatarSize) {
    return Center(
      child: Text(
        name.initials,
        style: TextStyle(
          fontSize: (avatarSize * 0.4).sp,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

/// Stats card for dashboard
class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? AppColors.primary;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: cardColor, size: 24.sp),
              ),
              SizedBox(height: 12.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: cardColor,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
