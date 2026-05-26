import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsState {
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool colorBlindMode;

  SettingsState({
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.colorBlindMode = false,
  });

  SettingsState copyWith({
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? colorBlindMode,
  }) {
    return SettingsState(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      colorBlindMode: colorBlindMode ?? this.colorBlindMode,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      soundEnabled: prefs.getBool('soundEnabled') ?? true,
      vibrationEnabled: prefs.getBool('vibrationEnabled') ?? true,
      colorBlindMode: prefs.getBool('colorBlindMode') ?? false,
    );
  }

  Future<void> toggleSound(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundEnabled', value);
    state = state.copyWith(soundEnabled: value);
  }

  Future<void> toggleVibration(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibrationEnabled', value);
    state = state.copyWith(vibrationEnabled: value);
  }

  Future<void> toggleColorBlindMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('colorBlindMode', value);
    state = state.copyWith(colorBlindMode: value);
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  final isSoundEnabled = ref.watch(settingsProvider.select((s) => s.soundEnabled));
  return AudioService(isSoundEnabled);
});

class AudioService {
  final bool isEnabled;
  final AudioPlayer _player = AudioPlayer();

  AudioService(this.isEnabled);

  Future<void> playCardFlip() async {
    if (!isEnabled) return;
    try {
      // await _player.play(AssetSource('sounds/card_flip.mp3'));
    } catch (_) {}
  }

  Future<void> playEventTrigger() async {
    if (!isEnabled) return;
    try {
      // await _player.play(AssetSource('sounds/event.mp3'));
    } catch (_) {}
  }

  Future<void> playError() async {
    if (!isEnabled) return;
    try {
      // await _player.play(AssetSource('sounds/error.mp3'));
    } catch (_) {}
  }
}
