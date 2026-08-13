/// Simple file-based JSON cache used for offline-first persistence of feature
/// data (habits, goals).
///
/// Files are namespaced per user so different accounts never see each other's
/// cached data. Values survive hot restarts and full app restarts, so data is
/// never lost when the backend is temporarily unreachable.
library;

export 'json_file_cache_stub.dart'
    if (dart.library.io) 'json_file_cache_io.dart';
