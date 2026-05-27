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
  final double musicVolume;
  final double sfxVolume;
  final String language;

  SettingsState({
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.colorBlindMode = false,
    this.musicVolume = 1.0,
    this.sfxVolume = 1.0,
    this.language = 'fr',
  });

  SettingsState copyWith({
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? colorBlindMode,
    double? musicVolume,
    double? sfxVolume,
    String? language,
  }) {
    return SettingsState(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      colorBlindMode: colorBlindMode ?? this.colorBlindMode,
      musicVolume: musicVolume ?? this.musicVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      language: language ?? this.language,
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
      musicVolume: prefs.getDouble('musicVolume') ?? 1.0,
      sfxVolume: prefs.getDouble('sfxVolume') ?? 1.0,
      language: prefs.getString('language') ?? 'fr',
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

  Future<void> updateMusicVolume(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('musicVolume', value);
    state = state.copyWith(musicVolume: value);
  }

  Future<void> updateSfxVolume(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sfxVolume', value);
    state = state.copyWith(sfxVolume: value);
  }

  Future<void> setLanguage(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', value);
    state = state.copyWith(language: value);
  }

  Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', false);
    await prefs.setBool('hasSeenRules', false);
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
