import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
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
/// - Valid location (latitude/longitude set)
/// Increased limit to show more donors on the map
final allAvailableDonorsProvider = StreamProvider<List<UserModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .where('isAvailable', isEqualTo: true)
      .where('latitude', isNotEqualTo: null)
      .limit(100) // Increased to show more donors
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .where((user) => user.hasLocation) // Show all available donors
            .toList(),
      );
});

/// Provider for all active blood requests
/// Shows requests with status 'pending' or 'accepted' (not completed/cancelled)
/// Emergency requests will blink in red on the map
/// Regular requests show in orange
/// Limited to 20 requests for optimal performance
final allActiveRequestsProvider = StreamProvider<List<BloodRequest>>((ref) {
  return FirebaseFirestore.instance
      .collection('blood_requests')
      .where('status', whereIn: ['pending', 'accepted'])
      .where('latitude', isNotEqualTo: null)
      .limit(20) // Reduced from 30 for better performance
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
  Timer? _updateDebounceTimer;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;
  bool _isUpdatingMarkers = false;
  DateTime? _lastUpdateTime;
  DateTime? _lastBlinkUpdateTime;
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

    // Initialize smooth blink animation for emergency markers
    // Oscillates between 0.4 (faded) and 1.0 (full opacity) in 1.5 seconds
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _blinkAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    // Add listener to update only emergency markers when animation changes
    // Throttled to update only every 200ms for performance
    _blinkAnimation.addListener(() {
      if (mounted && _markers.isNotEmpty) {
        // Throttle updates to every 200ms
        final now = DateTime.now();
        if (_lastBlinkUpdateTime != null &&
            now.difference(_lastBlinkUpdateTime!) <
                const Duration(milliseconds: 200)) {
          return;
        }
        _lastBlinkUpdateTime = now;

        // Only update if we have emergency markers
        final hasEmergencyMarkers =
            _cachedRequests?.any((r) => r.isSOS || r.isEmergency) ?? false;

        if (hasEmergencyMarkers) {
          _updateEmergencyMarkersOpacity();
        }
      }
    });

    // Start the repeating animation
    _blinkController.repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationNotifierProvider.notifier).getCurrentLocation();
      // Force initial data load
      _forceInitialDataLoad();
    });
  }

  /// Force load initial data for markers
  void _forceInitialDataLoad() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        final requestsAsync = ref.read(allActiveRequestsProvider);
        final donorsAsync = ref.read(allAvailableDonorsProvider);
        final mapFilter = ref.read(mapFilterProvider);

        if (requestsAsync.hasValue && donorsAsync.hasValue) {
          final requests = requestsAsync.value ?? [];
          final donors = donorsAsync.value ?? [];
          _cachedRequests = requests;
          _cachedDonors = donors;
          _updateMarkers(requests, donors, mapFilter);
        } else {
          // Retry if data not yet loaded
          _forceInitialDataLoad();
        }
      }
    });
  }

  @override
  void dispose() {
    _updateDebounceTimer?.cancel();
    _blinkController.dispose();
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

  void _updateEmergencyMarkersOpacity() {
    if (_cachedRequests == null || _isUpdatingMarkers) return;

    final filter = ref.read(mapFilterProvider);
    if (!filter.showRequests) return;

    final updatedMarkers = <Marker>{};
    final currentAlpha = _blinkAnimation.value;

    // Update emergency markers with new opacity, keep others as-is
    for (final marker in _markers) {
      if (marker.markerId.value.startsWith('request_')) {
        final requestId = marker.markerId.value.replaceFirst('request_', '');
        final request = _cachedRequests!.firstWhere(
          (r) => r.id == requestId,
          orElse: () => _cachedRequests!.first,
        );

        if (request.isSOS || request.isEmergency) {
          // Update emergency marker with animated opacity
          updatedMarkers.add(marker.copyWith(alphaParam: currentAlpha));
        } else {
          updatedMarkers.add(marker);
        }
      } else {
        // Keep donor markers unchanged
        updatedMarkers.add(marker);
      }
    }

    if (mounted) {
      setState(() {
        _markers = updatedMarkers;
      });
    }
  }

  /// Check if two positions are too close (within ~10 meters)
  bool _arePositionsTooClose(LatLng pos1, LatLng pos2) {
    const threshold = 0.0001; // Approximately 10-15 meters
    return (pos1.latitude - pos2.latitude).abs() < threshold &&
        (pos1.longitude - pos2.longitude).abs() < threshold;
  }

  /// Apply small offset to overlapping markers to make them all visible
  LatLng _getOffsetPosition(LatLng original, int offsetIndex) {
    // Create a circular offset pattern around the original position
    const offsetDistance = 0.0002; // Approximately 20-25 meters
    final angle = (offsetIndex * 60) * (3.14159 / 180); // 60 degrees apart

    return LatLng(
      original.latitude + (offsetDistance * math.cos(angle)),
      original.longitude + (offsetDistance * math.sin(angle)),
    );
  }

  void _handleDataUpdate() {
    // Get latest data
    final requestsAsync = ref.read(allActiveRequestsProvider);
    final donorsAsync = ref.read(allAvailableDonorsProvider);
    final mapFilter = ref.read(mapFilterProvider);

    if (!requestsAsync.hasValue || !donorsAsync.hasValue) return;

    final requests = requestsAsync.value ?? [];
    final donors = donorsAsync.value ?? [];

    // Check if data has changed
    final hasChanged =
        _cachedRequests?.length != requests.length ||
        _cachedDonors?.length != donors.length;

    // Throttle updates - minimum 2 seconds between updates
    final now = DateTime.now();
    final shouldUpdate =
        _lastUpdateTime == null ||
        now.difference(_lastUpdateTime!) > const Duration(seconds: 2);

    if (hasChanged && shouldUpdate && !_isUpdatingMarkers) {
      _cachedRequests = requests;
      _cachedDonors = donors;
      _lastUpdateTime = now;

      // Cancel existing timer
      _updateDebounceTimer?.cancel();

      // Debounce updates to reduce frequency
      _updateDebounceTimer = Timer(const Duration(milliseconds: 800), () {
        if (mounted && !_isUpdatingMarkers) {
          _updateMarkers(requests, donors, mapFilter);
        }
      });
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

        // For emergency, use smooth animated blinking (pulsing effect)
        if (isEmergency) {
          newMarkers.add(
            Marker(
              markerId: MarkerId('request_${request.id}'),
              position: LatLng(request.latitude, request.longitude),
              alpha: _blinkAnimation
                  .value, // Use animated value for smooth pulsing
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

    // Add donor markers with overlap detection
    if (filter.showDonors) {
      // Track positions to detect overlaps
      final positionMap = <LatLng, List<UserModel>>{};

      // Group donors by position
      for (final donor in donors) {
        if (donor.hasLocation) {
          final position = LatLng(donor.latitude!, donor.longitude!);

          // Check if this position is too close to any existing position
          LatLng? closePosition;
          for (final existingPos in positionMap.keys) {
            if (_arePositionsTooClose(position, existingPos)) {
              closePosition = existingPos;
              break;
            }
          }

          if (closePosition != null) {
            // Add to existing position group
            positionMap[closePosition]!.add(donor);
          } else {
            // Create new position group
            positionMap[position] = [donor];
          }
        }
      }

      // Create markers with offsets for overlapping positions
      for (final entry in positionMap.entries) {
        final basePosition = entry.key;
        final donorsAtPosition = entry.value;

        for (int i = 0; i < donorsAtPosition.length; i++) {
          final donor = donorsAtPosition[i];

          // Apply offset if there are multiple donors at this position
          final markerPosition = donorsAtPosition.length > 1
              ? _getOffsetPosition(basePosition, i)
              : basePosition;

          newMarkers.add(
            Marker(
              markerId: MarkerId('donor_${donor.id}'),
              position: markerPosition,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
              infoWindow: InfoWindow(
                title: '🩸 ${donor.name} (${donor.bloodGroup})',
                snippet:
                    'Available Donor • ${donor.totalDonations} donations\\nTap marker for options',
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

    // Watch map filter to trigger rebuild when filter changes
    ref.watch(mapFilterProvider);

    // Use ref.listen instead of ref.watch to prevent rebuild on every change
    // This improves performance by only updating markers, not rebuilding entire widget
    ref.listen<AsyncValue<List<BloodRequest>>>(allActiveRequestsProvider, (
      previous,
      next,
    ) {
      if (next.hasValue) {
        _handleDataUpdate();
      }
    });

    ref.listen<AsyncValue<List<UserModel>>>(allAvailableDonorsProvider, (
      previous,
      next,
    ) {
      if (next.hasValue) {
        _handleDataUpdate();
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                    _cachedRequests?.length ?? 0,
                    _cachedDonors?.length ?? 0,
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with donor info
            Row(
              children: [
                CircleAvatar(
                  radius: 30.r,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    size: 30.sp,
                    color: AppColors.primary,
                  ),
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
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.water_drop,
                                  size: 14.sp,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  donor.bloodGroup,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            '${donor.totalDonations} donations',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Action buttons
            if (donor.phone.isNotEmpty) ...[
              // Call Button
              _buildActionTile(
                icon: Icons.phone_rounded,
                iconColor: Colors.green,
                title: 'Call Donor',
                subtitle: donor.phone,
                onTap: () {
                  Navigator.pop(context);
                  _callDonor(donor.phone);
                },
              ),
              SizedBox(height: 8.h),
              // SMS Button
              _buildActionTile(
                icon: Icons.sms_rounded,
                iconColor: Colors.orange,
                title: 'Send SMS',
                subtitle: 'Open messaging app with pre-filled message',
                onTap: () {
                  Navigator.pop(context);
                  _sendSMS(donor);
                },
              ),
              SizedBox(height: 8.h),
            ] else ...[
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20.sp),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Phone number not available for this donor',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
            ],
            // WhatsApp Button (if phone available)
            if (donor.phone.isNotEmpty) ...[
              _buildActionTile(
                icon: Icons.chat_rounded,
                iconColor: Color(0xFF25D366),
                title: 'WhatsApp',
                subtitle: 'Send message via WhatsApp',
                onTap: () {
                  Navigator.pop(context);
                  _sendWhatsApp(donor);
                },
              ),
            ],
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: iconColor, size: 22.sp),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 20.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Call donor directly
  Future<void> _callDonor(String phoneNumber) async {
    try {
      final uri = Uri.parse('tel:$phoneNumber');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to make call: ${e.message ?? "Unknown error"}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
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

  /// Send SMS with pre-built message
  Future<void> _sendSMS(UserModel donor) async {
    try {
      // Pre-built message for blood donation request
      final message = Uri.encodeComponent(
        'Hello ${donor.name},\n\n'
        'I found your profile on RedPulse Blood Donation App. '
        'I am in need of ${donor.bloodGroup} blood.\n\n'
        'Could you please help me or let me know if you are available for donation?\n\n'
        'Thank you for being a donor! 🩸\n\n'
        '- Sent via RedPulse App',
      );

      final uri = Uri.parse('sms:${donor.phone}?body=$message');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to open SMS: ${e.message ?? "Unknown error"}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening messaging app: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Send WhatsApp message with pre-built text
  Future<void> _sendWhatsApp(UserModel donor) async {
    try {
      // Clean phone number (remove spaces, dashes, etc.)
      String cleanPhone = donor.phone.replaceAll(RegExp(r'[^0-9+]'), '');

      // Add country code if not present (assuming Pakistan +92)
      if (!cleanPhone.startsWith('+')) {
        if (cleanPhone.startsWith('0')) {
          cleanPhone = '+92${cleanPhone.substring(1)}';
        } else {
          cleanPhone = '+92$cleanPhone';
        }
      }

      // Pre-built message
      final message = Uri.encodeComponent(
        'Hello ${donor.name},\n\n'
        'I found your profile on RedPulse Blood Donation App. '
        'I am in need of ${donor.bloodGroup} blood.\n\n'
        'Could you please help me or let me know if you are available for donation?\n\n'
        'Thank you for being a donor! 🩸',
      );

      final uri = Uri.parse('https://wa.me/$cleanPhone?text=$message');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to SMS if WhatsApp not available
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('WhatsApp not available. Try SMS instead.'),
              backgroundColor: AppColors.warning,
              action: SnackBarAction(
                label: 'SMS',
                textColor: Colors.white,
                onPressed: () => _sendSMS(donor),
              ),
            ),
          );
        }
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to open WhatsApp: ${e.message ?? "Unknown error"}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
