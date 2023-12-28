import 'package:logging/logging.dart';

Logger logger = Logger('autosync');

extension LoggerExt on Logger {
  void d(Object message, [Object? error, StackTrace? stackTrace]) {
    log(Level.INFO, error, stackTrace);
  }

  void e(Object message, [Object? error, StackTrace? stackTrace]) {
    log(Level.SHOUT, error, stackTrace);
  }

  void w(Object message, [Object? error, StackTrace? stackTrace]) {
    log(Level.WARNING, error, stackTrace);
  }
}
