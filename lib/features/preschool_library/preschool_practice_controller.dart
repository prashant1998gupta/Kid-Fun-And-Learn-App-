import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../settings/settings_controller.dart';

enum PreschoolPracticeStage { newItem, practising, great }

extension PreschoolPracticeStageData on PreschoolPracticeStage {
  String get label => switch (this) {
        PreschoolPracticeStage.newItem => 'New',
        PreschoolPracticeStage.practising => 'Practising',
        PreschoolPracticeStage.great => 'Great job',
      };
}

class PreschoolItemProgress {
  const PreschoolItemProgress({this.views = 0, this.practices = 0});

  final int views;
  final int practices;

  PreschoolPracticeStage get stage {
    if (views == 0 && practices == 0) return PreschoolPracticeStage.newItem;
    if (practices < 3) return PreschoolPracticeStage.practising;
    return PreschoolPracticeStage.great;
  }

  Map<String, int> toMap() => {'views': views, 'practices': practices};

  factory PreschoolItemProgress.fromMap(Map<String, dynamic> map) =>
      PreschoolItemProgress(
        views: (map['views'] as num?)?.toInt() ?? 0,
        practices: (map['practices'] as num?)?.toInt() ?? 0,
      );
}

class PreschoolPracticeState {
  const PreschoolPracticeState(this.items);

  final Map<String, PreschoolItemProgress> items;

  PreschoolItemProgress forItem(String itemId) =>
      items[itemId] ?? const PreschoolItemProgress();

  int practisedCount(Iterable<String> itemIds) => itemIds
      .where((id) => forItem(id).stage != PreschoolPracticeStage.newItem)
      .length;
}

class PreschoolPracticeController
    extends StateNotifier<PreschoolPracticeState> {
  PreschoolPracticeController(this._preferences, this._childId)
      : super(PreschoolPracticeState(_restore(_preferences, _childId)));

  final SharedPreferences _preferences;
  final String _childId;

  static String _key(String childId) => 'preschool_practice_$childId';

  static Map<String, PreschoolItemProgress> _restore(
      SharedPreferences preferences, String childId) {
    final raw = preferences.getString(_key(childId));
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(
          key,
          PreschoolItemProgress.fromMap((value as Map).cast<String, dynamic>()),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> viewed(String itemId) async {
    final current = state.forItem(itemId);
    await _save(
        itemId,
        PreschoolItemProgress(
            views: current.views + 1, practices: current.practices));
  }

  Future<void> practised(String itemId) async {
    final current = state.forItem(itemId);
    await _save(
      itemId,
      PreschoolItemProgress(
        views: current.views == 0 ? 1 : current.views,
        practices: current.practices + 1,
      ),
    );
  }

  Future<void> _save(String itemId, PreschoolItemProgress progress) async {
    final next = {...state.items, itemId: progress};
    state = PreschoolPracticeState(next);
    await _preferences.setString(
      _key(_childId),
      jsonEncode(next.map((key, value) => MapEntry(key, value.toMap()))),
    );
  }
}

final preschoolPracticeControllerProvider = StateNotifierProvider.family<
    PreschoolPracticeController, PreschoolPracticeState, String>(
  (ref, childId) => PreschoolPracticeController(
    ref.watch(sharedPreferencesProvider),
    childId,
  ),
);
