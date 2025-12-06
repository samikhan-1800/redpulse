import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/request_provider.dart';
import '../../../data/providers/location_provider.dart';
import '../../widgets/cards.dart';
import '../../widgets/common_widgets.dart';
import '../request/create_request_screen.dart';
import '../request/request_detail_screen.dart';

/// Tab index for requests screen
final requestsTabProvider = StateProvider<int>((ref) => 0);

class RequestsScreen extends ConsumerWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = ref.watch(requestsTabProvider);

    return DefaultTabController(
      length: 2,
      initialIndex: tabIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.requests),
          bottom: TabBar(
            onTap: (index) {
              ref.read(requestsTabProvider.notifier).state = index;
            },
            tabs: const [
              Tab(text: AppStrings.allRequests),
              Tab(text: AppStrings.myRequests),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_NearbyRequestsTab(), _MyRequestsTab()],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreateRequestScreen()),
            );
          },
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 3,
          icon: const Icon(Icons.add, size: 20),
          label: Text(
            AppStrings.createRequest,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
      ),
    );
  }
}

class _NearbyRequestsTab extends ConsumerWidget {
  const _NearbyRequestsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationNotifierProvider);

    if (locationState.position == null) {
      return Center(
        child: EmptyState(
          icon: Icons.location_off,
          title: 'Location Required',
          subtitle: 'Enable location to see nearby requests',
          buttonText: 'Enable Location',
          onButtonPressed: () {
            ref.read(locationNotifierProvider.notifier).getCurrentLocation();
          },
        ),
      );
    }

    print(
      '✅ Location available: (${locationState.position!.latitude}, ${locationState.position!.longitude})',
    );

    final params = NearbyRequestsParams(
      latitude: locationState.position!.latitude,
      longitude: locationState.position!.longitude,
      radiusKm: 50.0, // Increased radius to show more requests
    );
    final requestsAsync = ref.watch(nearbyRequestsProvider(params));

    return requestsAsync.when(
      loading: () => const ShimmerList(),
      error: (error, _) => ErrorState(
        message: error.toString(),
        onRetry: () => ref.refresh(nearbyRequestsProvider(params)),
      ),
      data: (requests) {
        if (requests.isEmpty) {
          return const EmptyState(
            icon: Icons.check_circle,
            title: AppStrings.noRequests,
            subtitle: 'No blood requests in your area',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(nearbyRequestsProvider(params));
          },
          child: ListView.builder(
            padding: EdgeInsets.only(top: 8.h, bottom: 100.h),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final locationService = ref.read(locationServiceProvider);
              final distance = locationService.calculateDistance(
                locationState.position!.latitude,
                locationState.position!.longitude,
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
          ),
        );
      },
    );
  }
}

class _MyRequestsTab extends ConsumerWidget {
  const _MyRequestsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(userRequestsProvider);

    return requestsAsync.when(
      loading: () => const ShimmerList(),
      error: (error, _) => ErrorState(
        message: error.toString(),
        onRetry: () => ref.refresh(userRequestsProvider),
      ),
      data: (requests) {
        if (requests.isEmpty) {
          return EmptyState(
            icon: Icons.add_circle_outline,
            title: AppStrings.noRequests,
            subtitle: 'You haven\'t created any requests yet',
            buttonText: AppStrings.createRequest,
            onButtonPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateRequestScreen()),
              );
            },
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userRequestsProvider);
          },
          child: ListView.builder(
            padding: EdgeInsets.only(top: 8.h, bottom: 100.h),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return RequestCard(
                request: request,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          RequestDetailScreen(request: request, isOwner: true),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
