// Export the appropriate implementation based on platform
export 'universal_download_web.dart' if (dart.library.io) 'universal_download_io.dart';
