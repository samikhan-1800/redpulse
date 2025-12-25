import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/providers/location_provider.dart';
import '../../../data/models/blood_request_model.dart';
import '../../../data/models/user_model.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/dialogs.dart';
import '../request/request_detail_screen.dart';

/// Map filter state
class MapFilterState {
  final bool showDonors;
  final bool showRequests;
  final double radius;
  final String? bloodGroupFilter;

  const MapFilterState({
    this.showDonors = true,
    this.showRequests = true,
    this.radius = 50.0,
    this.bloodGroupFilter,
  });

  MapFilterState copyWith({
    bool? showDonors,
    bool? showRequests,
    double? radius,
    String? bloodGroupFilter,
  }) {
    return MapFilterState(
      showDonors: showDonors ?? this.showDonors,
      showRequests: showRequests ?? this.showRequests,
      radius: radius ?? this.radius,
      bloodGroupFilter: bloodGroupFilter ?? this.bloodGroupFilter,
    );
  }
}

final mapFilterProvider = StateProvider<MapFilterState>((ref) {
  return const MapFilterState();
});

/// Provider for all available donors from across the system
/// Shows all registered users who have:
/// - isAvailable = true (marked themselves as available)
/// - canDonate = true OR field not set (eligible to donate)
/// - Valid location (latitude/longitude set)
/// Limited to 50 donors for optimal performance
final allAvailableDonorsProvider = StreamProvider<List<UserModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .where('isAvailable', isEqualTo: true)
      .where('latitude', isNotEqualTo: null)
      .limit(50) // Reduced from 100 for better performance
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .where((user) => user.hasLocation && (user.canDonate))
            .toList(),
      );
});

