import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import 'animated_empty_state.dart';

/// Loading indicator widget
class LoadingIndicator extends StatelessWidget {
  final double? size;
  final Color? color;

  const LoadingIndicator({super.key, this.size, this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size ?? 40.w,
        height: size ?? 40.h,
        child: CircularProgressIndicator(
          color: color ?? AppColors.primary,
          strokeWidth: 3,
        ),
      ),
    );
  }
}

/// Full page loading with animated blood drop
class LoadingPage extends StatelessWidget {
  final String? message;

  const LoadingPage({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: AnimatedLoadingWidget(message: message));
  }
}

/// Empty state widget with smooth animation
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyState({
    super.key,
    this.icon = Icons.inbox,
    this.title = AppStrings.noData,
    this.subtitle,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedEmptyState(
              icon: icon,
              message: title,
              iconColor: AppColors.primary.withOpacity(0.3),
              iconSize: 80,
            ),
            if (subtitle != null) ...[
              SizedBox(height: 16.h),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (buttonText != null && onButtonPressed != null) ...[
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: onButtonPressed,
                child: Text(buttonText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error state widget
class ErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const ErrorState({super.key, this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48.sp,
                color: AppColors.error,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              AppStrings.somethingWentWrong,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              SizedBox(height: 8.h),
              Text(
                message!,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              SizedBox(height: 24.h),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text(AppStrings.tryAgain),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shimmer loading card
class ShimmerCard extends StatelessWidget {
  final double? height;
  final double? width;

  const ShimmerCard({super.key, this.height, this.width});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(
        height: height ?? 100.h,
        width: width ?? double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
    );
  }
}

/// Shimmer list
class ShimmerList extends StatelessWidget {
  final int itemCount;
  final double? itemHeight;

  const ShimmerList({super.key, this.itemCount = 5, this.itemHeight});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      itemBuilder: (context, index) => ShimmerCard(height: itemHeight),
    );
  }
}

/// Section header widget
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onActionPressed;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          if (actionText != null)
            TextButton(onPressed: onActionPressed, child: Text(actionText!)),
        ],
      ),
    );
  }
}

/// Divider with text
class DividerWithText extends StatelessWidget {
  final String text;

  const DividerWithText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            text,
            style: TextStyle(fontSize: 12.sp, color: AppColors.textHint),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

/// Badge counter widget
class BadgeCounter extends StatelessWidget {
  final int count;
  final Widget child;
  final bool showZero;

  const BadgeCounter({
    super.key,
    required this.count,
    required this.child,
    this.showZero = false,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0 && !showZero) {
      return child;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -4,
          top: -4,
          child: Container(
            padding: EdgeInsets.all(4.w),
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
            constraints: BoxConstraints(minWidth: 18.w, minHeight: 18.h),
            child: Center(
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Availability toggle widget
class AvailabilityToggle extends StatelessWidget {
  final bool isAvailable;
  final ValueChanged<bool>? onChanged;
  final bool isLoading;

  const AvailabilityToggle({
    super.key,
    required this.isAvailable,
    this.onChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isAvailable
            ? AppColors.success.withOpacity(0.1)
            : AppColors.textSecondary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isAvailable
              ? AppColors.success.withOpacity(0.3)
              : AppColors.textSecondary.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            SizedBox(
              width: 14.w,
              height: 14.h,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isAvailable
                    ? AppColors.success
                    : AppColors.textSecondary,
              ),
            )
          else
            Container(
              width: 10.w,
              height: 10.h,
              decoration: BoxDecoration(
                color: isAvailable
                    ? AppColors.success
                    : AppColors.textSecondary,
                shape: BoxShape.circle,
              ),
            ),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              isAvailable
                  ? AppStrings.availableToDonate
                  : AppStrings.notAvailable,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: isAvailable
                    ? AppColors.success
                    : AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 4.w),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: isAvailable,
              onChanged: isLoading ? null : onChanged,
              activeColor: AppColors.success,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
