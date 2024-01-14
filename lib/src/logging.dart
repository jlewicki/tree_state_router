import 'dart:async';
import 'dart:developer';

import 'package:logging/logging.dart';

const rootLoggerName = 'TreeStateRouter';
final Logger rootLogger = Logger(rootLoggerName);
StreamSubscription<LogRecord>? _subscription;

void setEnableDeveloperLogging(
  bool enable, {
  String loggerName = rootLoggerName,
}) {
  _subscription?.cancel();

  var logger = Logger(loggerName);
  if (hierarchicalLoggingEnabled) {
    logger.level = enable ? Level.ALL : Level.OFF;
  }

  if (enable) {
    _subscription = logger.onRecord.listen((rec) {
      log(
        rec.message,
        time: rec.time,
        sequenceNumber: rec.sequenceNumber,
        level: rec.level.value,
        name: rec.loggerName,
        zone: rec.zone,
        error: rec.error,
        stackTrace: rec.stackTrace,
      );
    });
  } else {
    _subscription = null;
  }
}
