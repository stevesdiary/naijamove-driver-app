/// Wire models — 1:1 with what the server returns on driver-facing routes.
/// Screens map these onto the richer UI models in `models.dart`.
library;

int _int(dynamic v, [int fallback = 0]) => v is num ? v.toInt() : int.tryParse('$v') ?? fallback;
double _dbl(dynamic v, [double fallback = 0]) => v is num ? v.toDouble() : double.tryParse('$v') ?? fallback;
DateTime? _date(dynamic v) => v == null ? null : DateTime.tryParse('$v');

class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});
  final String accessToken;
  final String refreshToken;
  factory AuthTokens.fromJson(Map<String, dynamic> j) =>
      AuthTokens(accessToken: j['accessToken'] as String, refreshToken: j['refreshToken'] as String);
}

/// Result of OTP verification. `role` decides where onboarding sends the user:
/// a `rider` must call `/drivers/register`; a `driver` goes straight in.
class LoginResult {
  const LoginResult({required this.tokens, required this.userId, required this.isNewUser, required this.role, this.name});
  final AuthTokens tokens;
  final String userId;
  final bool isNewUser;
  final String role;
  final String? name;
}

/// `drivers` row — the account's operational state.
enum DriverAccountStatus {
  pending, underReview, approved, suspended, rejected, expired;

  static DriverAccountStatus fromWire(String? s) => switch (s) {
        'under_review' => DriverAccountStatus.underReview,
        'approved' => DriverAccountStatus.approved,
        'suspended' => DriverAccountStatus.suspended,
        'rejected' => DriverAccountStatus.rejected,
        'expired' => DriverAccountStatus.expired,
        _ => DriverAccountStatus.pending,
      };

  bool get canGoOnline => this == DriverAccountStatus.approved;
}

class DriverAccount {
  const DriverAccount({
    required this.id,
    required this.userId,
    required this.status,
    required this.isOnline,
    required this.rating,
    required this.totalTrips,
    this.currentLat,
    this.currentLng,
  });
  final String id;
  final String userId;
  final DriverAccountStatus status;
  final bool isOnline;
  final double rating;
  final int totalTrips;
  final double? currentLat;
  final double? currentLng;

  factory DriverAccount.fromJson(Map<String, dynamic> j) => DriverAccount(
        id: '${j['id']}',
        userId: '${j['userId']}',
        status: DriverAccountStatus.fromWire(j['status']?.toString()),
        isOnline: j['isOnline'] == true,
        rating: _dbl(j['rating'], 5),
        totalTrips: _int(j['totalTrips']),
        currentLat: j['currentLat'] == null ? null : _dbl(j['currentLat']),
        currentLng: j['currentLng'] == null ? null : _dbl(j['currentLng']),
      );
}

/// Trip summary attached to a pending offer. No PIN, no rider identity.
class OfferTrip {
  const OfferTrip({
    required this.id,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.destinationAddress,
    required this.destinationLat,
    required this.destinationLng,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.estimatedFareKobo,
    required this.driverAmountKobo,
    required this.surgeMultiplier,
    this.paymentMethod,
    this.scheduledFor,
  });
  final String id;
  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final String destinationAddress;
  final double destinationLat;
  final double destinationLng;
  final int distanceMeters;
  final int durationSeconds;
  final int estimatedFareKobo;
  final int driverAmountKobo;
  final double surgeMultiplier;
  final String? paymentMethod;
  final DateTime? scheduledFor;

  factory OfferTrip.fromJson(Map<String, dynamic> j) => OfferTrip(
        id: '${j['id']}',
        pickupAddress: '${j['pickupAddress'] ?? ''}',
        pickupLat: _dbl(j['pickupLat']),
        pickupLng: _dbl(j['pickupLng']),
        destinationAddress: '${j['destinationAddress'] ?? ''}',
        destinationLat: _dbl(j['destinationLat']),
        destinationLng: _dbl(j['destinationLng']),
        distanceMeters: _int(j['distanceMeters']),
        durationSeconds: _int(j['durationSeconds']),
        estimatedFareKobo: _int(j['estimatedFareKobo']),
        driverAmountKobo: _int(j['driverAmountKobo']),
        surgeMultiplier: _dbl(j['surgeMultiplier'], 1),
        paymentMethod: j['paymentMethod']?.toString(),
        scheduledFor: _date(j['scheduledFor']),
      );
}

class TripOffer {
  const TripOffer({
    required this.id,
    required this.tripId,
    required this.expiresAt,
    this.estimatedPickupSeconds,
    this.trip,
  });
  final String id;
  final String tripId;
  final DateTime expiresAt;
  final int? estimatedPickupSeconds;
  final OfferTrip? trip;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory TripOffer.fromJson(Map<String, dynamic> j) => TripOffer(
        id: '${j['id']}',
        tripId: '${j['tripId']}',
        expiresAt: _date(j['expiresAt']) ?? DateTime.now(),
        estimatedPickupSeconds: j['estimatedPickupSeconds'] == null ? null : _int(j['estimatedPickupSeconds']),
        trip: j['trip'] is Map ? OfferTrip.fromJson(Map<String, dynamic>.from(j['trip'] as Map)) : null,
      );
}

/// Server trip status as the driver sees it.
enum WireTripStatus {
  requested, matched, driverArriving, driverArrived, inProgress, completed, cancelled;

  static WireTripStatus fromWire(String? s) => switch (s) {
        'matched' => WireTripStatus.matched,
        'driver_arriving' => WireTripStatus.driverArriving,
        'driver_arrived' => WireTripStatus.driverArrived,
        'in_progress' => WireTripStatus.inProgress,
        'completed' => WireTripStatus.completed,
        'cancelled' => WireTripStatus.cancelled,
        _ => WireTripStatus.requested,
      };

