// lib/services/common/permission_service.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionResult {
  final bool locationGranted;
  final double? latitude;
  final double? longitude;
  final bool cameraGranted;

  const PermissionResult({
    required this.locationGranted,
    this.latitude,
    this.longitude,
    required this.cameraGranted,
  });
}

class PermissionService {
  /// Request all required app permissions.
  /// Gracefully falls back on web/desktop where plugins aren't supported.
  static Future<PermissionResult> requestAllPermissions(
    BuildContext context,
  ) async {
    bool locationGranted = false;
    double? lat;
    double? lon;
    bool cameraGranted = false;

    // ── 1. Location (only works on Android / iOS) ────────────────────────────
    try {
      LocationPermission locationPerm = await Geolocator.checkPermission();

      if (locationPerm == LocationPermission.denied) {
        locationPerm = await Geolocator.requestPermission();
      }

      if (locationPerm == LocationPermission.whileInUse ||
          locationPerm == LocationPermission.always) {
        locationGranted = true;
        try {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 10),
            ),
          );
          lat = pos.latitude;
          lon = pos.longitude;
        } catch (e) {
          debugPrint('⚠️ Could not get GPS position: $e');
          locationGranted = false;
        }
      } else if (locationPerm == LocationPermission.deniedForever) {
        if (context.mounted) {
          await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('Location Permission'),
              content: const Text(
                'Location access is required to show real-time weather.\n\n'
                'Please enable it in Settings → App → Permissions.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    openAppSettings();
                  },
                  child: const Text(
                    'Open Settings',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }
      }
    } on MissingPluginException {
      // Running on web or desktop — geolocator not supported, skip silently
      debugPrint('ℹ️ Geolocator not supported on this platform (web/desktop). Using city fallback.');
    } catch (e) {
      debugPrint('⚠️ Location permission error: $e');
    }

    // ── 2. Camera (only works on Android / iOS) ──────────────────────────────
    try {
      final cameraStatus = await Permission.camera.status;
      if (cameraStatus.isDenied) {
        final result = await Permission.camera.request();
        cameraGranted = result.isGranted;
      } else if (cameraStatus.isPermanentlyDenied) {
        cameraGranted = false;
      } else {
        cameraGranted = cameraStatus.isGranted;
      }
    } on MissingPluginException {
      // Running on web or desktop — permission_handler not supported
      debugPrint('ℹ️ permission_handler not supported on this platform.');
    } catch (e) {
      debugPrint('⚠️ Camera permission error: $e');
    }

    return PermissionResult(
      locationGranted: locationGranted,
      latitude: lat,
      longitude: lon,
      cameraGranted: cameraGranted,
    );
  }
}
