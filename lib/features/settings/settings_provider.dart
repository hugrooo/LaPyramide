import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/audio/audio_manager.dart';

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsState {
  final bool soundEnabled;
  final bool musicEnabled;
  final bool vibrationEnabled;
  final bool allowBgAudio;
  final bool colorBlindMode;
  final double musicVolume;
  final double sfxVolume;
  final String language;
  final String themeMode; // 'dark', 'light', 'system'

  // Push Notifications
  final bool pushGlobal;
  final bool pushReminders;
  final bool pushFriends;
  final bool pushEvents;

  // Social & Visibilité
  final bool isOnlineVisible;
  final bool allowFriendRequests;

  SettingsState({
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.vibrationEnabled = true,
    this.allowBgAudio = false,
    this.colorBlindMode = false,
    this.musicVolume = 0.3,
    this.sfxVolume = 1.0,
    this.language = 'fr',
    this.themeMode = 'dark',
    this.pushGlobal = true,
    this.pushReminders = true,
    this.pushFriends = true,
    this.pushEvents = true,
    this.isOnlineVisible = true,
    this.allowFriendRequests = true,
  });

  SettingsState copyWith({
    bool? soundEnabled,
    bool? musicEnabled,
    bool? vibrationEnabled,
    bool? allowBgAudio,
    bool? colorBlindMode,
    double? musicVolume,
    double? sfxVolume,
    String? language,
    String? themeMode,
    bool? pushGlobal,
    bool? pushReminders,
    bool? pushFriends,
    bool? pushEvents,
    bool? isOnlineVisible,
    bool? allowFriendRequests,
  }) {
    return SettingsState(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      allowBgAudio: allowBgAudio ?? this.allowBgAudio,
      colorBlindMode: colorBlindMode ?? this.colorBlindMode,
      musicVolume: musicVolume ?? this.musicVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
      pushGlobal: pushGlobal ?? this.pushGlobal,
      pushReminders: pushReminders ?? this.pushReminders,
      pushFriends: pushFriends ?? this.pushFriends,
      pushEvents: pushEvents ?? this.pushEvents,
      isOnlineVisible: isOnlineVisible ?? this.isOnlineVisible,
      allowFriendRequests: allowFriendRequests ?? this.allowFriendRequests,
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
      musicEnabled: prefs.getBool('musicEnabled') ?? true,
      vibrationEnabled: prefs.getBool('vibrationEnabled') ?? true,
      allowBgAudio: prefs.getBool('allowBgAudio') ?? false,
      colorBlindMode: prefs.getBool('colorBlindMode') ?? false,
      musicVolume: prefs.getDouble('musicVolume') ?? 0.3,
      sfxVolume: prefs.getDouble('sfxVolume') ?? 1.0,
      language: prefs.getString('language') ?? 'fr',
      themeMode: prefs.getString('themeMode') ?? 'dark',
      pushGlobal: prefs.getBool('pushGlobal') ?? true,
      pushReminders: prefs.getBool('pushReminders') ?? true,
      pushFriends: prefs.getBool('pushFriends') ?? true,
      pushEvents: prefs.getBool('pushEvents') ?? true,
      isOnlineVisible: prefs.getBool('isOnlineVisible') ?? true,
      allowFriendRequests: prefs.getBool('allowFriendRequests') ?? true,
    );
    AudioManager().updateSettings(
      sound: state.soundEnabled,
      music: state.musicEnabled,
      bgAudio: state.allowBgAudio,
      sfxVol: state.sfxVolume,
      musicVol: state.musicVolume,
    );
  }

  Future<void> toggleSound(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundEnabled', value);
    state = state.copyWith(soundEnabled: value);
    AudioManager().updateSettings(sound: state.soundEnabled, sfxVol: state.sfxVolume);
  }

  Future<void> toggleMusic(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('musicEnabled', value);
    state = state.copyWith(musicEnabled: value);
    AudioManager().updateSettings(music: state.musicEnabled);
  }

  Future<void> toggleVibration(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibrationEnabled', value);
    state = state.copyWith(vibrationEnabled: value);
  }

  Future<void> toggleAllowBgAudio(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('allowBgAudio', value);
    state = state.copyWith(allowBgAudio: value);
    AudioManager().updateSettings(bgAudio: value);
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
    AudioManager().updateSettings(musicVol: value);
  }

  Future<void> updateSfxVolume(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sfxVolume', value);
    state = state.copyWith(sfxVolume: value);
    AudioManager().updateSettings(sfxVol: value);
  }

  Future<void> setThemeMode(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', value);
    state = state.copyWith(themeMode: value);
  }

  Future<void> togglePushGlobal(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pushGlobal', value);
    state = state.copyWith(pushGlobal: value);
  }

  Future<void> togglePushReminders(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pushReminders', value);
    state = state.copyWith(pushReminders: value);
  }

  Future<void> togglePushFriends(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pushFriends', value);
    state = state.copyWith(pushFriends: value);
  }

  Future<void> togglePushEvents(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pushEvents', value);
    state = state.copyWith(pushEvents: value);
  }

  Future<void> toggleIsOnlineVisible(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isOnlineVisible', value);
    state = state.copyWith(isOnlineVisible: value);
  }

  Future<void> toggleAllowFriendRequests(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('allowFriendRequests', value);
    state = state.copyWith(allowFriendRequests: value);
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

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    // Vider seulement les clés de cache non essentielles
    final keys = prefs.getKeys();
    for (final k in keys) {
      if (k.startsWith('cache_') || k.startsWith('temp_')) {
        await prefs.remove(k);
      }
    }
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  final isSoundEnabled =
      ref.watch(settingsProvider.select((s) => s.soundEnabled));
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
