import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../settings/settings_controller.dart';

/// A saved drawing entry with a thumbnail data URL and timestamp.
class SavedDrawing {
  const SavedDrawing({
    required this.id,
    required this.name,
    required this.thumbnailBytes,
    required this.createdAt,
  });

  final String id;
  final String name;
  final Uint8List thumbnailBytes;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'thumbnail': base64Encode(thumbnailBytes),
        'createdAt': createdAt.toIso8601String(),
      };

  factory SavedDrawing.fromMap(Map<String, dynamic> map) => SavedDrawing(
        id: map['id'] as String,
        name: map['name'] as String,
        thumbnailBytes: base64Decode(map['thumbnail'] as String),
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}

/// Persists saved drawings via SharedPreferences as base64-encoded PNGs.
class CanvasRepository {
  CanvasRepository(this._prefs);
  final SharedPreferences _prefs;

  static const _key = 'saved_drawings';

  List<SavedDrawing> loadAll() {
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => SavedDrawing.fromMap((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<void> saveAll(List<SavedDrawing> drawings) async {
    final raw = jsonEncode(drawings.map((d) => d.toMap()).toList());
    await _prefs.setString(_key, raw);
  }

  Future<void> delete(String id) async {
    final all = loadAll().where((d) => d.id != id).toList();
    await saveAll(all);
  }
}

final canvasRepositoryProvider = Provider<CanvasRepository>((ref) {
  return CanvasRepository(ref.watch(sharedPreferencesProvider));
});