/// Backend wiring. Build with
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3004   (Android emulator)
///   flutter run --dart-define=API_BASE_URL=http://localhost:3004  (iOS simulator)
/// to talk to the server; leave it unset to run against the in-app mock data.
abstract final class ApiConfig {
  static const baseUrl = String.fromEnvironment('API_BASE_URL');

  /// True when no backend is configured — repositories fall back to mocks.
  static bool get useMock => baseUrl.isEmpty;

  /// ws(s):// counterpart of [baseUrl] for the trip channel.
  static String get wsBaseUrl {
    final u = Uri.parse(baseUrl);
    return u.replace(scheme: u.scheme == 'https' ? 'wss' : 'ws').toString();
  }

  static const connectTimeout = Duration(seconds: 10);
  static const receiveTimeout = Duration(seconds: 20);

  /// How often the driver channel streams GPS while on a trip.
  static const locationInterval = Duration(seconds: 3);
}
