/// Web (non-IO) implementation of [JsonFileCache].
///
/// Web has no filesystem access, so caching is a safe no-op: every read
/// returns `null` and writes are ignored.
class JsonFileCache {
  JsonFileCache._();

  static Future<void> write(String name, Object? json) async {}

  static Future<T?> read<T>(
    String name,
    T Function(Object? json) fromJson,
  ) async =>
      null;
}
