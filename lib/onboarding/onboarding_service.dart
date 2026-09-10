import 'package:noscall/core/common/storage/preferences_store.dart';
import 'package:noscall/core/common/utils/log_utils.dart';

/// Stores whether the first-run onboarding has already been completed.
class OnboardingService {
  static final OnboardingService _instance = OnboardingService._internal();
  factory OnboardingService() => _instance;
  OnboardingService._internal();

  static const String completedKey = 'noscall_onboarding_completed';

  final PreferencesStore _prefs = PreferencesStore.shared;
  bool _isCompleted = false;

  bool get isCompleted => _isCompleted;

  Future<void> initialize() async {
    try {
      _isCompleted = await _prefs.getBool(completedKey) ?? false;
    } catch (e, stack) {
      LogUtils.e(() => 'OnboardingService.initialize failed: $e, $stack');
      _isCompleted = false;
    }
  }

  Future<void> complete() async {
    final ok = await _prefs.setBool(completedKey, true);
    if (ok) {
      _isCompleted = true;
    } else {
      LogUtils.w(() => 'OnboardingService.complete failed to persist');
    }
  }

  Future<void> reset() async {
    final ok = await _prefs.remove(completedKey);
    if (ok) {
      _isCompleted = false;
    } else {
      LogUtils.w(() => 'OnboardingService.reset failed to persist');
    }
  }
}
