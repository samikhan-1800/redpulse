import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/user_provider.dart';
import '../../../data/providers/request_provider.dart';
import '../../../data/providers/donation_provider.dart';
import '../../../data/providers/location_provider.dart';
import '../../../data/providers/notification_provider.dart';
import '../../widgets/cards.dart';
import '../../widgets/common_widgets.dart';
import '../request/create_request_screen.dart';
import '../request/request_detail_screen.dart';
import '../notification/notifications_screen.dart';
import 'main_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Get location on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationNotifierProvider.notifier).getCurrentLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProfileProvider);
    final donationStats = ref.watch(donationStatsProvider);
    final locationState = ref.watch(locationNotifierProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      body: userAsync.when(
        loading: () => const LoadingPage(),
        error: (error, _) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.refresh(currentUserProfileProvider),
        ),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Please login'));
          }

          return SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(currentUserProfileProvider);
                await ref
                    .read(locationNotifierProvider.notifier)
                    .getCurrentLocation();
              },
              child: CustomScrollView(
                slivers: [
                  // App bar
                  SliverAppBar(
                    floating: true,
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${AppStrings.hello}, ${user.name.split(' ').first}! 👋',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (user.city != null)
                          Text(
                            user.city!,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                    actions: [
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationsScreen(),
                            ),
                          );
                        },
                        icon: BadgeCounter(
                          count: unreadCount,
                          child: const Icon(Icons.notifications_outlined),
                        ),
                      ),
                    ],
                  ),
                  // Content
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Availability toggle
                        Padding(
                          padding: EdgeInsets.all(16.w),
                          child: Row(
                            children: [
                              Expanded(
                                child: AvailabilityToggle(
                                  isAvailable: user.isAvailable,
                                  onChanged: (value) {
                                    ref
                                        .read(
                                          userProfileNotifierProvider.notifier,
                                        )
                                        .toggleAvailability(value);
                                  },
                                ),
                              ),
                              SizedBox(width: 12.w),
                              BloodGroupBadge(
                                bloodGroup: user.bloodGroup,
                                size: 48,
                              ),
                            ],
                          ),
                        ),
                        // Stats cards
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Row(
                            children: [
                              Expanded(
                                child: StatsCard(
                                  title: AppStrings.totalDonations,
                                  value: donationStats.totalDonations
                                      .toString(),
                                  icon: Icons.volunteer_activism,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: StatsCard(
                                  title: AppStrings.livesSaved,
                                  value: donationStats.livesSaved.toString(),
                                  icon: Icons.favorite,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24.h),
                        // Quick actions
                        const SectionHeader(title: AppStrings.quickActions),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Row(
                            children: [
                              Expanded(
                                child: _QuickActionCard(
                                  icon: Icons.add_circle,
                                  title: AppStrings.createRequest,
                                  color: AppColors.primary,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const CreateRequestScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: _QuickActionCard(
                                  icon: Icons.emergency,
                                  title: AppStrings.sosAlert,
                                  color: AppColors.emergency,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const CreateRequestScreen(
                                              requestType: 'sos',
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: _QuickActionCard(
                                  icon: Icons.search,
                                  title: AppStrings.findDonors,
                                  color: AppColors.secondary,
                                  onTap: () {
                                    ref
                                            .read(
                                              bottomNavIndexProvider.notifier,
                                            )
                                            .state =
                                        1;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24.h),
                        // Nearby requests
                        SectionHeader(
                          title: AppStrings.nearbyRequests,
                          actionText: 'See All',
                          onActionPressed: () {
                            ref.read(bottomNavIndexProvider.notifier).state = 2;
                          },
                        ),
                        // Requests list
                        if (locationState.position != null)
                          _NearbyRequestsList(
                            latitude: locationState.position!.latitude,
                            longitude: locationState.position!.longitude,
                          )
                        else
                          Padding(
                            padding: EdgeInsets.all(16.w),
                            child: const EmptyState(
                              icon: Icons.location_off,
                              title: 'Location not available',
                              subtitle:
                                  'Enable location to see nearby requests',
                            ),
                          ),
                        SizedBox(height: 24.h),
                      ],
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
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback? onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      elevation: 0,
      color: color.withOpacity(0.08),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: color.withOpacity(0.2), width: 1),
          ),
          padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 12.w),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24.sp),
              ),
              SizedBox(height: 8.h),
              Text(
                title,
                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NearbyRequestsList extends ConsumerWidget {
  final double latitude;
  final double longitude;

  const _NearbyRequestsList({required this.latitude, required this.longitude});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = NearbyRequestsParams(
      latitude: latitude,
      longitude: longitude,
    );
    final requestsAsync = ref.watch(nearbyRequestsProvider(params));

    return requestsAsync.when(
      loading: () => const ShimmerList(itemCount: 3),
      error: (error, _) =>
          Padding(padding: EdgeInsets.all(16.w), child: Text('Error: $error')),
      data: (requests) {
        if (requests.isEmpty) {
          return Padding(
            padding: EdgeInsets.all(16.w),
            child: const EmptyState(
              icon: Icons.check_circle,
              title: AppStrings.noRequests,
              subtitle: 'No blood requests in your area right now',
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: requests.take(3).length,
          addRepaintBoundaries: true,
          addAutomaticKeepAlives: false,
          itemBuilder: (context, index) {
            final request = requests[index];
            final locationService = ref.read(locationServiceProvider);
            final distance = locationService.calculateDistance(
              latitude,
              longitude,
              request.latitude,
              request.longitude,
            );

            return RequestCard(
              request: request,
              distance: distance,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RequestDetailScreen(request: request),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
