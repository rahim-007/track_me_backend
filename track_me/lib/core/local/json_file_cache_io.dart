import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../constants/app_constants.dart';

/// IO implementation of [JsonFileCache]: persists JSON to a file in the app's
/// documents directory, namespaced per user.
class JsonFileCache {
  JsonFileCache._();

  static Future<String> _resolvedName(String name) async {
    try {
      const storage = FlutterSecureStorage();
      final userId = await storage.read(key: AppConstants.userIdKey);
      if (userId != null && userId.isNotEmpty) {
        return '${name}_$userId.json';
      }
    } catch (_) {
      // Fall through to the non-namespaced file.
    }
    return '$name.json';
  }

  static Future<File> _file(String name) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/${await _resolvedName(name)}');
  }

  static Future<void> write(String name, Object? json) async {
    if (kIsWeb) return;
    try {
      final file = await _file(name);
      await file.writeAsString(jsonEncode(json), flush: true);
    } catch (_) {
      // Cache failures must never break the app flow.
    }
  }

  /// Reads and decodes a cached JSON value. Returns `null` when the cache is
  /// missing, corrupted, or on unsupported platforms.
  static Future<T?> read<T>(
    String name,
    T Function(Object? json) fromJson,
  ) async {
    if (kIsWeb) return null;
    try {
      final file = await _file(name);
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return null;
      return fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }
}
