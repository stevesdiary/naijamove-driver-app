import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_config.dart';
import '../api/wire.dart';
import 'repository_providers.dart';

/// Driver wallet: earnings land in `driver_payable`; withdrawals go to a bank account.
class WalletRepository {
  const WalletRepository(this._api);
  final ApiClient _api;

  /// GET /wallet/balance
  Future<WalletBalance> balance() async {
    if (ApiConfig.useMock) return const WalletBalance(balanceKobo: 4250000, currency: 'NGN');
    return WalletBalance.fromJson(await _api.getJson('/wallet/balance'));
  }

  /// GET /wallet/transactions
  Future<List<WalletTransaction>> transactions({int limit = 50, int offset = 0}) async {
    if (ApiConfig.useMock) return const [];
    final list = await _api.getList('/wallet/transactions', query: {'limit': '$limit', 'offset': '$offset'});
    return list.map((e) => WalletTransaction.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// POST /wallet/withdraw → new balance. 422 on insufficient funds.
  Future<int> withdraw({
    required int amountKobo,
    required String bankCode,
    required String accountNumber,
    required String accountName,
  }) async {
    if (ApiConfig.useMock) return 4250000 - amountKobo;
    final j = await _api.postJson('/wallet/withdraw', body: {
      'amountKobo': amountKobo,
      'bankCode': bankCode,
      'accountNumber': accountNumber,
      'accountName': accountName,
    });
    return (j['balanceKobo'] as num?)?.toInt() ?? 0;
  }
}

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => WalletRepository(ref.watch(apiClientProvider)),
);

final walletBalanceProvider = AsyncNotifierProvider<WalletBalanceNotifier, WalletBalance>(WalletBalanceNotifier.new);

class WalletBalanceNotifier extends AsyncNotifier<WalletBalance> {
  @override
  Future<WalletBalance> build() => ref.watch(walletRepositoryProvider).balance();

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => ref.read(walletRepositoryProvider).balance());
  }
}
