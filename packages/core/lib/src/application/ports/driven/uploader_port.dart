import '../../../domain/upload_job.dart';

abstract interface class UploaderPort {
  Future<void> upload(UploadJob job, List<int> bytes);
}
