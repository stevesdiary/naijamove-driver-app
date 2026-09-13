import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_config.dart';

/// Server error envelope: `{ error: { code, message } }`.
class ApiException implements Exception {
  const ApiException(this.code, this.message, {this.statusCode});
  final String code;
  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;
  bool get isNetwork => code == 'NETWORK';

  @override
  String toString() => message;

  static ApiException from(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      final err = data['error'] as Map;
      return ApiException(
        (err['code'] ?? 'ERROR').toString(),
        (err['message'] ?? 'Something went wrong').toString(),
        statusCode: e.response?.statusCode,
      );
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const ApiException('NETWORK', "You're offline. Check your connection and try again.");
    }
    return ApiException('ERROR', e.message ?? 'Something went wrong', statusCode: e.response?.statusCode);
  }
}

/// Access/refresh token persistence.
class TokenStore {
  TokenStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;
  static const _access = 'nm_driver_access_token';
  static const _refresh = 'nm_driver_refresh_token';
  static const _userId = 'nm_driver_user_id';

  String? _cachedAccess;

  Future<String?> get accessToken async => _cachedAccess ??= await _storage.read(key: _access);
  Future<String?> get refreshToken => _storage.read(key: _refresh);
  Future<String?> get userId => _storage.read(key: _userId);

  Future<void> save({required String access, required String refresh, String? userId}) async {
    _cachedAccess = access;
    await _storage.write(key: _access, value: access);
    await _storage.write(key: _refresh, value: refresh);
    if (userId != null) await _storage.write(key: _userId, value: userId);
  }

  Future<void> clear() async {
    _cachedAccess = null;
    await _storage.delete(key: _access);
    await _storage.delete(key: _refresh);
    await _storage.delete(key: _userId);
  }
}

/// Dio wrapper: base URL, bearer auth, single-flight refresh on 401, error mapping.
class ApiClient {
  ApiClient(this.tokens, {Dio? dio, this.onSessionExpired})
      : dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConfig.baseUrl,
                connectTimeout: ApiConfig.connectTimeout,
                receiveTimeout: ApiConfig.receiveTimeout,
                headers: {'Accept': 'application/json'},
              ),
            ) {
    this.dio.interceptors.add(
          QueuedInterceptorsWrapper(onRequest: _onRequest, onError: _onError),
        );
  }

  final Dio dio;
  final TokenStore tokens;
  final void Function()? onSessionExpired;

  Future<void> _onRequest(RequestOptions o, RequestInterceptorHandler h) async {
    if (o.extra['noAuth'] != true) {
      final t = await tokens.accessToken;
      if (t != null) o.headers['Authorization'] = 'Bearer $t';
    }
    h.next(o);
  }

  Future<void> _onError(DioException e, ErrorInterceptorHandler h) async {
    final isAuthCall = e.requestOptions.path.startsWith('/auth/');
    if (e.response?.statusCode == 401 && !isAuthCall && e.requestOptions.extra['retried'] != true) {
      final refreshed = await _refresh();
      if (refreshed) {
        final opts = e.requestOptions..extra['retried'] = true;
        opts.headers['Authorization'] = 'Bearer ${await tokens.accessToken}';
        try {
          return h.resolve(await dio.fetch(opts));
        } on DioException catch (re) {
          return h.next(re);
        }
      }
      await tokens.clear();
      onSessionExpired?.call();
    }
    h.next(e);
  }

  Future<bool> _refresh() async {
    final rt = await tokens.refreshToken;
    if (rt == null) return false;
    try {
      final res = await dio.post<Map<String, dynamic>>(
        '/auth/token/refresh',
        data: {'refreshToken': rt},
        options: Options(extra: {'noAuth': true}),
      );
      final d = res.data!;
      await tokens.save(access: d['accessToken'] as String, refresh: d['refreshToken'] as String);
      return true;
    } on DioException {
      return false;
    }
  }

  // ---- typed helpers -------------------------------------------------------

  Future<Map<String, dynamic>> getJson(String path, {Map<String, dynamic>? query, bool auth = true}) async {
    try {
      final r = await dio.get<dynamic>(path, queryParameters: query, options: Options(extra: {'noAuth': !auth}));
      return _asMap(r.data);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<List<dynamic>> getList(String path, {Map<String, dynamic>? query, String? key}) async {
    try {
      final r = await dio.get<dynamic>(path, queryParameters: query);
      final d = r.data;
      if (d is List) return d;
      if (d is Map && key != null && d[key] is List) return d[key] as List;
      if (d is Map) {
        final firstList = d.values.whereType<List>().firstOrNull;
        if (firstList != null) return firstList;
      }
      return const [];
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<Map<String, dynamic>> postJson(String path, {Object? body, bool auth = true}) async {
    try {
      final r = await dio.post<dynamic>(path, data: body, options: Options(extra: {'noAuth': !auth}));
      return _asMap(r.data);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<Map<String, dynamic>> putJson(String path, {Object? body}) async {
    try {
      final r = await dio.put<dynamic>(path, data: body);
      return _asMap(r.data);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> delete(String path) async {
    try {
      await dio.delete<dynamic>(path);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  static Map<String, dynamic> _asMap(dynamic d) {
    if (d is Map<String, dynamic>) return d;
    if (d is Map) return Map<String, dynamic>.from(d);
    return const {};
  }
}
