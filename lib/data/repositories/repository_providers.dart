/// Central provider file — one ApiClient shared by every repository.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';

final tokenStoreProvider = Provider<TokenStore>((_) => TokenStore());

/// Increments when a refresh fails (session revoked/expired). The session
/// controller listens and sends the driver back to sign-in.
final sessionExpiredProvider = NotifierProvider<SessionExpiredNotifier, int>(SessionExpiredNotifier.new);

class SessionExpiredNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokens = ref.watch(tokenStoreProvider);
  return ApiClient(
    tokens,
    onSessionExpired: () => ref.read(sessionExpiredProvider.notifier).bump(),
  );
});
