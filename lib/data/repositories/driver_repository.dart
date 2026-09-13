import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_config.dart';
import '../api/wire.dart';
import 'repository_providers.dart';

/// Driver account: profile, availability, GPS, earnings, documents.
class DriverRepository {
  const DriverRepository(this._api);
  final ApiClient _api;

  /// GET /drivers/me
  Future<DriverAccount> getAccount() async {
    if (ApiConfig.useMock) {
      return const DriverAccount(id: 'mock_driver', userId: 'mock_user', status: DriverAccountStatus.approved, isOnline: false, rating: 4.9, totalTrips: 1240);
    }
    return DriverAccount.fromJson(await _api.getJson('/drivers/me'));
  }

  /// POST /drivers/availability — 403 unless the account is `approved`.
  Future<DriverAccount> setOnline(bool isOnline) async {
    if (ApiConfig.useMock) {
      return DriverAccount(id: 'mock_driver', userId: 'mock_user', status: DriverAccountStatus.approved, isOnline: isOnline, rating: 4.9, totalTrips: 1240);
    }
    return DriverAccount.fromJson(await _api.postJson('/drivers/availability', body: {'isOnline': isOnline}));
  }

  /// POST /drivers/location — coarse position for dispatch (the trip channel streams the fine-grained feed).
  Future<void> updateLocation({required double lat, required double lng}) async {
    if (ApiConfig.useMock) return;
    await _api.postJson('/drivers/location', body: {'lat': lat, 'lng': lng});
  }

  /// GET /drivers/earnings
  Future<Earnings> getEarnings() async {
    if (ApiConfig.useMock) {
      return const Earnings(totalKobo: 184500000, thisWeekKobo: 4250000, thisMonthKobo: 16800000, pendingPayoutKobo: 1200000);
    }
    return Earnings.fromJson(await _api.getJson('/drivers/earnings'));
  }

  /// GET /drivers/documents
  Future<List<DriverDocumentRecord>> listDocuments() async {
    if (ApiConfig.useMock) return const [];
    final list = await _api.getList('/drivers/documents');
    return list.map((e) => DriverDocumentRecord.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// POST /drivers/documents — [fileUrl] must already be uploaded to storage.
  Future<DriverDocumentRecord> submitDocument({
    required DriverDocumentType type,
    String? fileUrl,
    String? referenceNumber,
    DateTime? expiresAt,
  }) async {
    if (ApiConfig.useMock) {
      return DriverDocumentRecord(id: 'mock_doc', type: type, fileUrl: fileUrl, referenceNumber: referenceNumber, expiresAt: expiresAt);
    }
    final j = await _api.postJson('/drivers/documents', body: {
      'type': type.wire,
      'fileUrl': ?fileUrl,
      'referenceNumber': ?referenceNumber,
      'expiresAt': ?expiresAt?.toUtc().toIso8601String(),
    });
    return DriverDocumentRecord.fromJson(j);
  }
}

final driverRepositoryProvider = Provider<DriverRepository>(
  (ref) => DriverRepository(ref.watch(apiClientProvider)),
);

/// The driver's account row — refreshed after going online/offline or registering.
final driverAccountProvider = AsyncNotifierProvider<DriverAccountNotifier, DriverAccount>(DriverAccountNotifier.new);

class DriverAccountNotifier extends AsyncNotifier<DriverAccount> {
  @override
  Future<DriverAccount> build() => ref.watch(driverRepositoryProvider).getAccount();

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => ref.read(driverRepositoryProvider).getAccount());
  }

  Future<void> setOnline(bool isOnline) async {
    state = await AsyncValue.guard(() => ref.read(driverRepositoryProvider).setOnline(isOnline));
  }
}
