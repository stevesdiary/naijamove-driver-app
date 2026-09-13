import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_config.dart';
import '../../data/api/trip_channel.dart';
import '../../data/api/wire.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../data/repositories/repository_providers.dart';
import '../../data/repositories/trips_repository.dart';

/// Where the driver is in the trip they've accepted.
enum TripPhase { navigating, arrived, inProgress, completed }

class ActiveTrip {
  const ActiveTrip({
    required this.tripId,
    required this.request,
    this.phase = TripPhase.navigating,
    this.acceptedAt,
    this.arrivedAt,
    this.startedAt,
    this.finalFareKobo,
    this.driverAmountKobo,
    this.stopsDone = 0,
  });
  final String tripId;
  final TripRequest request;
  final TripPhase phase;
  final DateTime? acceptedAt;
  final DateTime? arrivedAt;
  final DateTime? startedAt;
  final int? finalFareKobo;
  final int? driverAmountKobo;
  final int stopsDone;

  ActiveTrip copyWith({TripPhase? phase, DateTime? arrivedAt, DateTime? startedAt, int? finalFareKobo, int? driverAmountKobo, int? stopsDone}) =>
      ActiveTrip(
        tripId: tripId,
        request: request,
        phase: phase ?? this.phase,
        acceptedAt: acceptedAt,
        arrivedAt: arrivedAt ?? this.arrivedAt,
        startedAt: startedAt ?? this.startedAt,
        finalFareKobo: finalFareKobo ?? this.finalFareKobo,
        driverAmountKobo: driverAmountKobo ?? this.driverAmountKobo,
        stopsDone: stopsDone ?? this.stopsDone,
      );
}

/// Converts a server offer into the UI's [TripRequest]. The rider is anonymous
/// until acceptance, so rating/trips come through as neutral placeholders.
TripRequest requestFromOffer(TripOffer o) {
  final t = o.trip!;
  final rnd = math.Random(o.id.hashCode);
  Offset spot() => Offset(0.2 + rnd.nextDouble() * 0.6, 0.2 + rnd.nextDouble() * 0.6);
  return TripRequest(
    id: o.id,
    pickup: Place(name: t.pickupAddress.split(',').first, address: t.pickupAddress, area: t.pickupAddress.split(',').last.trim(), at: spot()),
    destination: Place(name: t.destinationAddress.split(',').first, address: t.destinationAddress, area: t.destinationAddress.split(',').last.trim(), at: spot()),
    distanceToPickupKm: ((o.estimatedPickupSeconds ?? 240) / 60 * 0.4 * 10).round() / 10,
    distanceKm: (t.distanceMeters / 100).round() / 10,
    durationMin: (t.durationSeconds / 60).round(),
    fare: (t.estimatedFareKobo / 100).round(),
    surge: t.surgeMultiplier > 1 ? t.surgeMultiplier : null,
    category: VehicleCategory.economy,
    rider: Rider(
      firstName: 'Rider',
      rating: 5,
      trips: 0,
      payment: switch (t.paymentMethod) {
        'cash' => PaymentMethodType.cash,
        'bank_transfer' => PaymentMethodType.transfer,
        _ => PaymentMethodType.card,
      },
    ),
  );
}

/// Drives the accepted trip through its phases, calling the API and
/// streaming GPS over the trip channel while the trip is live.
class ActiveTripController extends Notifier<ActiveTrip?> {
  DriverTripChannel? _channel;
  Timer? _gps;

  @override
  ActiveTrip? build() {
    ref.onDispose(_teardown);
    return null;
  }

  TripsRepository get _repo => ref.read(tripsRepositoryProvider);

  Future<void> accept(TripRequest request, {String? offerId}) async {
    final tripId = await _repo.acceptOffer(offerId ?? request.id);
    state = ActiveTrip(tripId: tripId, request: request, acceptedAt: DateTime.now());
    await _openChannel(tripId);
  }

  Future<void> decline(String offerId, {String? reason}) => _repo.declineOffer(offerId, reason: reason);

