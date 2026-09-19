import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class NavigationLauncher {
  NavigationLauncher._();

  /// Launches Google Maps Navigation directly to the given destination coordinates.
  /// Falls back to Google Maps search URL if intent isn't handled.
  static Future<bool> openGoogleMapsDirections(double lat, double lng, {String label = 'Destination'}) async {
    final googleMapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
    final uri = Uri.parse(googleMapsUrl);

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to web browser or generic map url
        return await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('❌ [NavigationLauncher] Failed to open Google Maps: $e');
      return false;
    }
  }

  /// Launches native phone dialer for calling customer or store owner
  static Future<bool> callPhoneNumber(String phone) async {
    if (phone.isEmpty) return false;
    // Strip out non-numeric characters except +
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleaned');

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
      return false;
    } catch (e) {
      debugPrint('❌ [NavigationLauncher] Failed to call phone: $e');
      return false;
    }
  }
}
