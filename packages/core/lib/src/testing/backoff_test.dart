import 'package:core/src/domain/backoff.dart';
import 'package:test/test.dart';

void main() {
  test('crece exponencialmente', () {
    expect(backoffFor(0), const Duration(seconds: 2));
    expect(backoffFor(1), const Duration(seconds: 4));
    expect(backoffFor(2), const Duration(seconds: 8));
  });

  test('respeta techo', () {
    expect(backoffFor(30), const Duration(hours: 1));
  });

  test("el jitter aumenta la espera de forma acotada", () {
    final sin = backoffFor(3);
    final con = backoffFor(3, jitter: 0.5);
    expect(con.inMilliseconds, greaterThan(sin.inMilliseconds));
    expect(con.inMilliseconds, lessThanOrEqualTo(sin.inMilliseconds * 2));
  });
}
