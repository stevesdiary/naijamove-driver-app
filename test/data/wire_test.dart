import 'package:flutter_test/flutter_test.dart';
import 'package:naijamove_driver/data/api/wire.dart';

void main() {
  group('wire models', () {
    test('TripOffer parses the enriched offer payload', () {
      final o = TripOffer.fromJson({
        'id': 'off_1',
        'tripId': 'trp_1',
        'status': 'pending',
        'estimatedPickupSeconds': 240,
        'expiresAt': DateTime.now().add(const Duration(minutes: 1)).toUtc().toIso8601String(),
        'trip': {
          'id': 'trp_1',
          'pickupAddress': 'VI',
          'pickupLat': 6.4281,
          'pickupLng': 3.4219,
          'destinationAddress': 'Ikeja',
          'destinationLat': 6.6018,
          'destinationLng': 3.3515,
          'distanceMeters': 8400,
          'durationSeconds': 1560,
          'estimatedFareKobo': 185000,
          'driverAmountKobo': 170200,
          'surgeMultiplier': 1.4,
          'paymentMethod': 'card',
        },
      });
      expect(o.isExpired, isFalse);
      expect(o.trip?.driverAmountKobo, 170200);
      expect(o.trip?.surgeMultiplier, 1.4);
    });

    test('DriverTrip prefers finalFare over estimate and never reads a PIN', () {
      final t = DriverTrip.fromJson({
        'id': 'trp_1',
        'status': 'completed',
        'pickupAddress': 'A', 'pickupLat': 1, 'pickupLng': 2,
        'destinationAddress': 'B', 'destinationLat': 3, 'destinationLng': 4,
        'estimatedFareKobo': 1000, 'finalFareKobo': 1200, 'driverAmountKobo': 1100, 'tipKobo': 50,
        'createdAt': '2026-09-13T00:00:00Z',
      });
      expect(t.status, WireTripStatus.completed);
      expect(t.fareKobo, 1200);
      expect(t.status.isActive, isFalse);
    });

    test('DriverAccountStatus gates going online on approval', () {
      expect(DriverAccountStatus.fromWire('approved').canGoOnline, isTrue);
      expect(DriverAccountStatus.fromWire('under_review').canGoOnline, isFalse);
      expect(DriverAccountStatus.fromWire('garbage'), DriverAccountStatus.pending);
    });

    test('numeric fields tolerate strings (bigint columns serialise as strings)', () {
      final a = DriverAccount.fromJson({'id': 'd', 'userId': 'u', 'status': 'approved', 'isOnline': true, 'rating': '4.8', 'totalTrips': '1240'});
      expect(a.rating, 4.8);
      expect(a.totalTrips, 1240);
    });
  });
}
