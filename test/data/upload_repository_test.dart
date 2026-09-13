import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:naijamove_driver/data/api/api_client.dart';
import 'package:naijamove_driver/data/repositories/upload_repository.dart';

void main() {
  // Mock mode (no API_BASE_URL in tests): validation still runs before the fake upload.
  final repo = UploadRepository(ApiClient(TokenStore()));

  test('rejects unsupported content types before any network call', () async {
    await expectLater(
      repo.upload(purpose: UploadPurpose.driverDocument, bytes: Uint8List(10), contentType: 'application/x-msdownload'),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'UNSUPPORTED_TYPE')),
    );
  });

  test('rejects files over 10 MB', () async {
    await expectLater(
      repo.upload(purpose: UploadPurpose.driverDocument, bytes: Uint8List(UploadRepository.maxBytes + 1), contentType: 'image/jpeg'),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'TOO_LARGE')),
    );
  });

  test('reports progress and returns a purpose-prefixed key', () async {
    final seen = <double>[];
    final r = await repo.upload(purpose: UploadPurpose.profilePhoto, bytes: Uint8List(100), contentType: 'image/png', onProgress: seen.add);
    expect(r.key, startsWith('profile_photo/'));
    expect(seen.last, 1.0);
  });
}
