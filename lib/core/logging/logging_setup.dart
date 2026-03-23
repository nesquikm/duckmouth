import 'package:logging/logging.dart';
import 'package:the_logger/the_logger.dart';

/// Initialize the_logger for console-only structured logging.
Future<void> setupLogging({String? appVersion}) async {
  await TheLogger.i().init(
    dbLogger: true,
    consoleLogger: true,
    consoleFormatJson: true,
    sessionStartExtra: appVersion ?? '1.0.0',
    retainStrategy: {Level.ALL: 10},
  );
}
