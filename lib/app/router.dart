import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/earnings/earnings_screens.dart';
import '../features/home/home_screen.dart';
import '../features/home/scheduled_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/offline/offline_screen.dart';
import '../features/onboarding/auth_screens.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/setup_screens.dart';
import '../features/onboarding/splash_screen.dart';
import '../features/performance/performance_screens.dart';
import '../features/profile/profile_screens.dart';
import '../features/support/support_screens.dart';
import '../features/trip/active_trip_screen.dart';
import '../features/trip/rider_chat_screen.dart';
import '../features/trip/trip_outcome_screens.dart';
import '../features/trips/trips_screens.dart';
import 'routes.dart';
import 'shell.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// `--dart-define=START_ROUTE=/home` jumps straight to a screen (demos, screenshots).
const startRoute = String.fromEnvironment('START_ROUTE', defaultValue: Routes.splash);

CustomTransitionPage<void> _slideUp(GoRouterState state, Widget child) => CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (_, anim, _, child) => SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );

CustomTransitionPage<void> _fade(GoRouterState state, Widget child) => CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (_, anim, _, child) => FadeTransition(opacity: anim, child: child),
    );

final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: startRoute,
  routes: [
    // Flow 1 — Onboarding & auth
    GoRoute(path: Routes.splash, pageBuilder: (_, s) => _fade(s, const SplashScreen())),
    GoRoute(path: Routes.onboarding, pageBuilder: (_, s) => _fade(s, const OnboardingScreen())),
    GoRoute(path: Routes.phone, pageBuilder: (_, s) => _fade(s, const PhoneEntryScreen())),
    GoRoute(path: Routes.otp, builder: (_, s) => OtpScreen(phone: s.extra as String? ?? '')),
    GoRoute(path: Routes.profileSetup, builder: (_, _) => const ProfileSetupScreen()),
    GoRoute(path: Routes.vehicleSetup, builder: (_, _) => const VehicleSetupScreen()),
    GoRoute(path: Routes.documents, builder: (_, _) => const DocumentUploadScreen()),
    GoRoute(path: Routes.underReview, pageBuilder: (_, s) => _fade(s, const UnderReviewScreen())),
    GoRoute(path: Routes.permissions, pageBuilder: (_, s) => _fade(s, const PermissionsScreen())),

    // Shell tabs
    StatefulShellRoute.indexedStack(
      builder: (_, _, shell) => AppShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen(), routes: [
            GoRoute(path: 'scheduled', parentNavigatorKey: _rootKey, builder: (_, _) => const ScheduledTripsScreen()),
          ]),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: Routes.trips, builder: (_, _) => const TripsScreen(), routes: [
            GoRoute(path: ':id', parentNavigatorKey: _rootKey, builder: (_, s) => CancelledTripScreen(tripId: s.pathParameters['id']!)),
          ]),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: Routes.earnings, builder: (_, _) => const EarningsScreen(), routes: [
            GoRoute(path: 'wallet', parentNavigatorKey: _rootKey, builder: (_, _) => const WalletScreen()),
            GoRoute(path: 'withdraw', parentNavigatorKey: _rootKey, builder: (_, _) => const WithdrawScreen()),
            GoRoute(path: 'bonuses', parentNavigatorKey: _rootKey, builder: (_, _) => const BonusesScreen()),
            GoRoute(path: 'bank', parentNavigatorKey: _rootKey, builder: (_, _) => const LinkBankScreen()),
            GoRoute(path: 'transactions', parentNavigatorKey: _rootKey, builder: (_, _) => const TransactionsScreen()),
            GoRoute(path: 'trip/:id', parentNavigatorKey: _rootKey, builder: (_, s) => TripEarningsDetailScreen(tripId: s.pathParameters['id']!)),
          ]),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: Routes.profile, builder: (_, _) => const ProfileScreen(), routes: [
            GoRoute(path: 'vehicle', parentNavigatorKey: _rootKey, builder: (_, _) => const VehicleScreen()),
            GoRoute(path: 'emergency', parentNavigatorKey: _rootKey, builder: (_, _) => const EmergencyContactScreen()),
            GoRoute(path: 'safety', parentNavigatorKey: _rootKey, builder: (_, _) => const SafetySettingsScreen()),
            GoRoute(path: 'documents', parentNavigatorKey: _rootKey, builder: (_, _) => const DocumentStatusScreen()),
            GoRoute(path: 'public', parentNavigatorKey: _rootKey, builder: (_, _) => const PublicProfileScreen()),
            GoRoute(path: 'settings', parentNavigatorKey: _rootKey, builder: (_, _) => const SettingsScreen()),
            GoRoute(path: 'edit', parentNavigatorKey: _rootKey, builder: (_, _) => const EditProfileScreen()),
            GoRoute(path: 'performance', parentNavigatorKey: _rootKey, builder: (_, _) => const PerformanceScreen()),
            GoRoute(path: 'top-driver', parentNavigatorKey: _rootKey, builder: (_, _) => const TopDriverScreen()),
          ]),
        ]),
      ],
    ),

    // Flow 3 — Active trip (full-screen, outside the shell)
    GoRoute(
      path: Routes.activeTrip,
      pageBuilder: (_, s) => _fade(s, ActiveTripScreen(justAccepted: s.extra == true)),
      routes: [
        GoRoute(path: 'completed', pageBuilder: (_, s) => _slideUp(s, const TripCompletedScreen())),
        GoRoute(path: 'cancel', pageBuilder: (_, s) => _slideUp(s, const CancelTripScreen())),
        GoRoute(path: 'rider-cancelled', pageBuilder: (_, s) => _fade(s, const RiderCancelledScreen())),
        GoRoute(path: 'no-show', pageBuilder: (_, s) => _slideUp(s, const NoShowScreen())),
        GoRoute(path: 'sos', pageBuilder: (_, s) => _fade(s, const SosScreen())),
        GoRoute(path: 'chat', pageBuilder: (_, s) => _slideUp(s, const RiderChatScreen())),
      ],
    ),

    // Flow 7 / 9 / 10
    GoRoute(path: Routes.notifications, builder: (_, _) => const NotificationsScreen()),
    GoRoute(
      path: Routes.support,
      builder: (_, _) => const SupportHomeScreen(),
      routes: [
        GoRoute(
          path: 'new',
          builder: (_, s) => IssueCategoryScreen(tripId: s.extra as String?),
          routes: [
            GoRoute(
              path: 'form',
              builder: (_, s) {
                final extra = s.extra;
                if (extra is ({String category, String? tripId})) {
                  return IssueFormScreen(category: extra.category, tripId: extra.tripId);
                }
                return const IssueFormScreen(category: 'Other — describe your issue');
              },
            ),
            GoRoute(path: 'done', pageBuilder: (_, s) => _fade(s, CaseSubmittedScreen(category: s.extra as String?))),
          ],
        ),
        GoRoute(path: 'cases', builder: (_, _) => const CasesScreen(), routes: [
          GoRoute(path: ':ref', builder: (_, s) => CaseDetailScreen(caseRef: s.pathParameters['ref']!)),
        ]),
        GoRoute(path: 'faq', builder: (_, _) => const FaqScreen()),
      ],
    ),
    GoRoute(path: Routes.offline, pageBuilder: (_, s) => _fade(s, const OfflineScreen())),
  ],
);
