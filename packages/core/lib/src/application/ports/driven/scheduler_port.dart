enum NetworkRequirement { none, any, unmetered }

class TaskSpec {
  const TaskSpec({
    required this.id,
    required this.kind,
    this.network = NetworkRequirement.any,
    this.requiresCharging = false,
    this.initialDelay = Duration.zero,
    this.payload = const {},
  });

  final String id;
  final String kind;
  final NetworkRequirement network;
  final bool requiresCharging;
  final Duration initialDelay;
  final Map<String, String> payload;
}

abstract interface class SchedulerPort {
  Future<void> scheduleOneOff(TaskSpec spec);
  Future<void> schedulePeriodic(TaskSpec spec, Duration interval);
  Future<void> cancel(String id);
}
