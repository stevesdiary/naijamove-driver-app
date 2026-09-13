import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme/app_theme.dart';
import '../../data/repositories/upload_repository.dart';
import '../widgets/components.dart';

/// A picked file ready to upload.
class PickedFile {
  const PickedFile({required this.bytes, required this.contentType, required this.name});
  final Uint8List bytes;
  final String contentType;
  final String name;
}

/// Bottom sheet: Take photo · Choose from library. Returns null if dismissed.
/// Images are downscaled/re-encoded on device so uploads stay well under the 10 MB cap.
Future<PickedFile?> pickImage(BuildContext context, {bool allowCamera = true}) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SheetSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (allowCamera) IconRow(icon: Icons.photo_camera_rounded, title: 'Take photo', onTap: () => Navigator.pop(ctx, ImageSource.camera)),
          IconRow(icon: Icons.photo_library_rounded, title: 'Choose from library', onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
        ],
      ),
    ),
  );
  if (source == null) return null;
  final x = await ImagePicker().pickImage(source: source, imageQuality: 85, maxWidth: 2000, maxHeight: 2000);
  if (x == null) return null;
  final bytes = await x.readAsBytes();
  return PickedFile(bytes: bytes, contentType: x.mimeType ?? _mimeFromName(x.name), name: x.name);
}

String _mimeFromName(String name) {
  final ext = name.split('.').last.toLowerCase();
  return switch (ext) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    'pdf' => 'application/pdf',
    _ => 'image/jpeg',
  };
}

/// Pick → upload with a progress dialog → returns the storage key, or null if
/// the user cancelled. Errors are surfaced as toasts.
Future<String?> pickAndUpload(BuildContext context, WidgetRef ref, UploadPurpose purpose) async {
  final file = await pickImage(context);
  if (file == null || !context.mounted) return null;

  final progress = ValueNotifier<double>(0);
  final dialog = showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ProgressDialog(progress: progress, name: file.name),
  );
  try {
    final result = await ref.read(uploadRepositoryProvider).upload(
          purpose: purpose,
          bytes: file.bytes,
          contentType: file.contentType,
          onProgress: (f) => progress.value = f,
        );
    return result.key;
  } catch (e) {
    if (context.mounted) showToast(context, e.toString(), kind: ToastKind.error);
    return null;
  } finally {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    await dialog;
    progress.dispose();
  }
}

class _ProgressDialog extends StatelessWidget {
  const _ProgressDialog({required this.progress, required this.name});
  final ValueNotifier<double> progress;
  final String name;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Uploading…'),
      content: ValueListenableBuilder<double>(
        valueListenable: progress,
        builder: (_, v, _) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: theme.textTheme.bodySmall?.copyWith(color: context.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: v == 0 ? null : v, minHeight: 8, color: AppColors.primaryBlue, backgroundColor: context.bg),
            ),
            const SizedBox(height: 6),
            Text('${(v * 100).round()}%', style: theme.textTheme.labelMedium?.copyWith(fontFeatures: AppText.tabular)),
          ],
        ),
      ),
    );
  }
}
