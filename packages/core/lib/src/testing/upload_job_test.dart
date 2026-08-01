// packages/core/test/upload_job_test.dart
import 'package:core/src/domain/errors.dart';
import 'package:core/src/domain/upload_job.dart';
import 'package:test/test.dart';

void main() {
  // Helper para no repetir los mismos argumentos válidos en cada test.
  UploadJob valid() =>
      UploadJob.create(localPath: '/tmp/foto.jpg', sizeBytes: 1024);

  test('crea un job válido con quality por defecto', () {
    final job = valid();
    expect(job.quality, 80);
    expect(job.localPath, '/tmp/foto.jpg');
  });

  test('limpia espacios del path', () {
    final job = UploadJob.create(
      localPath: '  /tmp/foto.jpg  ',
      sizeBytes: 1024,
    );
    expect(job.localPath, '/tmp/foto.jpg');
  });

  test('rechaza path vacío', () {
    expect(
      () => UploadJob.create(localPath: '   ', sizeBytes: 1024),
      throwsA(isA<InvalidJobError>()),
    );
  });

  test('rechaza quality menor a 1', () {
    expect(
      () => UploadJob.create(
        localPath: '/tmp/foto.jpg',
        sizeBytes: 1024,
        quality: 0,
      ),
      throwsA(isA<InvalidJobError>()),
    );
  });

  test('rechaza quality mayor a 100', () {
    expect(
      () => UploadJob.create(
        localPath: '/tmp/foto.jpg',
        sizeBytes: 1024,
        quality: 101,
      ),
      throwsA(isA<InvalidJobError>()),
    );
  });

  test('rechaza sizeBytes negativo o cero', () {
    expect(
      () => UploadJob.create(localPath: '/tmp/foto.jpg', sizeBytes: 0),
      throwsA(isA<InvalidJobError>()),
    );
    expect(
      () => UploadJob.create(localPath: '/tmp/foto.jpg', sizeBytes: -10),
      throwsA(isA<InvalidJobError>()),
    );
  });

  test('rechaza archivos más grandes que maxSizeBytes', () {
    expect(
      () => UploadJob.create(
        localPath: '/tmp/foto.jpg',
        sizeBytes: UploadJob.maxSizeBytes + 1,
      ),
      throwsA(isA<InvalidJobError>()),
    );
  });

  test('rehydrate reconstruye sin validar', () {
    final payload = valid().toPayload();
    final job = UploadJob.rehydrate(payload);
    expect(job.localPath, '/tmp/foto.jpg');
    expect(job.sizeBytes, 1024);
  });

  test('rehydrate falla si falta un campo', () {
    expect(
      () => UploadJob.rehydrate({'localPath': '/a.jpg'}),
      throwsA(isA<InvalidJobError>()),
    );
  });
}
