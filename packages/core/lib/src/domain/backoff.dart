import 'dart:math' as math;

Duration backoffFor(
  int attempt, {
  Duration base = const Duration(seconds: 2),
  Duration max = const Duration(hours: 1),
  double jitter = 0.0,
}) {
  assert(attempt >= 0, 'attempt no puede ser negativo');
  assert(jitter >= 0 && jitter <= 1, 'jitter debe estar entre 0 y 1');

  final exponentialMs = base.inMilliseconds * math.pow(2, attempt);
  final cappedMs = math.min(exponentialMs, max.inMilliseconds);
  final resultMs = (cappedMs * (1 + jitter)).round();

  return Duration(milliseconds: resultMs);
}
