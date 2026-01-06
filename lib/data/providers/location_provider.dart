import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import 'auth_provider.dart';

class LocationState {
  final Position? position;
  final String? address;
  final bool isLoading;
  final String? error;
  final bool permissionGranted;

  const LocationState({
    this.position,
    this.address,
    this.isLoading = false,
    this.error,
    this.permissionGranted = false,
  });

  LocationState copyWith({
    Position? position,
    String? address,
    bool? isLoading,
    String? error,
    bool? permissionGranted,
  }) {
    return LocationState(
      position: position ?? this.position,
      address: address ?? this.address,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      permissionGranted: permissionGranted ?? this.permissionGranted,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  final LocationService _locationService;

  LocationNotifier(this._locationService) : super(const LocationState());

  Future<bool> checkPermission() async {
    state = state.copyWith(isLoading: true, error: null);

    final permission = await _locationService.checkPermission();

    if (permission == LocationPermission.denied) {
      final requested = await _locationService.requestPermission();
      if (requested == LocationPermission.denied) {
        state = state.copyWith(
          isLoading: false,
          error: 'Location permission denied',
          permissionGranted: false,
        );
        return false;
      }
      if (requested == LocationPermission.deniedForever) {
        state = state.copyWith(
          isLoading: false,
          error:
              'Location permission permanently denied. Please enable in settings.',
          permissionGranted: false,
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      state = state.copyWith(
        isLoading: false,
        error:
            'Location permission permanently denied. Please enable in settings.',
        permissionGranted: false,
      );
      return false;
    }

    state = state.copyWith(isLoading: false, permissionGranted: true);
    return true;
  }

  Future<Position?> getCurrentLocation() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) return null;

      final position = await _locationService.getCurrentPosition();

      if (position == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Could not get current location',
        );
        return null;
      }

      state = state.copyWith(
        position: position,
        isLoading: false,
        permissionGranted: true,
      );

      try {
        final addr = await _locationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        state = state.copyWith(address: addr);
      } catch (_) {}

      return position;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error getting location: $e',
      );
      return null;
    }
  }

  double? distanceTo(double latitude, double longitude) {
    if (state.position == null) return null;
    return _locationService.calculateDistance(
      state.position!.latitude,
      state.position!.longitude,
      latitude,
      longitude,
    );
  }

  Future<void> openSettings() async {
    await _locationService.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    await _locationService.openAppSettings();
  }
}

final locationNotifierProvider =
    StateNotifierProvider<LocationNotifier, LocationState>((ref) {
      return LocationNotifier(ref.watch(locationServiceProvider));
    });

final currentPositionProvider = Provider<Position?>((ref) {
  return ref.watch(locationNotifierProvider).position;
});

final positionStreamProvider = StreamProvider<Position>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.getPositionStream();
});
