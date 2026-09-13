import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/wire.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/repository_providers.dart';

/// Where the signed-in user is in the driver funnel.
enum SessionStage {
  /// No tokens.
  signedOut,

  /// Signed in as a `rider` — must call `/drivers/register` to become a driver.
  needsDriverProfile,

  /// Driver profile exists but is not `approved` (pending docs / review / suspended).
  awaitingApproval,

  /// Approved driver.
  active,
}

class Session {
  const Session({this.stage = SessionStage.signedOut, this.userId, this.name, this.account});
  final SessionStage stage;
  final String? userId;
  final String? name;
  final DriverAccount? account;

  bool get isSignedIn => stage != SessionStage.signedOut;

  Session copyWith({SessionStage? stage, String? userId, String? name, DriverAccount? account}) => Session(
        stage: stage ?? this.stage,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        account: account ?? this.account,
      );
}

class SessionController extends Notifier<Session> {
  @override
  Session build() {
    // A failed refresh anywhere in the app signs the driver out.
    ref.listen(sessionExpiredProvider, (_, _) => state = const Session());
    return const Session();
  }

  /// After OTP verify. Tokens are already persisted by the repository.
  void loginFrom(LoginResult r) {
    state = Session(
      stage: r.role == 'driver' ? SessionStage.awaitingApproval : SessionStage.needsDriverProfile,
      userId: r.userId,
      name: r.name,
    );
  }

  /// After /drivers/register or a fresh /drivers/me read.
  void applyAccount(DriverAccount account) {
    state = state.copyWith(
      account: account,
      stage: account.status.canGoOnline ? SessionStage.active : SessionStage.awaitingApproval,
    );
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const Session();
  }
}

final sessionProvider = NotifierProvider<SessionController, Session>(SessionController.new);
