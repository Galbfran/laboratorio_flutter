sealed class DomainError implements Exception {
  const DomainError(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class InvalidJobError extends DomainError {
  const InvalidJobError({required String message}) : super(message);
}

class TransientUploadError extends DomainError {
  const TransientUploadError({required String message}) : super(message);
}

class PermanentUploadError extends DomainError {
  const PermanentUploadError({required String message}) : super(message);
}

class NoConnectivityError extends DomainError {
  const NoConnectivityError({String message = 'Sin conexión'}) : super(message);
}
