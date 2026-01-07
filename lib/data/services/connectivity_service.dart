import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service to monitor network connectivity
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  
  StreamController<bool>? _connectionStatusController;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isConnected = true;

  /// Stream of connection status changes
  Stream<bool> get connectionStatusStream {
    _connectionStatusController ??= StreamController<bool>.broadcast(
      onListen: _startMonitoring,
      onCancel: _stopMonitoring,
    );
    return _connectionStatusController!.stream;
  }

  /// Current connection status
  bool get isConnected => _isConnected;

  /// Check if device has internet connectivity
  Future<bool> checkConnectivity() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      
      // If no connectivity, return false immediately
      if (connectivityResults.contains(ConnectivityResult.none)) {
        _isConnected = false;
        return false;
      }

      // Check actual internet reachability
      final hasInternet = await _checkInternetReachability();
      _isConnected = hasInternet;
      return hasInternet;
    } catch (e) {
      print('Error checking connectivity: $e');
      _isConnected = false;
      return false;
    }
  }

  /// Check if device can actually reach the internet
  Future<bool> _checkInternetReachability() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    } catch (e) {
      print('Error checking internet reachability: $e');
      return false;
    }
  }

  /// Start monitoring connectivity changes
  void _startMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        final wasConnected = _isConnected;
        
        if (results.contains(ConnectivityResult.none)) {
          _isConnected = false;
        } else {
          // Verify actual internet connectivity
          _isConnected = await _checkInternetReachability();
        }

        // Only emit if status changed
        if (wasConnected != _isConnected) {
          _connectionStatusController?.add(_isConnected);
        }
      },
    );

    // Initial check
    checkConnectivity().then((isConnected) {
      _connectionStatusController?.add(isConnected);
    });
  }

  /// Stop monitoring connectivity changes
  void _stopMonitoring() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  /// Dispose resources
  void dispose() {
    _stopMonitoring();
    _connectionStatusController?.close();
    _connectionStatusController = null;
  }
}