  bool get isActive => this == matched || this == driverArriving || this == driverArrived || this == inProgress;
}

/// A `trips` row from `/rides/driver/me` (PIN is never included).
class DriverTrip {
  const DriverTrip({
    required this.id,
    required this.status,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.destinationAddress,
    required this.destinationLat,
    required this.destinationLng,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.estimatedFareKobo,
    required this.driverAmountKobo,
    required this.tipKobo,
    required this.createdAt,
    this.finalFareKobo,
    this.paymentMethod,
    this.cancelledBy,
    this.cancellationReason,
    this.completedAt,
  });
  final String id;
  final WireTripStatus status;
  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final String destinationAddress;
  final double destinationLat;
  final double destinationLng;
  final int distanceMeters;
  final int durationSeconds;
  final int estimatedFareKobo;
  final int? finalFareKobo;
  final int driverAmountKobo;
  final int tipKobo;
  final String? paymentMethod;
  final String? cancelledBy;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime? completedAt;

  int get fareKobo => finalFareKobo ?? estimatedFareKobo;

  factory DriverTrip.fromJson(Map<String, dynamic> j) => DriverTrip(
        id: '${j['id']}',
        status: WireTripStatus.fromWire(j['status']?.toString()),
        pickupAddress: '${j['pickupAddress'] ?? ''}',
        pickupLat: _dbl(j['pickupLat']),
        pickupLng: _dbl(j['pickupLng']),
        destinationAddress: '${j['destinationAddress'] ?? ''}',
        destinationLat: _dbl(j['destinationLat']),
        destinationLng: _dbl(j['destinationLng']),
        distanceMeters: _int(j['distanceMeters']),
        durationSeconds: _int(j['durationSeconds']),
        estimatedFareKobo: _int(j['estimatedFareKobo']),
        finalFareKobo: j['finalFareKobo'] == null ? null : _int(j['finalFareKobo']),
        driverAmountKobo: _int(j['driverAmountKobo']),
        tipKobo: _int(j['tipKobo']),
        paymentMethod: j['paymentMethod']?.toString(),
        cancelledBy: j['cancelledBy']?.toString(),
        cancellationReason: j['cancellationReason']?.toString(),
        createdAt: _date(j['createdAt']) ?? DateTime.now(),
        completedAt: _date(j['completedAt']),
      );
}

class Earnings {
  const Earnings({required this.totalKobo, required this.thisWeekKobo, required this.thisMonthKobo, required this.pendingPayoutKobo});
  final int totalKobo;
  final int thisWeekKobo;
  final int thisMonthKobo;
  final int pendingPayoutKobo;
  factory Earnings.fromJson(Map<String, dynamic> j) => Earnings(
        totalKobo: _int(j['totalEarningsKobo']),
        thisWeekKobo: _int(j['thisWeekKobo']),
        thisMonthKobo: _int(j['thisMonthKobo']),
        pendingPayoutKobo: _int(j['pendingPayoutKobo']),
      );
}

enum DriverDocumentType {
  driversLicence('drivers_licence'),
  vehicleRegistration('vehicle_registration'),
  insurance('insurance'),
  inspection('inspection'),
  backgroundCheck('background_check'),
  profilePhoto('profile_photo');

  const DriverDocumentType(this.wire);
  final String wire;
  static DriverDocumentType? fromWire(String? s) => values.where((v) => v.wire == s).firstOrNull;
}

class DriverDocumentRecord {
  const DriverDocumentRecord({
    required this.id,
    required this.type,
    this.fileUrl,
    this.referenceNumber,
    this.expiresAt,
    this.verifiedAt,
    this.rejectedAt,
    this.rejectionReason,
  });
  final String id;
  final DriverDocumentType? type;
  final String? fileUrl;
  final String? referenceNumber;
  final DateTime? expiresAt;
  final DateTime? verifiedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;

  bool get isVerified => verifiedAt != null && rejectedAt == null;
  bool get isRejected => rejectedAt != null;

  factory DriverDocumentRecord.fromJson(Map<String, dynamic> j) => DriverDocumentRecord(
        id: '${j['id']}',
        type: DriverDocumentType.fromWire(j['type']?.toString()),
        fileUrl: j['fileUrl']?.toString(),
        referenceNumber: j['referenceNumber']?.toString(),
        expiresAt: _date(j['expiresAt']),
        verifiedAt: _date(j['verifiedAt']),
        rejectedAt: _date(j['rejectedAt']),
        rejectionReason: j['rejectionReason']?.toString(),
      );
}

class WalletBalance {
  const WalletBalance({required this.balanceKobo, required this.currency});
  final int balanceKobo;
  final String currency;
  factory WalletBalance.fromJson(Map<String, dynamic> j) =>
      WalletBalance(balanceKobo: _int(j['balanceKobo']), currency: '${j['currency'] ?? 'NGN'}');
}

class WalletTransaction {
  const WalletTransaction({required this.id, required this.isCredit, required this.amountKobo, required this.description, required this.createdAt, this.referenceType});
  final String id;
  final bool isCredit;
  final int amountKobo;
  final String description;
  final String? referenceType;
  final DateTime createdAt;
  factory WalletTransaction.fromJson(Map<String, dynamic> j) => WalletTransaction(
        id: '${j['id']}',
        isCredit: j['type'] == 'credit',
        amountKobo: _int(j['amountKobo']),
        description: '${j['description'] ?? ''}',
        referenceType: j['referenceType']?.toString(),
        createdAt: _date(j['createdAt']) ?? DateTime.now(),
      );
}
