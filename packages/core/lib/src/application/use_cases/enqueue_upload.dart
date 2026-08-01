import '../../domain/outbox_entry.dart';
import '../../domain/upload_job.dart';
import '../ports/driven/clock_port.dart';
import '../ports/driven/logger_port.dart';
import '../ports/driven/outbox_port.dart';
import '../ports/driven/scheduler_port.dart';

/// Los datos que el mundo exterior manda para pedir un upload.
/// Es un DTO propio del caso de uso — nunca se expone UploadJob directo
/// hacia afuera, ni se recibe directo desde afuera.
class EnqueueUploadInput {
  const EnqueueUploadInput({
    required this.localPath,
    required this.sizeBytes,
    this.quality = 80,
  });

  final String localPath;
  final int sizeBytes;
  final int quality;
}

class EnqueueUpload {
  const EnqueueUpload({
    required OutboxPort outbox,
    required ClockPort clock,
    required SchedulerPort scheduler,
    required LoggerPort logger,
    required String Function() idGenerator,
  }) : _outbox = outbox,
       _clock = clock,
       _scheduler = scheduler,
       _logger = logger,
       _newId = idGenerator;

  final OutboxPort _outbox;
  final ClockPort _clock;
  final SchedulerPort _scheduler;
  final LoggerPort _logger;
  final String Function() _newId;

  Future<String> call(EnqueueUploadInput input) async {
    // 1. Construí el UploadJob con UploadJob.create(...), usando los
    //    tres campos de `input`. Si algo es inválido, esto va a tirar
    //    InvalidJobError solo — no hace falta que lo manejes acá.
    final job = UploadJob.create(
      localPath: input.localPath,
      sizeBytes: input.sizeBytes,
      quality: input.quality,
    );

    // 2. Construí la OutboxEntry con OutboxEntry.create(...).
    //    Necesita un id (usá _newId()), el job del paso 1, y el `now`
    //    (usá _clock.now() — nunca DateTime.now() directo acá).
    final entry = OutboxEntry.create(
      id: _newId(),
      job: job,
      now: _clock.now(),
    );

    // 3. Guardala: await _outbox.enqueue(entry).
    await _outbox.enqueue(entry);

    // 4. Dejá rastro: await _logger.info('Encolado ${entry.id}');
    await _logger.info('Encolado ${entry.id}');

    // 5. Pedile al scheduler que programe el sync. Armá un TaskSpec
    //    con id: 'sync-uploads', kind: 'sync', network: any,
    //    y llamá await _scheduler.scheduleOneOff(spec).
    await _scheduler.scheduleOneOff(
      const TaskSpec(
        id: 'sync-uploads',
        kind: 'sync',
        network: NetworkRequirement.any,
      ),
    );

    // 6. Devolvé entry.id — es lo que el llamador necesita para
    //    poder consultar el estado de esa entrada después.
    return entry.id;
  }
}
