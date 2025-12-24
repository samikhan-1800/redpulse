import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'
    hide ClusterManager, Cluster;
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/location_provider.dart';
import '../../../data/providers/request_provider.dart';
import '../../../data/providers/user_provider.dart';
import '../../../data/models/blood_request_model.dart';
import '../../../data/models/user_model.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/dialogs.dart';
import '../request/request_detail_screen.dart';

/// Cluster item for markers
class MapMarkerItem with ClusterItem {
  final String id;
  final LatLng position;
  final String type; // 'donor', 'request', 'emergency'
  final dynamic data; // UserModel or BloodRequest
  final bool isEmergency;

  MapMarkerItem({
    required this.id,
    required this.position,
    required this.type,
    required this.data,
    this.isEmergency = false,
  });

  @override
  LatLng get location => position;

  @override
  String get geohash => '';
}

/// Map filter state
class MapFilterState {
  final bool showDonors;
  final bool showRequests;
  final double radius;
  final String? bloodGroupFilter;

  const MapFilterState({
    this.showDonors = true,
    this.showRequests = true,
    this.radius = 50.0, // Increased default radius
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

/// Provider for all available donors (not just nearby)
final allAvailableDonorsProvider = StreamProvider<List<UserModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .where('isAvailable', isEqualTo: true)
      .where('canDonate', isEqualTo: true)
      .where('latitude', isNotEqualTo: null)
      .limit(500) // Limit for performance
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .where((user) => user.hasLocation)
            .toList(),
      );
});

/// Provider for all active requests
final allActiveRequestsProvider = StreamProvider<List<BloodRequest>>((ref) {
  return FirebaseFirestore.instance
      .collection('blood_requests')
      .where('status', isEqualTo: 'active')
      .where('latitude', isNotEqualTo: null)
      .limit(500) // Limit for performance
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
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  late ClusterManager _clusterManager;
  Set<Marker> _markers = {};
  Timer? _blinkTimer;
  bool _showEmergencyMarkers = true;
  late AnimationController _pulseController;

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

    _clusterManager = ClusterManager<MapMarkerItem>(
      [],
      _updateMarkers,
      markerBuilder: _markerBuilder,
      levels: [1, 4.25, 6.75, 8.25, 11.5, 14.5, 16.0, 16.5, 20.0],
      extraPercent: 0.2,
      stopClusteringZoom: 17.0,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationNotifierProvider.notifier).getCurrentLocation();
    });

    // Start blinking timer for emergency markers
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
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
    _pulseController.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _clusterManager.setMapId(controller.mapId);
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

  Future<Marker> _markerBuilder(dynamic clusterData) async {
    final cluster = clusterData as Cluster<MapMarkerItem>;
    if (cluster.isMultiple) {
      // Cluster marker
      return Marker(
        markerId: MarkerId(cluster.getId()),
        position: cluster.location,
        icon: await _getClusterBitmap(
          cluster.count,
          cluster.items.any((item) => item.isEmergency),
        ),
        onTap: () {
          // Zoom in to cluster
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(cluster.location, 15),
          );
        },
      );
    }

    // Single marker
    final item = cluster.items.first;
    return _createSingleMarker(item);
  }

  Marker _createSingleMarker(MapMarkerItem item) {
    if (item.type == 'request') {
      final request = item.data as BloodRequest;
      final isEmergency = request.isSOS || request.isEmergency;

      // For emergency, use blinking logic
      if (isEmergency && !_showEmergencyMarkers) {
        return Marker(
          markerId: MarkerId(item.id),
          position: item.position,
          alpha: 0.3, // Faded for blink effect
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        );
      }

      return Marker(
        markerId: MarkerId(item.id),
        position: item.position,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isEmergency ? BitmapDescriptor.hueRed : BitmapDescriptor.hueOrange,
        ),
        infoWindow: InfoWindow(
          title:
              '🩸 ${request.bloodGroup} Blood ${isEmergency ? "EMERGENCY" : "Needed"}',
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
      );
    } else {
      // Donor marker
      final donor = item.data as UserModel;
      return Marker(
        markerId: MarkerId(item.id),
        position: item.position,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: '🩸 ${donor.name} (${donor.bloodGroup})',
          snippet:
              'Available Donor • ${donor.totalDonations} donations\nTap marker for options',
        ),
        onTap: () {
          _showDonorOptions(donor);
        },
      );
    }
  }

  Future<BitmapDescriptor> _getClusterBitmap(
    int size,
    bool hasEmergency,
  ) async {
    // For now, use default markers with appropriate color
    // In production, you'd want to create custom cluster icons with numbers
    return BitmapDescriptor.defaultMarkerWithHue(
      hasEmergency ? BitmapDescriptor.hueRed : BitmapDescriptor.hueViolet,
    );
  }

  void _updateMarkers(Set<Marker> markers) {
    setState(() {
      _markers = markers;
    });
  }

  void _updateClusterItems(
    List<BloodRequest> requests,
    List<UserModel> donors,
    MapFilterState filter,
  ) {
    final items = <MapMarkerItem>[];

    // Add request markers
    if (filter.showRequests) {
      for (final request in requests) {
        items.add(
          MapMarkerItem(
            id: 'request_${request.id}',
            position: LatLng(request.latitude, request.longitude),
            type: 'request',
            data: request,
            isEmergency: request.isSOS || request.isEmergency,
          ),
        );
      }
    }

    // Add donor markers
    if (filter.showDonors) {
      for (final donor in donors) {
        if (donor.hasLocation) {
          items.add(
            MapMarkerItem(
              id: 'donor_${donor.id}',
              position: LatLng(donor.latitude!, donor.longitude!),
              type: 'donor',
              data: donor,
            ),
          );
        }
      }
    }

    _clusterManager.setItems(items);
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationNotifierProvider);
    final mapFilter = ref.watch(mapFilterProvider);

    // Watch all requests and donors
    final requestsAsync = ref.watch(allActiveRequestsProvider);
    final donorsAsync = ref.watch(allAvailableDonorsProvider);

    // Update cluster items when data changes
    if (requestsAsync.hasValue && donorsAsync.hasValue) {
      final requests = requestsAsync.value ?? [];
      final donors = donorsAsync.value ?? [];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateClusterItems(requests, donors, mapFilter);
      });
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
                    zoom: 14,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  onCameraMove: _clusterManager.onCameraMove,
                  onCameraIdle: _clusterManager.updateMap,
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
                        '${donor.totalDonations} donations',
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
