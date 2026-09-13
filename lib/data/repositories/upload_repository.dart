import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_config.dart';
import 'repository_providers.dart';

/// What a file is for. Mirrors the server's `uploadPurposes`.
enum UploadPurpose {
  driverDocument('driver_document'),
  profilePhoto('profile_photo'),
  vehiclePhoto('vehicle_photo'),
  deliveryProof('delivery_proof'),
  supportAttachment('support_attachment');

  const UploadPurpose(this.wire);
  final String wire;
}

/// Result of a completed upload — the key is what other endpoints accept.
class UploadedFile {
  const UploadedFile({required this.key, required this.sizeBytes});
  final String key;
  final int sizeBytes;
}

/// Direct-to-storage uploads.
///
/// 1. `POST /uploads/presign` → one-shot PUT URL bound to type + length
/// 2. PUT the bytes to storage (Backblaze B2) — the app never holds B2 keys
/// 3. Hand `key` to the endpoint that owns the record
class UploadRepository {
  UploadRepository(this._api) : _raw = Dio(BaseOptions(connectTimeout: const Duration(seconds: 15), receiveTimeout: const Duration(minutes: 2)));
  final ApiClient _api;

  /// Separate client for the storage PUT: no bearer token, no base URL, no refresh interceptor.
  final Dio _raw;

  static const maxBytes = 10 * 1024 * 1024;
  static const allowedTypes = {'image/jpeg', 'image/png', 'image/webp', 'application/pdf'};

  Future<UploadedFile> upload({
    required UploadPurpose purpose,
    required Uint8List bytes,
    required String contentType,
    void Function(double fraction)? onProgress,
  }) async {
    if (!allowedTypes.contains(contentType)) {
      throw const ApiException('UNSUPPORTED_TYPE', 'Use a JPEG, PNG, WebP or PDF');
    }
    if (bytes.length > maxBytes) {
      throw const ApiException('TOO_LARGE', 'File must be 10 MB or smaller');
    }
    if (ApiConfig.useMock) {
      for (var i = 1; i <= 4; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 150));
        onProgress?.call(i / 4);
      }
      return UploadedFile(key: '${purpose.wire}/mock/${DateTime.now().millisecondsSinceEpoch}.jpg', sizeBytes: bytes.length);
    }

    final presign = await _api.postJson('/uploads/presign', body: {
      'purpose': purpose.wire,
      'contentType': contentType,
      'sizeBytes': bytes.length,
    });
    final key = presign['key'] as String;
    final url = presign['uploadUrl'] as String;
    final headers = Map<String, dynamic>.from(presign['headers'] as Map);

    try {
      await _raw.put<void>(
        url,
        data: Stream.fromIterable([bytes]),
        options: Options(headers: headers, contentType: contentType),
        onSendProgress: (sent, total) {
          if (total > 0) onProgress?.call(sent / total);
        },
      );
    } on DioException catch (e) {
      throw ApiException('UPLOAD_FAILED', 'Upload failed (${e.response?.statusCode ?? 'network'}). Try again.', statusCode: e.response?.statusCode);
    }
    return UploadedFile(key: key, sizeBytes: bytes.length);
  }
}

final uploadRepositoryProvider = Provider<UploadRepository>((ref) => UploadRepository(ref.watch(apiClientProvider)));