  Future<void> arrived() async {
    final t = state;
    if (t == null) return;
    await _repo.arrived(t.tripId);
    _channel?.sendState('arrived');
    state = t.copyWith(phase: TripPhase.arrived, arrivedAt: DateTime.now());
  }

  Future<void> startWithPin(String pin) async {
    final t = state;
    if (t == null) return;
    await _repo.startWithPin(t.tripId, pin);
    _channel?.sendState('started');
    state = t.copyWith(phase: TripPhase.inProgress, startedAt: DateTime.now());
  }

  void stopReached() {
    final t = state;
    if (t == null) return;
    state = t.copyWith(stopsDone: t.stopsDone + 1);
  }

  Future<void> complete() async {
    final t = state;
    if (t == null) return;
    final elapsed = DateTime.now().difference(t.startedAt ?? DateTime.now()).inSeconds;
    final r = await _repo.complete(
      t.tripId,
      finalDistanceMeters: (t.request.distanceKm * 1000).round(),
      finalDurationSeconds: math.max(elapsed, t.request.durationMin * 60),
    );
    state = t.copyWith(phase: TripPhase.completed, finalFareKobo: r.finalFareKobo, driverAmountKobo: r.driverAmountKobo);
    _teardown();
  }

  Future<void> cancel(String reason) async {
    final t = state;
    if (t == null) return;
    await _repo.cancel(t.tripId, reason: reason);
    clear();
  }

  /// The rider cancelled or never showed — drop local state without a server call.
  void clear() {
    _teardown();
    state = null;
  }

  Future<void> _openChannel(String tripId) async {
    if (ApiConfig.useMock) return;
    final ch = DriverTripChannel(tripId: tripId, tokens: ref.read(tokenStoreProvider));
    try {
      await ch.connect();
    } catch (_) {
      return; // REST calls remain the source of truth; live GPS is best-effort.
    }
    _channel = ch;
    // Device GPS integration lands with the location plugin; until then stream the
    // request's pickup as a stand-in so the rider sees a moving marker.
    _gps = Timer.periodic(ApiConfig.locationInterval, (_) {
      final at = state?.request.pickup.at ?? const Offset(0.5, 0.5);
      ch.sendLocation(lat: 6.4 + at.dy * 0.3, lng: 3.3 + at.dx * 0.3);
    });
    unawaited(ch.done.whenComplete(() => _gps?.cancel()));
  }

  void _teardown() {
    _gps?.cancel();
    _gps = null;
    unawaited(_channel?.close());
    _channel = null;
  }
}

final activeTripProvider = NotifierProvider<ActiveTripController, ActiveTrip?>(ActiveTripController.new);

/// Incoming offers while online. Mock mode fires one demo request a few
/// seconds after going online; live mode polls `/dispatch/offers/me`.
class IncomingOfferController extends Notifier<TripRequest?> {
  Timer? _timer;
  String? _offerId;

  @override
  TripRequest? build() {
    ref.onDispose(() => _timer?.cancel());
    return null;
  }

  String? get offerId => _offerId;

  void startListening() {
    _timer?.cancel();
    if (ApiConfig.useMock) {
      _timer = Timer(const Duration(seconds: 4), () {
        _offerId = MockData.request.id;
        state = MockData.request;
      });
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (state != null) return;
      try {
        final offers = await ref.read(tripsRepositoryProvider).pendingOffers();
        final o = offers.where((o) => o.trip != null).firstOrNull;
        if (o != null) {
          _offerId = o.id;
          state = requestFromOffer(o);
        }
      } catch (_) {
        // Transient — try again next tick.
      }
    });
  }

  void stopListening() {
    _timer?.cancel();
    state = null;
  }

  void dismiss() {
    state = null;
    _offerId = null;
    // Keep polling for the next one.
  }
}

final incomingOfferProvider = NotifierProvider<IncomingOfferController, TripRequest?>(IncomingOfferController.new);
