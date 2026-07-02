import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profiles/profiles_controller.dart';
import '../settings/settings_controller.dart';

/// Gates the once-per-day free Lucky Spin (per child). Reward application lives
/// in the spin screen so the wheel animation and the payout stay in sync.
class LuckySpinController extends StateNotifier<int?> {
  LuckySpinController(this._ref) : super(null) {
    _restore();
  }

  final Ref _ref;

  String get _childId => _ref.read(activeChildProvider)?.id ?? '';
  String get _key => 'lucky_spin_day_$_childId';

  static int get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .difference(DateTime.utc(2020))
        .inDays;
  }

  void _restore() {
    state = _ref.read(sharedPreferencesProvider).getInt(_key);
  }

  void refreshForActiveChild() => _restore();

  bool get canSpinToday => state != _today;

  Future<void> markSpun() async {
    state = _today;
    await _ref.read(sharedPreferencesProvider).setInt(_key, _today);
  }
}

final luckySpinControllerProvider =
    StateNotifierProvider<LuckySpinController, int?>((ref) {
  return LuckySpinController(ref);
});