/// Provider for all active blood requests
/// Shows requests with status 'pending' or 'accepted' (not completed/cancelled)
/// Emergency requests will blink in red on the map
/// Regular requests show in orange
/// Limited to 30 requests for optimal performance
final allActiveRequestsProvider = StreamProvider<List<BloodRequest>>((ref) {
  return FirebaseFirestore.instance
      .collection('blood_requests')
      .where('status', whereIn: ['pending', 'accepted'])
      .where('latitude', isNotEqualTo: null)
      .limit(30) // Reduced from 50 for better performance
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => BloodRequest.fromFirestore(doc))
            .toList(),
      );
});

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Timer? _blinkTimer;
  Timer? _updateDebounceTimer;
  bool _showEmergencyMarkers = true;
  late AnimationController _pulseController;
  bool _isUpdatingMarkers = false;
  DateTime? _lastUpdateTime;
  List<BloodRequest>? _cachedRequests;
  List<UserModel>? _cachedDonors;

  @override
  bool get wantKeepAlive => true;

  // Dark mode map style
  static const String _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#212121"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#757575"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#212121"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#2c2c2c"}]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#8a8a8a"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#000000"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#3d3d3d"}]
  }
]
''';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationNotifierProvider.notifier).getCurrentLocation();
    });

    // Start blinking timer for emergency markers (reduced frequency for performance)
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 2000), (timer) {
      if (mounted) {
        setState(() {
          _showEmergencyMarkers = !_showEmergencyMarkers;
        });
      }
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _updateDebounceTimer?.cancel();
    _pulseController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _setMapStyle();
    _centerOnUserLocation();
  }

  void _setMapStyle() {
    if (_mapController == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      _mapController!.setMapStyle(_darkMapStyle);
    } else {
      _mapController!.setMapStyle(null);
    }
  }

  void _centerOnUserLocation() {
    final position = ref.read(locationNotifierProvider).position;
    if (position != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          14,
        ),
      );
    }
  }

  void _updateMarkers(
    List<BloodRequest> requests,
    List<UserModel> donors,
    MapFilterState filter,
  ) {
    // Prevent concurrent updates
    if (_isUpdatingMarkers) return;
    _isUpdatingMarkers = true;

    final newMarkers = <Marker>{};

    // Add request markers
    if (filter.showRequests) {
      for (final request in requests) {
        final isEmergency = request.isSOS || request.isEmergency;

        // For emergency, use blinking logic (fade in/out effect)
        if (isEmergency) {
          newMarkers.add(
            Marker(
              markerId: MarkerId('request_${request.id}'),
              position: LatLng(request.latitude, request.longitude),
              alpha: _showEmergencyMarkers ? 1.0 : 0.3,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
              infoWindow: InfoWindow(
                title: '🚨 ${request.bloodGroup} Blood EMERGENCY',
                snippet:
                    '${request.unitsRequired} units • ${request.patientName}\n${request.hospitalName}\nTap to view details',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RequestDetailScreen(request: request),
                    ),
                  );
                },
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RequestDetailScreen(request: request),
                  ),
                );
              },
            ),
          );
        } else {
          // Non-emergency requests (orange markers)
          newMarkers.add(
            Marker(
              markerId: MarkerId('request_${request.id}'),
              position: LatLng(request.latitude, request.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange,
              ),
              infoWindow: InfoWindow(
                title: '🩸 ${request.bloodGroup} Blood Needed',
                snippet:
                    '${request.unitsRequired} units • ${request.patientName}\n${request.hospitalName}\nTap to view details',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RequestDetailScreen(request: request),
                    ),
                  );
                },
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RequestDetailScreen(request: request),
                  ),
                );
              },
            ),
          );
        }
      }
    }

    // Add donor markers
    if (filter.showDonors) {
      for (final donor in donors) {
        if (donor.hasLocation) {
          newMarkers.add(
            Marker(
              markerId: MarkerId('donor_${donor.id}'),
              position: LatLng(donor.latitude!, donor.longitude!),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
              infoWindow: InfoWindow(
                title: '🩸 ${donor.name} (${donor.bloodGroup})',
                snippet:
                    'Available Donor • ${donor.totalDonations} donations\nTap marker for options',
              ),
              onTap: () {
                _showDonorOptions(donor);
              },
            ),
          );
        }
      }
    }

    if (mounted) {
      setState(() {
        _markers = newMarkers;
      });
    }
    _isUpdatingMarkers = false;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final locationState = ref.watch(locationNotifierProvider);
    final mapFilter = ref.watch(mapFilterProvider);

    // Watch all requests and donors
    final requestsAsync = ref.watch(allActiveRequestsProvider);
    final donorsAsync = ref.watch(allAvailableDonorsProvider);

    // Only update markers if data has actually changed and enough time has passed
    if (requestsAsync.hasValue && donorsAsync.hasValue) {
      final requests = requestsAsync.value ?? [];
      final donors = donorsAsync.value ?? [];

      // Check if data has changed
      final hasChanged =
          _cachedRequests?.length != requests.length ||
          _cachedDonors?.length != donors.length;

      // Throttle updates - minimum 1 second between updates
      final now = DateTime.now();
      final shouldUpdate =
          _lastUpdateTime == null ||
          now.difference(_lastUpdateTime!) > const Duration(seconds: 1);

      if (hasChanged && shouldUpdate && !_isUpdatingMarkers) {
        _cachedRequests = requests;
        _cachedDonors = donors;
        _lastUpdateTime = now;

        // Cancel existing timer
        _updateDebounceTimer?.cancel();

        // Debounce updates to reduce frequency
        _updateDebounceTimer = Timer(const Duration(milliseconds: 500), () {
          if (mounted && !_isUpdatingMarkers) {
            _updateMarkers(requests, donors, mapFilter);
          }
        });
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.map),
        actions: [
          IconButton(
            onPressed: _showFilterSheet,
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: locationState.isLoading
          ? const LoadingPage(message: 'Getting location...')
          : locationState.position == null
          ? Center(
              child: EmptyState(
                icon: Icons.location_off,
                title: 'Location Required',
                subtitle:
                    locationState.error ?? 'Please enable location services',
                buttonText: 'Enable Location',
                onButtonPressed: () {
                  ref
                      .read(locationNotifierProvider.notifier)
                      .getCurrentLocation();
                },
              ),
            )
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      locationState.position!.latitude,
                      locationState.position!.longitude,
                    ),
                    zoom: 13,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                  zoomGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  rotateGesturesEnabled: true,
                  mapToolbarEnabled: false,
                  compassEnabled: true,
                  buildingsEnabled: false,
                  trafficEnabled: false,
                ),
                // Legend
                Positioned(top: 16.h, left: 16.w, child: _buildLegend()),
                // Stats card
                Positioned(
                  top: 16.h,
                  right: 16.w,
                  child: _buildStatsCard(
                    requestsAsync.value?.length ?? 0,
                    donorsAsync.value?.length ?? 0,
                  ),
                ),
                // Center on location button
                Positioned(
                  bottom: 100.h,
                  right: 16.w,
                  child: FloatingActionButton.small(
                    heroTag: 'centerLocation',
                    onPressed: _centerOnUserLocation,
                    child: const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsCard(int requestCount, int donorCount) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active',
              style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bloodtype, size: 12.sp, color: Colors.red),
                SizedBox(width: 4.w),
                Text('$requestCount', style: TextStyle(fontSize: 10.sp)),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person, size: 12.sp, color: Colors.green),
                SizedBox(width: 4.w),
                Text('$donorCount', style: TextStyle(fontSize: 10.sp)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _legendItem(Colors.red, 'Emergency'),
            SizedBox(height: 4.h),
            _legendItem(Colors.orange, 'Request'),
            SizedBox(height: 4.h),
            _legendItem(Colors.green, 'Donor'),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12.w,
          height: 12.h,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 8.w),
        Text(label, style: TextStyle(fontSize: 10.sp)),
      ],
    );
  }

  void _showFilterSheet() {
    CustomBottomSheet.show(
      context,
      title: 'Map Filters',
      child: const _MapFilterSheet(),
    );
  }

  void _showDonorOptions(UserModel donor) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30.r,
                  backgroundColor: Colors.red.shade100,
                  child: Icon(Icons.person, size: 30.sp, color: Colors.red),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donor.name,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.water_drop,
                            size: 16.sp,
                            color: Colors.red,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            donor.bloodGroup,
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${donor.totalDonations} ${donor.totalDonations == 1 ? 'donation' : 'donations'}',
                        style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            if (donor.phone.isNotEmpty) ...[
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.green),
                title: const Text('Call Donor'),
                subtitle: Text(donor.phone),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement call functionality
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.chat, color: Colors.blue),
              title: const Text('Send Message'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to chat
              },
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}

class _MapFilterSheet extends ConsumerWidget {
  const _MapFilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(mapFilterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show options
        SwitchListTile(
          title: const Text(AppStrings.showDonors),
          value: filter.showDonors,
          onChanged: (value) {
            ref.read(mapFilterProvider.notifier).state = filter.copyWith(
              showDonors: value,
            );
          },
        ),
        SwitchListTile(
          title: const Text(AppStrings.showRequests),
          value: filter.showRequests,
          onChanged: (value) {
            ref.read(mapFilterProvider.notifier).state = filter.copyWith(
              showRequests: value,
            );
          },
        ),
        SizedBox(height: 16.h),
      ],
    );
  }
}
