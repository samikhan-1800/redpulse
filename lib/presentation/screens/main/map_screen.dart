import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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

/// Map filter state
class MapFilterState {
  final bool showDonors;
  final bool showRequests;
  final double radius;
  final String? bloodGroupFilter;

  const MapFilterState({
    this.showDonors = true,
    this.showRequests = true,
    this.radius = 10.0,
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

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  // Cache to prevent unnecessary marker updates
  String _lastMarkersHash = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationNotifierProvider.notifier).getCurrentLocation();
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _centerOnUserLocation();
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
    // Create hash to detect changes
    final newHash =
        '${requests.length}_${donors.length}_${filter.showDonors}_${filter.showRequests}';
    if (_lastMarkersHash == newHash) return; // No changes, skip update
    _lastMarkersHash = newHash;

    _markers.clear();

    // Add request markers
    if (filter.showRequests) {
      for (final request in requests) {
        _markers.add(
          Marker(
            markerId: MarkerId('request_${request.id}'),
            position: LatLng(request.latitude, request.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              request.isSOS || request.isEmergency
                  ? BitmapDescriptor.hueRed
                  : BitmapDescriptor.hueOrange,
            ),
            infoWindow: InfoWindow(
              title: '🩸 ${request.bloodGroup} Blood Needed',
              snippet:
                  '${request.patientName} at ${request.hospitalName}\nTap to view details',
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

    // Add donor markers
    if (filter.showDonors) {
      for (final donor in donors) {
        if (donor.hasLocation) {
          _markers.add(
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

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationNotifierProvider);
    final mapFilter = ref.watch(mapFilterProvider);
    final currentUser = ref.watch(currentUserProfileProvider).value;

    // Watch nearby requests
    final requestsAsync = locationState.position != null
        ? ref.watch(
            nearbyRequestsProvider(
              NearbyRequestsParams(
                latitude: locationState.position!.latitude,
                longitude: locationState.position!.longitude,
                radiusKm: mapFilter.radius,
              ),
            ),
          )
        : null;

    // Watch nearby donors
    final donorsAsync = locationState.position != null && currentUser != null
        ? ref.watch(
            nearbyDonorsProvider(
              NearbyDonorsParams(
                latitude: locationState.position!.latitude,
                longitude: locationState.position!.longitude,
                bloodGroup:
                    mapFilter.bloodGroupFilter ?? currentUser.bloodGroup,
                radiusKm: mapFilter.radius,
              ),
            ),
          )
        : null;

    // Update markers when data changes
    if (requestsAsync != null && donorsAsync != null) {
      final requests = requestsAsync.valueOrNull ?? [];
      final donors = donorsAsync.valueOrNull ?? [];
      _updateMarkers(requests, donors, mapFilter);
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
                ),
                // Legend
                Positioned(top: 16.h, left: 16.w, child: _buildLegend()),
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

  Widget _buildLegend() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _legendItem(Colors.red, 'Emergency Request'),
            SizedBox(height: 4.h),
            _legendItem(Colors.orange, 'Normal Request'),
            SizedBox(height: 4.h),
            _legendItem(Colors.green, 'Available Donor'),
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
                leading: Icon(Icons.phone, color: Colors.green),
                title: Text('Call Donor'),
                subtitle: Text(donor.phone),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement call functionality
                },
              ),
            ],
            ListTile(
              leading: Icon(Icons.chat, color: Colors.blue),
              title: Text('Send Message'),
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
        const Divider(),
        // Radius slider
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${AppStrings.searchRadius}: ${filter.radius.toInt()} km',
                style: TextStyle(fontSize: 14.sp),
              ),
              Slider(
                value: filter.radius,
                min: 1,
                max: 50,
                divisions: 49,
                onChanged: (value) {
                  ref.read(mapFilterProvider.notifier).state = filter.copyWith(
                    radius: value,
                  );
                },
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }
}
