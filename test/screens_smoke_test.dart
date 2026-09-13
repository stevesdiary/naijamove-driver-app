import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naijamove_driver/app/state/session.dart';
import 'package:naijamove_driver/app/theme/app_theme.dart';
import 'package:naijamove_driver/data/mock_data.dart';
import 'package:naijamove_driver/features/earnings/earnings_screens.dart';
import 'package:naijamove_driver/features/home/home_screen.dart';
import 'package:naijamove_driver/features/home/request_sheet.dart';
import 'package:naijamove_driver/features/home/scheduled_screen.dart';
import 'package:naijamove_driver/features/notifications/notifications_screen.dart';
import 'package:naijamove_driver/features/offline/offline_screen.dart';
import 'package:naijamove_driver/features/onboarding/auth_screens.dart';
import 'package:naijamove_driver/features/onboarding/onboarding_screen.dart';
import 'package:naijamove_driver/features/onboarding/setup_screens.dart';
import 'package:naijamove_driver/features/performance/performance_screens.dart';
import 'package:naijamove_driver/features/profile/profile_screens.dart';
import 'package:naijamove_driver/features/support/support_screens.dart';
import 'package:naijamove_driver/features/trip/active_trip_screen.dart';
import 'package:naijamove_driver/features/trip/rider_chat_screen.dart';
import 'package:naijamove_driver/features/trip/trip_outcome_screens.dart';
import 'package:naijamove_driver/features/trip/trip_state.dart';
import 'package:naijamove_driver/features/trips/trips_screens.dart';

/// Every screen must build without throwing (overflow, null, missing provider)
/// in mock mode at a phone-sized viewport.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> pump(WidgetTester tester, Widget screen, {bool withTrip = false}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer();
    container.read(sessionProvider.notifier).demoLogin();
    if (withTrip) {
      await container.read(activeTripProvider.notifier).accept(MockData.request);
    }
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.light, home: screen),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    return container;
  }

  final screens = <String, Widget>{
    'onboarding': const OnboardingScreen(),
    'phone': const PhoneEntryScreen(),
    'otp': const OtpScreen(phone: '8025550193'),
    'profile setup': const ProfileSetupScreen(),
    'vehicle setup': const VehicleSetupScreen(),
    'documents': const DocumentUploadScreen(),
    'under review': const UnderReviewScreen(),
    'permissions': const PermissionsScreen(),
    'home': const HomeScreen(),
    'scheduled': const ScheduledTripsScreen(),
    'request sheet': Scaffold(body: TripRequestSheet(request: MockData.request)),
    'cancel trip': const CancelTripScreen(),
    'sos': const SosScreen(),
    'no-show': const NoShowScreen(),
    'rider cancelled': const RiderCancelledScreen(),
    'rider chat': const RiderChatScreen(),
    'trip completed': const TripCompletedScreen(),
    'earnings': const EarningsScreen(),
    'wallet': const WalletScreen(),
    'trip earnings': TripEarningsDetailScreen(tripId: MockData.trips.first.id),
    'withdraw': const WithdrawScreen(),
    'bonuses': const BonusesScreen(),
    'link bank': const LinkBankScreen(),
    'transactions': const TransactionsScreen(),
    'trips': const TripsScreen(),
    'cancelled trip': CancelledTripScreen(tripId: MockData.trips.last.id),
    'profile': const ProfileScreen(),
    'vehicle': const VehicleScreen(),
    'emergency contact': const EmergencyContactScreen(),
    'safety': const SafetySettingsScreen(),
    'document status': const DocumentStatusScreen(),
    'public profile': const PublicProfileScreen(),
    'settings': const SettingsScreen(),
    'edit profile': const EditProfileScreen(),
    'notifications': const NotificationsScreen(),
    'performance': const PerformanceScreen(),
    'top driver': const TopDriverScreen(),
    'support home': const SupportHomeScreen(),
    'issue category': IssueCategoryScreen(tripId: MockData.trips.first.id),
    'issue form': const IssueFormScreen(category: 'I have a payment or earnings issue'),
    'case submitted': const CaseSubmittedScreen(category: 'safety'),
    'cases': const CasesScreen(),
    'case detail': CaseDetailScreen(caseRef: MockData.caseRef),
    'faq': const FaqScreen(),
    'offline': const OfflineScreen(),
  };

  for (final entry in screens.entries) {
    testWidgets('${entry.key} builds', (tester) async {
      await pump(tester, entry.value);
      expect(tester.takeException(), isNull);
    });
  }

  group('active trip', () {
    testWidgets('walks navigating → arrived → in progress', (tester) async {
      final c = await pump(tester, const ActiveTripScreen(), withTrip: true);
      expect(find.text("I've Arrived"), findsOneWidget);

      await tester.tap(find.text("I've Arrived"));
      await tester.pump(const Duration(milliseconds: 400));
      expect(c.read(activeTripProvider)!.phase, TripPhase.arrived);
      expect(find.text("You've arrived at pickup"), findsOneWidget);

      await c.read(activeTripProvider.notifier).startWithPin('4821');
      await tester.pump(const Duration(milliseconds: 400));
      expect(c.read(activeTripProvider)!.phase, TripPhase.inProgress);
      expect(find.text('End Trip'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('mock PIN 0000 is rejected without advancing', (tester) async {
      final c = await pump(tester, const ActiveTripScreen(), withTrip: true);
      await c.read(activeTripProvider.notifier).arrived();
      await expectLater(c.read(activeTripProvider.notifier).startWithPin('0000'), throwsA(anything));
      expect(c.read(activeTripProvider)!.phase, TripPhase.arrived);
    });
  });
}
