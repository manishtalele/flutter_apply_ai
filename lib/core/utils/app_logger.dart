import 'package:logger/logger.dart';

/// Logging abstraction for the entire application.
///
/// Every layer depends on this interface (never on a concrete logging
/// package) so that logging can be swapped, silenced in tests, or routed to a
/// file/crash reporter without touching business logic. This is the
/// Dependency-Inversion seam for cross-cutting logging.
abstract class AppLogger {
  /// Verbose/debug diagnostics — development only.
  void d(String message, [Object? error, StackTrace? stackTrace]);

  /// Informational lifecycle events (bootstrap, navigation, successful I/O).
  void i(String message, [Object? error, StackTrace? stackTrace]);

  /// Recoverable problems that did not abort the operation.
  void w(String message, [Object? error, StackTrace? stackTrace]);

  /// Failures — mapped from exceptions before they become [Failure]s.
  void e(String message, [Object? error, StackTrace? stackTrace]);
}

/// Default [AppLogger] backed by the `logger` package with a readable,
/// colorized console printer. Registered as a permanent singleton in
/// [InitialBinding].
class ConsoleAppLogger implements AppLogger {
  ConsoleAppLogger({Logger? logger})
      : _logger = logger ??
            Logger(
              printer: PrettyPrinter(
                methodCount: 0,
                errorMethodCount: 8,
                lineLength: 100,
                colors: true,
                printEmojis: true,
                dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
              ),
            );

  final Logger _logger;

  @override
  void d(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  @override
  void i(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  @override
  void w(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  @override
  void e(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
