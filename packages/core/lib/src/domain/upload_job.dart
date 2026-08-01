import 'errors.dart';

class UploadJob {
  const UploadJob._({
    required this.localPath,
    required this.quality,
    required this.sizeBytes,
  });

  final String localPath;
  final int quality;
  final int sizeBytes;

  static const maxSizeBytes = 25 * 1024 * 1024;

  factory UploadJob.create({
    required String localPath,
    required int sizeBytes,
    int quality = 80,
  }) {
    final cleanPath = localPath.trim();

    if (cleanPath.isEmpty) {
      throw const InvalidJobError(message: 'El path no puede estar vacío');
    }

    if (quality < 1 || quality > 100) {
      throw InvalidJobError(
        message: 'Quality must be between 1 and 100, got $quality',
      );
    }

    if (sizeBytes <= 0) {
      throw InvalidJobError(
        message: 'Size must be greater than 0, got $sizeBytes',
      );
    }

    if (sizeBytes > maxSizeBytes) {
      throw InvalidJobError(
        message: 'Size must be <= $maxSizeBytes, got $sizeBytes',
      );
    }

    return UploadJob._(
      localPath: cleanPath,
      sizeBytes: sizeBytes,
      quality: quality,
    );
  }

  factory UploadJob.rehydrate(Map<String, String> payload) {
    final size = int.tryParse(payload['sizeBytes'] ?? '');
    final quality = int.tryParse(payload['quality'] ?? '');
    final localPath = payload['localPath'];

    if (size == null || quality == null || localPath == null) {
      throw const InvalidJobError(message: 'Invalid job data');
    }

    return UploadJob._(localPath: localPath, sizeBytes: size, quality: quality);
  }

  Map<String, String> toPayload() => {
    'localPath': localPath,
    'quality': '$quality',
    'sizeBytes': '$sizeBytes',
  };
}
