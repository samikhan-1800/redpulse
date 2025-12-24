import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/request_provider.dart';
import '../../../data/providers/chat_provider.dart';
import '../../../data/models/blood_request_model.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cards.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/dialogs.dart';
import '../chat/chat_screen.dart';
import '../main/main_screen.dart';

class RequestDetailScreen extends ConsumerStatefulWidget {
  final BloodRequest request;
  final bool isOwner;

  const RequestDetailScreen({
    super.key,
    required this.request,
    this.isOwner = false,
  });

  @override
  ConsumerState<RequestDetailScreen> createState() =>
      _RequestDetailScreenState();
}

class _RequestDetailScreenState extends ConsumerState<RequestDetailScreen> {
  bool _isAccepting = false;

  Future<void> _acceptRequest() async {
    // Prevent concurrent accepts
    if (_isAccepting) return;

    // Get current user profile
    final currentUser = ref.read(currentUserProfileProvider).value;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load your profile. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Check if user already accepted this request
    if (widget.request.acceptedByIds.contains(currentUser.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already accepted this request'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Check if user is available for donation
    if (!currentUser.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You are currently marked as unavailable. Please enable your availability in your profile to accept donation requests.',
          ),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Go to Profile',
            textColor: Colors.white,
            onPressed: () {
              // Navigate to profile screen
              ref.read(bottomNavIndexProvider.notifier).state = 4;
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ),
      );
      return;
    }

    // Check if user is eligible to donate (not donated recently)
    if (!currentUser.canDonate) {
      final nextDate = currentUser.nextEligibleDate;
      final daysRemaining = nextDate != null
          ? nextDate.difference(DateTime.now()).inDays
          : 0;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You recently donated blood and must wait until ${nextDate?.formattedDate ?? "your next eligible date"} (${daysRemaining} days remaining) before donating again.',
          ),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    // Check if request is already fulfilled
    if (widget.request.isFulfilled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This request has already been fulfilled'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final confirmed = await ConfirmationDialog.show(
      context,
      title: AppStrings.acceptRequest,
      message:
          'Are you willing to donate blood for this request? The requester will be notified and a chat will be started.',
      confirmText: 'Yes, I\'ll Donate',
    );

    if (confirmed != true) return;

    setState(() => _isAccepting = true);

    try {
      // Use the proper acceptRequest method from provider
      final chatId = await ref
          .read(bloodRequestNotifierProvider.notifier)
          .acceptRequest(widget.request);

      if (mounted) {
        setState(() => _isAccepting = false);

        if (chatId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request accepted! Chat started with requester.'),
              backgroundColor: AppColors.success,
            ),
          );

          // Navigate back or to chat
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request accepted but failed to create chat'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAccepting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _callRequester() async {
    try {
      final phoneNumber = widget.request.requesterPhone;
      final uri = Uri.parse('tel:$phoneNumber');
      
      // Launch phone dialer directly - let the system handle availability
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on PlatformException catch (e) {
      // Handle specific platform errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to make phone call: ${e.message ?? "Unknown error"}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      // Handle other errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initiating call: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _openMaps() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${widget.request.latitude},${widget.request.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _updateStatus(String status) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Update Status',
      message: 'Are you sure you want to mark this request as $status?',
      confirmText: 'Yes',
      isDangerous: status == 'cancelled',
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(bloodRequestNotifierProvider.notifier)
          .updateStatus(widget.request.id, status);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Request marked as $status')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final isOwner = widget.isOwner || widget.request.requesterId == userId;
    final hasAccepted = widget.request.acceptedByIds.contains(userId);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.requestDetails),
        actions: [
          if (isOwner && widget.request.isActive)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'completed') {
                  _updateStatus('completed');
                } else if (value == 'cancelled') {
                  _updateStatus('cancelled');
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'completed',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Mark as Completed'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'cancelled',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Cancel Request'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.request.isSOS || widget.request.isEmergency)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: widget.request.isSOS
                      ? AppColors.emergency
                      : AppColors.warning,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.white),
                    SizedBox(width: 8.w),
                    Text(
                      widget.request.isSOS
                          ? 'SOS - Immediate Help Needed!'
                          : 'Emergency Request',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 16.h),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    BloodGroupBadge(
                      bloodGroup: widget.request.bloodGroup,
                      size: 72,
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.request.bloodGroup} Blood Needed',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            widget.request.unitsAccepted > 0
                                ? '${widget.request.unitsAccepted}/${widget.request.unitsRequired} units accepted'
                                : '${widget.request.unitsRequired} units required',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: widget.request.unitsAccepted > 0
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          StatusBadge(status: widget.request.status),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),
            const SectionHeader(title: 'Patient Information'),
            Card(
              child: Column(
                children: [
                  _buildInfoRow(
                    Icons.person,
                    AppStrings.patientName,
                    widget.request.patientName,
                  ),
                  const Divider(height: 1),
                  _buildInfoRow(
                    Icons.local_hospital,
                    AppStrings.hospitalName,
                    widget.request.hospitalName,
                  ),
                  const Divider(height: 1),
                  InkWell(
                    onTap: _openMaps,
                    child: _buildInfoRow(
                      Icons.location_on,
                      AppStrings.hospitalAddress,
                      widget.request.hospitalAddress,
                      trailing: Icon(
                        Icons.directions,
                        color: AppColors.primary,
                        size: 20.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            const SectionHeader(title: 'Requester Information'),
            Card(
              child: Column(
                children: [
                  _buildInfoRow(
                    Icons.account_circle,
                    'Posted by',
                    widget.request.requesterName,
                  ),
                  const Divider(height: 1),
                  InkWell(
                    onTap: _callRequester,
                    child: _buildInfoRow(
                      Icons.phone,
                      'Contact',
                      widget.request.requesterPhone,
                      trailing: Icon(
                        Icons.call,
                        color: AppColors.success,
                        size: 20.sp,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  _buildInfoRow(
                    Icons.access_time,
                    'Posted on',
                    widget.request.createdAt.formattedDateTime,
                  ),
                ],
              ),
            ),
            if (widget.request.additionalNotes != null &&
                widget.request.additionalNotes!.isNotEmpty) ...[
              SizedBox(height: 16.h),
              const SectionHeader(title: 'Additional Notes'),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Text(
                    widget.request.additionalNotes!,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
            SizedBox(height: 16.h),
            const SectionHeader(title: 'Compatible Blood Types'),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: widget.request.compatibleBloodGroups
                      .map(
                        (group) => BloodGroupBadge(bloodGroup: group, size: 40),
                      )
                      .toList(),
                ),
              ),
            ),
            SizedBox(height: 32.h),
          ],
        ),
      ),
      bottomNavigationBar: !isOwner && !hasAccepted && widget.request.isActive
          ? SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        text: AppStrings.call,
                        isOutlined: true,
                        icon: Icons.call,
                        onPressed: _callRequester,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      flex: 2,
                      child: widget.request.isSOS
                          ? SOSButton(
                              onPressed: _acceptRequest,
                              isLoading: _isAccepting,
                            )
                          : PrimaryButton(
                              text: AppStrings.acceptRequest,
                              icon: Icons.volunteer_activism,
                              onPressed: _acceptRequest,
                              isLoading: _isAccepting,
                            ),
                    ),
                  ],
                ),
              ),
            )
          : hasAccepted
          ? SafeArea(
              child: Container(
                padding: EdgeInsets.all(16.w),
                color: AppColors.success.withOpacity(0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: AppColors.success),
                    SizedBox(width: 8.w),
                    Text(
                      'You have already accepted this request',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Widget? trailing,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Icon(icon, size: 20.sp, color: AppColors.textSecondary),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
