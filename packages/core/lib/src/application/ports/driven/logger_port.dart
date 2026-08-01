enum TriggerSource { ui, scheduler, push, test, boot }

abstract interface class LoggerPort {
  Future<void> info(String message, {TriggerSource? source});
  Future<void> error(String message, Object error, StackTrace stackTrace);
}
