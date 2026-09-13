import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_client.dart';
import 'api_config.dart';

/// Driver side of `/ws/trip/:tripId/driver`.
///
/// The upgrade is authenticated with the access token as `?token=` (mobile
/// WebSocket clients can't reliably set headers), and the server only admits
/// the driver assigned to that trip. The server closes the channel when the
/// trip completes or is cancelled.
class DriverTripChannel {
  DriverTripChannel({required this.tripId, required this.tokens});

  final String tripId;
  final TokenStore tokens;
  WebSocketChannel? _ws;
  final _closed = Completer<void>();

  /// Resolves when the server closes the socket (trip over) or on error.
  Future<void> get done => _closed.future;
  bool get isOpen => _ws != null && !_closed.isCompleted;

  Future<void> connect() async {
    if (ApiConfig.useMock) return;
    final token = await tokens.accessToken;
    if (token == null) throw StateError('Not signed in');
    final uri = Uri.parse('${ApiConfig.wsBaseUrl}/ws/trip/$tripId/driver').replace(queryParameters: {'token': token});
    final ws = WebSocketChannel.connect(uri);
    await ws.ready; // throws on 401/403/422 from the guard
    _ws = ws;
    ws.stream.listen(
      (_) {}, // driver channel is write-mostly; the server only sends `closed`
      onDone: () => _finish(),
      onError: (Object e, StackTrace s) => _finish(e, s),
      cancelOnError: true,
    );
  }

  /// Push a GPS fix; fanned out to the rider and cached server-side (10 s TTL).
  void sendLocation({required double lat, required double lng}) {
    _send({'type': 'location', 'lat': lat, 'lng': lng});
  }

  /// Push a lightweight state hint (e.g. `arrived`) — the REST calls remain the source of truth.
  void sendState(String state) {
    assert(state.length <= 32);
    _send({'type': 'state', 'state': state});
  }

  void _send(Map<String, Object> msg) {
    final ws = _ws;
    if (ws == null || _closed.isCompleted) return;
    ws.sink.add(jsonEncode(msg));
  }

  Future<void> close() async {
    await _ws?.sink.close();
    _finish();
  }

  void _finish([Object? error, StackTrace? stack]) {
    if (_closed.isCompleted) return;
    if (error != null) {
      _closed.completeError(error, stack);
    } else {
      _closed.complete();
    }
  }
}
