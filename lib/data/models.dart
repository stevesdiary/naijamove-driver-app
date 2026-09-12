import 'package:flutter/material.dart';

/// Domain enums mirror the server's Drizzle schema names where they exist.
enum VehicleCategory {
  economy('Economy', 4, Icons.directions_car_rounded),
  comfort('Comfort', 4, Icons.directions_car_filled_rounded),
  premium('Premium', 4, Icons.star_rounded),
  xl('XL', 6, Icons.airport_shuttle_rounded);

  const VehicleCategory(this.label, this.seats, this.icon);
  final String label;
  final int seats;
  final IconData icon;
}

enum DriverStatus { offline, online, onTrip }

enum AccountStatus { pendingReview, active, suspended }

enum TripStatus {
  accepted,
  navigating,
  arrived,
  inProgress,
  completed,
  cancelledByDriver,
  cancelledByRider,
  cancelledBySystem,
  noShow,
  disputed,
}

enum PaymentMethodType {
  card('Card', Icons.credit_card_rounded),
  cash('Cash', Icons.payments_rounded),
  transfer('Transfer', Icons.account_balance_rounded);

  const PaymentMethodType(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum DocStatus {
  missing,
  uploaded,
  pendingReview,
  verified,
  rejected,
  expiringSoon,
  expired,
}

enum TxKind { trip, payout, bonus, adjustment }

enum PayoutStatus { completed, processing, failed }

enum BonusStatus { active, upcoming, completed }

enum NotificationKind { trip, earnings, bonus, safety, account }

enum CaseStatus { open, pendingUser, pendingAgent, escalated, resolved, closed }

enum MessageSender { driver, rider, agent, system }

enum DriverTier {
  bronze('Bronze', 0, 4.5, 10),
  silver('Silver', 200, 4.7, 6),
  gold('Gold', 600, 4.8, 4),
  platinum('Platinum', 1500, 4.9, 2);

  const DriverTier(this.label, this.minTrips, this.minRating, this.maxCancel);
  final String label;
  final int minTrips;
  final double minRating;
  final int maxCancel;
  DriverTier? get next =>
      index < DriverTier.values.length - 1 ? DriverTier.values[index + 1] : null;
}

class Place {
  const Place({
    required this.name,
    required this.address,
    this.area,
    this.at,
  });
  final String name;
  final String address;

  /// Short area name shown before acceptance (privacy).
  final String? area;

  /// Normalised 0..1 position on the stylised map canvas.
  final Offset? at;
}

class Rider {
  const Rider({
    required this.firstName,
    required this.rating,
    required this.trips,
    required this.payment,
  });
  final String firstName;
  final double rating;
  final int trips;
  final PaymentMethodType payment;
}

class Vehicle {
  const Vehicle({
    required this.make,
    required this.model,
    required this.year,
    required this.colour,
    required this.plate,
    required this.category,
  });
  final String make;
  final String model;
  final int year;
  final String colour;
  final String plate;
  final VehicleCategory category;
  String get title => '$colour $make $model $year';
  String get shortTitle => '$make $model';
}

class DriverProfile {
  const DriverProfile({
    required this.firstName,
    required this.lastName,
    required this.preferredName,
    required this.phone,
    this.email,
    required this.rating,
    required this.ratings,
    required this.trips,
    required this.memberSince,
    required this.bio,
    required this.tier,
    required this.languages,
    required this.acceptanceRate,
    required this.completionRate,
    required this.cancellationRate,
    required this.onTimeRate,
  });
  final String firstName;
  final String lastName;
  final String preferredName;
  final String phone;
  final String? email;
  final double rating;
  final int ratings;
  final int trips;
  final int memberSince;
  final String bio;
  final DriverTier tier;
  final List<String> languages;
  final int acceptanceRate;
  final int completionRate;
  final int cancellationRate;
  final int onTimeRate;
  String get fullName => '$firstName $lastName';
}

class TripRequest {
  const TripRequest({
    required this.id,
    required this.pickup,
    required this.destination,
    required this.distanceToPickupKm,
    required this.distanceKm,
    required this.durationMin,
    required this.fare,
    this.surge,
    required this.category,
    required this.rider,
    this.stops = const [],
  });
  final String id;
  final Place pickup;
  final Place destination;
  final double distanceToPickupKm;
  final double distanceKm;
  final int durationMin;
  final int fare;
  final double? surge;
  final VehicleCategory category;
  final Rider rider;
  final List<Place> stops;
}

class Trip {
  const Trip({
    required this.id,
    required this.pickup,
    required this.destination,
    this.stops = const [],
    required this.date,
    required this.status,
    required this.distanceKm,
    required this.durationMin,
    required this.gross,
    required this.commission,
    this.bonus = 0,
    this.tip = 0,
    required this.category,
    required this.rider,
    this.surge,
    this.cancellationFee = 0,
    this.cancelledBy,
    this.cancelReason,
    this.waitedSeconds,
    this.ratingGiven,
    this.baseFare = 600,
    this.bookingFee = 200,
  });
  final String id;
  final Place pickup;
  final Place destination;
  final List<Place> stops;
  final DateTime date;
  final TripStatus status;
  final double distanceKm;
  final int durationMin;
  final int gross;
  final int commission;
  final int bonus;
  final int tip;
  final VehicleCategory category;
  final Rider rider;
  final double? surge;
  final int cancellationFee;
  final String? cancelledBy;
  final String? cancelReason;
  final int? waitedSeconds;
  final int? ratingGiven;
  final int baseFare;
  final int bookingFee;

  int get net => gross - commission + bonus + tip;
  int get distanceCharge => gross - baseFare - bookingFee;
  bool get isCancelled =>
      status == TripStatus.cancelledByDriver ||
      status == TripStatus.cancelledByRider ||
      status == TripStatus.cancelledBySystem ||
      status == TripStatus.noShow;
  String get routeLabel => '${pickup.area ?? pickup.name} → '
      '${destination.area ?? destination.name}';
}

class ScheduledTrip {
  const ScheduledTrip({
    required this.time,
    required this.pickup,
    required this.destination,
    required this.fare,
    required this.category,
  });
  final DateTime time;
  final Place pickup;
  final Place destination;
  final int fare;
  final VehicleCategory category;
}

class Bonus {
  const Bonus({
    required this.name,
    required this.description,
    required this.progress,
    required this.target,
    required this.reward,
    required this.status,
    this.expires,
    this.startsLabel,
    this.paidOn,
    this.progressIsAmount = false,
  });
  final String name;
  final String description;
  final int progress;
  final int target;
  final int reward;
  final BonusStatus status;
  final DateTime? expires;
  final String? startsLabel;
  final DateTime? paidOn;
  final bool progressIsAmount;
  double get fraction => (progress / target).clamp(0, 1);
}

class WalletTx {
  const WalletTx({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.amount,
    this.payoutStatus,
    this.tripId,
  });
  final TxKind kind;
  final String title;
  final String subtitle;
  final DateTime date;

  /// Positive = in, negative = out.
  final int amount;
  final PayoutStatus? payoutStatus;
  final String? tripId;
}

class Payout {
  const Payout({
    required this.date,
    required this.amount,
    required this.status,
    required this.bank,
  });
  final DateTime date;
  final int amount;
  final PayoutStatus status;
  final String bank;
}

class BankAccount {
  const BankAccount({
    required this.bankName,
    required this.accountNumber,
    required this.holder,
  });
  final String bankName;
  final String accountNumber;
  final String holder;
  String get masked => '$bankName ••• ${accountNumber.substring(6)}';
}

class DriverDocument {
  const DriverDocument({
    required this.name,
    required this.status,
    this.expiry,
    this.rejectionReason,
    this.icon = Icons.description_rounded,
  });
  final String name;
  final DocStatus status;
  final DateTime? expiry;
  final String? rejectionReason;
  final IconData icon;
  DriverDocument copyWith({DocStatus? status, DateTime? expiry}) =>
      DriverDocument(
        name: name,
        status: status ?? this.status,
        expiry: expiry ?? this.expiry,
        rejectionReason: status == null ? rejectionReason : null,
        icon: icon,
      );
}

class AppNotification {
  const AppNotification({
    required this.title,
    required this.body,
    required this.time,
    required this.kind,
    this.unread = false,
  });
  final String title;
  final String body;
  final DateTime time;
  final NotificationKind kind;
  final bool unread;
}

class EmergencyContact {
  const EmergencyContact({
    required this.name,
    required this.phone,
    required this.relationship,
  });
  final String name;
  final String phone;
  final String relationship;
}

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.time,
    required this.sender,
    this.read = true,
    this.imageAttachment = false,
  });
  final String text;
  final DateTime time;
  final MessageSender sender;
  final bool read;
  final bool imageAttachment;
}

class SupportCase {
  const SupportCase({
    required this.ref,
    required this.title,
    required this.icon,
    required this.status,
    required this.preview,
    required this.updated,
    this.unread = false,
    this.messages = const [],
    this.tripLabel,
    this.resolution,
  });
  final String ref;
  final String title;
  final IconData icon;
  final CaseStatus status;
  final String preview;
  final DateTime updated;
  final bool unread;
  final List<ChatMessage> messages;
  final String? tripLabel;
  final String? resolution;
}

class Feedback {
  const Feedback({
    required this.stars,
    required this.tags,
    this.comment,
    required this.date,
  });
  final int stars;
  final List<String> tags;
  final String? comment;
  final DateTime date;
}

class FaqArticle {
  const FaqArticle({
    required this.title,
    required this.breadcrumb,
    required this.intro,
    required this.steps,
    required this.highlight,
    required this.tip,
    required this.related,
  });
  final String title;
  final String breadcrumb;
  final String intro;
  final List<String> steps;
  final String highlight;
  final String tip;
  final List<String> related;
}
