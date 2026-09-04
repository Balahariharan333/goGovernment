import 'package:flutter_test/flutter_test.dart';
import 'package:go_government/service/location_service.dart';

void main() {
  group('LocationService tests', () {
    test('formatDistance formats meters accurately', () {
      expect(LocationService.formatDistance(50), '50 m');
      expect(LocationService.formatDistance(260.4), '260 m');
      expect(LocationService.formatDistance(999), '999 m');
      expect(LocationService.formatDistance(1000), '1.0 km');
      expect(LocationService.formatDistance(1250), '1.3 km');
      expect(LocationService.formatDistance(3140), '3.1 km');
    });

    test('defaultLocation is set to Bengaluru coordinates', () {
      expect(LocationService.defaultLocation.latitude, closeTo(12.9716, 0.001));
      expect(LocationService.defaultLocation.longitude, closeTo(77.5946, 0.001));
    });

    test('calculateDistance returns plausible geographic distance', () {
      // Distance between Bangalore Vidhana Soudha (12.9791, 77.5913) and MG Road Metro (12.9752, 77.6065)
      final meters = LocationService.calculateDistance(12.9791, 77.5913, 12.9752, 77.6065);
      expect(meters, greaterThan(1000));
      expect(meters, lessThan(3000));
    });
  });
}
