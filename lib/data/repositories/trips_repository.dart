import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_config.dart';
import '../api/wire.dart';
import 'repository_providers.dart';

/// Offers and the driver-side trip lifecycle:
/// offer → accept → arrive → start(PIN) → complete → rate.
class TripsRepository {
  const TripsRepository(this._api);
  final ApiClient _api;

  /// GET /dispatch/offers/me — pending, unexpired offers with trip summaries.
  Future<List<TripOffer>> pendingOffers() async {
    if (ApiConfig.useMock) return const [];
    final list = await _api.getList('/dispatch/offers/me', key: 'offers');
    return list
        .map((e) => TripOffer.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((o) => !o.isExpired)
        .toList();
  }

  /// POST /rides/offers/:offerId/accept → { tripId, status }
  Future<String> acceptOffer(String offerId) async {
    if (ApiConfig.useMock) return 'mock_trip';
    final j = await _api.postJson('/rides/offers/$offerId/accept');
    return '${j['tripId']}';
  }

  /// POST /rides/offers/:offerId/decline
  Future<void> declineOffer(String offerId, {String? reason}) async {
    if (ApiConfig.useMock) return;
    await _api.postJson('/rides/offers/$offerId/decline', body: {'reason': ?reason});
  }

  /// POST /rides/driver/trips/:tripId/arrive
  Future<void> arrived(String tripId) async {
    if (ApiConfig.useMock) return;
    await _api.postJson('/rides/driver/trips/$tripId/arrive');
  }

  /// POST /rides/driver/trips/:tripId/start — the rider reads their 4-digit PIN to the driver.
  /// 401 on a wrong PIN; 422 after 5 wrong attempts (contact support).
  Future<void> startWithPin(String tripId, String pin) async {
    if (ApiConfig.useMock) {
      if (pin == '0000') throw const ApiException('UNAUTHORIZED', 'Invalid or already used PIN', statusCode: 401);
      return;
    }
    await _api.postJson('/rides/driver/trips/$tripId/start', body: {'pin': pin});
  }

  /// POST /rides/driver/trips/:tripId/complete → { finalFareKobo, driverAmountKobo }
  Future<({int finalFareKobo, int driverAmountKobo})> complete(
    String tripId, {
    required int finalDistanceMeters,
    required int finalDurationSeconds,
  }) async {
    if (ApiConfig.useMock) return (finalFareKobo: 185000, driverAmountKobo: 170200);
    final j = await _api.postJson('/rides/driver/trips/$tripId/complete', body: {
      'finalDistanceMeters': finalDistanceMeters,
      'finalDurationSeconds': finalDurationSeconds,
    });
    return (
      finalFareKobo: (j['finalFareKobo'] as num?)?.toInt() ?? 0,
      driverAmountKobo: (j['driverAmountKobo'] as num?)?.toInt() ?? 0,
    );
  }

  /// POST /rides/driver/trips/:tripId/cancel
  Future<void> cancel(String tripId, {required String reason}) async {
    if (ApiConfig.useMock) return;
    await _api.postJson('/rides/driver/trips/$tripId/cancel', body: {'reason': reason});
  }

  /// POST /rides/driver/trips/:tripId/rate
  Future<void> rateRider(String tripId, {required int rating, String? comment}) async {
    if (ApiConfig.useMock) return;
    await _api.postJson('/rides/driver/trips/$tripId/rate', body: {
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
  }

  /// GET /rides/driver/me — history, newest first. `limit` is capped at 100 server-side.
  Future<List<DriverTrip>> history({int limit = 20, int offset = 0}) async {
    if (ApiConfig.useMock) return const [];
    final list = await _api.getList('/rides/driver/me', query: {'limit': '$limit', 'offset': '$offset'});
    return list.map((e) => DriverTrip.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }
}

final tripsRepositoryProvider = Provider<TripsRepository>(
  (ref) => TripsRepository(ref.watch(apiClientProvider)),
);
