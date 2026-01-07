import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final shortestSide = min(mediaQuery.size.width, mediaQuery.size.height);
    final scaleFactor = (shortestSide / 375).clamp(0.8, 1.2);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: ClipRect(
        child: RepaintBoundary(
          child: userAsync.when(
            loading: () => const LoadingPage(),
            error: (error, _) => ErrorState(
              message: error.toString(),
              onRetry: () => ref.refresh(currentUserProfileProvider),
            ),
            data: (user) {
              if (user == null) {
                return const Center(child: Text('Please login'));
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(currentUserProfileProvider);
                  await ref
                      .read(locationNotifierProvider.notifier)
                      .getCurrentLocation();
                },
                child: CustomScrollView(
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    // App bar
                    SliverAppBar(
                      floating: false,
                      pinned: true,
                      elevation: 0,
                      expandedHeight: 0,
                      toolbarHeight: isLandscape ? 48 : 56,
                      leading: Padding(
                        padding: const EdgeInsets.all(8),
                        child: GestureDetector(
                          onTap: () {
                            ref.read(bottomNavIndexProvider.notifier).state = 4;
                          },
                          child: UserAvatar(
                            imageUrl: user.profileImageUrl,
                            name: user.name,
                            size: isLandscape ? 32 : 40,
                          ),
                        ),
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${AppStrings.hello}, ${user.name.split(' ').first}! 👋',
                            style: TextStyle(
                              fontSize: isLandscape ? 14 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (user.city != null)
                            Text(
                              user.city!,
                              style: TextStyle(
                                fontSize: isLandscape ? 9 : 12,
                                color: Colors.white.withOpacity(0.9),
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
                                builder: (context) =>
                                    const NotificationsScreen(),
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
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isLandscape ? 24 : 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Availability toggle
                            Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: isLandscape ? 10 : 16,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: AvailabilityToggle(
                                      isAvailable: user.isAvailable,
                                      onChanged: (value) {
                                        ref
                                            .read(
                                              userProfileNotifierProvider
                                                  .notifier,
                                            )
                                            .toggleAvailability(value);
                                      },
                                    ),
                                  ),
                                  SizedBox(width: isLandscape ? 8 : 12),
                                  BloodGroupBadge(
                                    bloodGroup: user.bloodGroup,
                                    size: isLandscape ? 40 : 48,
                                  ),
                                ],
                              ),
                            ),
                            // Stats cards
                            Row(
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
                                SizedBox(width: isLandscape ? 8 : 12),
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
                            SizedBox(height: isLandscape ? 16 : 24),
                            // Quick actions
                            const SectionHeader(title: AppStrings.quickActions),
                            _buildQuickActions(isLandscape, scaleFactor),
                            SizedBox(height: isLandscape ? 16 : 24),
                            // Nearby requests
                            SectionHeader(
                              title: AppStrings.nearbyRequests,
                              actionText: 'See All',
                              onActionPressed: () {
                                ref
                                        .read(bottomNavIndexProvider.notifier)
                                        .state =
                                    2;
                              },
                            ),
                            // Requests list
                            Container(
                              constraints: BoxConstraints(
                                minHeight: isLandscape ? 80 : 100,
                              ),
                              child: locationState.position != null
                                  ? _NearbyRequestsList(
                                      latitude:
                                          locationState.position!.latitude,
                                      longitude:
                                          locationState.position!.longitude,
                                    )
                                  : const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: EmptyState(
                                        icon: Icons.location_off,
                                        title: 'Location not available',
                                        subtitle:
                                            'Enable location to see nearby requests',
                                      ),
                                    ),
                            ),
                            SizedBox(height: isLandscape ? 16 : 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(bool isLandscape, double scaleFactor) {
    final cardHeight = isLandscape ? 70.0 : 110.0;

    return SizedBox(
      height: cardHeight,
      child: Row(
        children: [
          Expanded(
            child: _QuickActionCard(
              icon: Icons.add_circle,
              title: AppStrings.createRequest,
              color: AppColors.primary,
              isLandscape: isLandscape,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CreateRequestScreen(),
                  ),
                );
              },
            ),
          ),
          SizedBox(width: isLandscape ? 8 : 12),
          Expanded(
            child: _QuickActionCard(
              icon: Icons.emergency,
              title: AppStrings.sosAlert,
              color: AppColors.emergency,
              isLandscape: isLandscape,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const CreateRequestScreen(requestType: 'sos'),
                  ),
                );
              },
            ),
          ),
          SizedBox(width: isLandscape ? 8 : 12),
          Expanded(
            child: _QuickActionCard(
              icon: Icons.search,
              title: AppStrings.findDonors,
              color: AppColors.primary,
              isLandscape: isLandscape,
              onTap: () {
                ref.read(bottomNavIndexProvider.notifier).state = 1;
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback? onTap;
  final bool isLandscape;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.isLandscape,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardPadding = isLandscape
        ? const EdgeInsets.symmetric(vertical: 8, horizontal: 6)
        : const EdgeInsets.symmetric(vertical: 16, horizontal: 12);
    final iconSize = isLandscape ? 18.0 : 26.0;
    final fontSize = isLandscape ? 9.0 : 12.0;
    final iconPadding = isLandscape ? 6.0 : 12.0;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      color: color.withOpacity(0.08),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2), width: 1),
          ),
          padding: cardPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: iconSize),
              ),
              SizedBox(height: isLandscape ? 4 : 6),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
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
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error: $error'),
      ),
      data: (requests) {
        if (requests.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: EmptyState(
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
