// Export the appropriate implementation based on platform
export 'universal_logger_output_web.dart'
    if (dart.library.io) 'universal_logger_output_io.dart';
