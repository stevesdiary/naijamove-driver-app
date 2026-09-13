/// Route paths — one place, referenced everywhere.
abstract final class Routes {
  // Flow 1 — Onboarding & Auth
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const phone = '/auth/phone';
  static const otp = '/auth/otp';
  static const profileSetup = '/auth/profile';
  static const vehicleSetup = '/auth/vehicle';
  static const documents = '/auth/documents';
  static const underReview = '/auth/review';
  static const permissions = '/auth/permissions';

  // Shell tabs
  static const home = '/home';
  static const trips = '/trips';
  static const earnings = '/earnings';
  static const profile = '/profile';

  // Flow 2 — Home
  static const scheduled = '/home/scheduled';

  // Flow 3 — Active trip
  static const activeTrip = '/trip';
  static const tripCompleted = '/trip/completed';
  static const cancelTrip = '/trip/cancel';
  static const riderCancelled = '/trip/rider-cancelled';
  static const noShow = '/trip/no-show';
  static const sos = '/trip/sos';
  static const riderChat = '/trip/chat';

  // Flow 4 — Earnings
  static const wallet = '/earnings/wallet';
  static const withdraw = '/earnings/withdraw';
  static const bonuses = '/earnings/bonuses';
  static const linkBank = '/earnings/bank';
  static const transactions = '/earnings/transactions';
  static String tripEarnings(String id) => '/earnings/trip/$id';
  static const tripEarningsPattern = '/earnings/trip/:id';

  // Flow 5 — Trips
  static String tripDetail(String id) => '/trips/$id';
  static const tripDetailPattern = '/trips/:id';

  // Flow 6 — Profile
  static const vehicle = '/profile/vehicle';
  static const emergencyContact = '/profile/emergency';
  static const safety = '/profile/safety';
  static const documentStatus = '/profile/documents';
  static const publicProfile = '/profile/public';
  static const settings = '/profile/settings';
  static const editProfile = '/profile/edit';

  // Flow 7
  static const notifications = '/notifications';

  // Flow 8
  static const performance = '/profile/performance';
  static const topDriver = '/profile/top-driver';

  // Flow 9 — Support
  static const support = '/support';
  static const supportCategories = '/support/new';
  static const supportForm = '/support/new/form';
  static const supportSubmitted = '/support/new/done';
  static const cases = '/support/cases';
  static String caseDetail(String ref) => '/support/cases/$ref';
  static const caseDetailPattern = '/support/cases/:ref';
  static const faq = '/support/faq';

  // Flow 10
  static const offline = '/offline';
}
