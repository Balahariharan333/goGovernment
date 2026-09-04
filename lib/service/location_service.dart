import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

/// Centralized service for device GPS, geocoding, distance computation, and turn-by-turn navigation.
class LocationService {
  LocationService._();

  /// Default fallback location in Bengaluru if GPS is unavailable or disabled.
  static const LatLng defaultLocation = LatLng(12.9716, 77.5946);

  /// Checks device location service status and permissions, then returns the current position.
  static Future<Position?> getCurrentPosition({bool requestPermission = true}) async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LocationService] Location services are disabled.');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('[LocationService] Location permissions denied ($permission).');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint('[LocationService] Error obtaining current position: $e');
      return null;
    }
  }

  static final Geocoding _geocoding = Geocoding();

  /// Converts GPS coordinates into a human-readable street address with locality and postal code.
  static Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final List<Placemark> placemarks = await _geocoding.placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final List<String> parts = [];

        final name = p.name?.trim() ?? '';
        final street = p.street?.trim() ?? '';
        final subLocality = p.subLocality?.trim() ?? '';
        final locality = p.locality?.trim() ?? '';
        final postalCode = p.postalCode?.trim() ?? '';

        if (name.isNotEmpty && !parts.contains(name)) parts.add(name);
        if (street.isNotEmpty && street != name && !parts.contains(street)) parts.add(street);
        if (subLocality.isNotEmpty && !parts.contains(subLocality)) parts.add(subLocality);
        if (locality.isNotEmpty && !parts.contains(locality)) parts.add(locality);
        if (postalCode.isNotEmpty && !parts.contains(postalCode)) parts.add(postalCode);

        if (parts.isNotEmpty) {
          return parts.join(', ');
        }
      }
    } catch (e) {
      debugPrint('[LocationService] Error reverse geocoding ($lat, $lng): $e');
    }
    return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  }

  /// Converts a textual street address into latitude and longitude coordinates.
  static Future<LatLng?> getCoordinatesFromAddress(String address) async {
    try {
      final List<Location> locations = await _geocoding.locationFromAddress(address);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        return LatLng(loc.latitude, loc.longitude);
      }
    } catch (e) {
      debugPrint('[LocationService] Error geocoding address "$address": $e');
    }
    return null;
  }

  /// Computes the straight-line distance in meters between two GPS coordinates.
  static double calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Formats distance in meters into user-friendly string (e.g. "250 m" or "1.8 km").
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Launches native turn-by-turn navigation (Google Maps / Apple Maps) via deep link.
  static Future<bool> launchTurnByTurnNavigation({
    double? destLat,
    double? destLng,
    String? address,
    bool isWalking = false,
  }) async {
    final mode = isWalking ? 'w' : 'd';
    final travelMode = isWalking ? 'walking' : 'driving';
    final targetDestination = (destLat != null && destLng != null)
        ? '$destLat,$destLng'
        : Uri.encodeComponent(address ?? '');

    if (targetDestination.isEmpty) {
      debugPrint('[LocationService] Cannot navigate without destination coordinates or address.');
      return false;
    }

    // 1. Android native turn-by-turn navigation intent
    final nativeUri = Uri.parse('google.navigation:q=$targetDestination&mode=$mode');

    // 2. Universal web / fallback directions URI
    final webUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$targetDestination&travelmode=$travelMode',
    );

    try {
      if (await canLaunchUrl(nativeUri)) {
        return await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUri)) {
        return await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[LocationService] Navigation launch error: $e');
    }
    return false;
  }
}
