import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();

  bool soundEnabled = true;
  bool musicEnabled = true;
  bool allowBgAudio = false;
  double sfxVolume = 1.0;
  double musicVolume = 0.3;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    soundEnabled = prefs.getBool('soundEnabled') ?? true;
    musicEnabled = prefs.getBool('musicEnabled') ?? true;
    allowBgAudio = prefs.getBool('allowBgAudio') ?? false;
    sfxVolume = prefs.getDouble('sfxVolume') ?? 1.0;
    musicVolume = prefs.getDouble('musicVolume') ?? 0.3;

    _applyAudioContext();
    _musicPlayer.setReleaseMode(ReleaseMode.loop);
    _musicPlayer.setVolume(musicVolume);
  }

  void _applyAudioContext() {
    try {
      AudioPlayer.global.setAudioContext(AudioContext(
        iOS: AudioContextIOS(
          category: allowBgAudio ? AVAudioSessionCategory.ambient : AVAudioSessionCategory.playback,
          options: allowBgAudio ? {AVAudioSessionOptions.mixWithOthers} : {},
        ),
        android: AudioContextAndroid(
          audioMode: AndroidAudioMode.normal,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.game,
          audioFocus: allowBgAudio ? AndroidAudioFocus.none : AndroidAudioFocus.gain,
        ),
      ));
    } catch (_) {}
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundEnabled', soundEnabled);
    await prefs.setBool('musicEnabled', musicEnabled);
    await prefs.setBool('allowBgAudio', allowBgAudio);
    await prefs.setDouble('sfxVolume', sfxVolume);
    await prefs.setDouble('musicVolume', musicVolume);
  }

  void updateSettings(
      {bool? sound, bool? music, bool? bgAudio, double? sfxVol, double? musicVol}) {
    if (sound != null) soundEnabled = sound;
    if (music != null) {
      musicEnabled = music;
      if (!music) stopMusic();
    }
    if (bgAudio != null) {
      allowBgAudio = bgAudio;
      _applyAudioContext();
    }
    if (sfxVol != null) sfxVolume = sfxVol;
    if (musicVol != null) {
      musicVolume = musicVol;
      _musicPlayer.setVolume(musicVol);
    }
    saveSettings();
  }

  Future<void> playMusic(String path) async {
    if (!musicEnabled) return;
    try {
      await _musicPlayer.play(AssetSource(path));
    } catch (_) {}
  }

  Future<void> stopMusic() async {
    await _musicPlayer.stop();
  }

  Future<void> pauseMusic() async {
    await _musicPlayer.pause();
  }

  Future<void> resumeMusic() async {
    if (!musicEnabled) return;
    await _musicPlayer.resume();
  }

  void playSound(String path) async {
    if (!soundEnabled) return;
    try {
      await _sfxPlayer.setVolume(sfxVolume);
      await _sfxPlayer.play(AssetSource(path));
    } catch (_) {}
  }

  void playClick() => playSound('sounds/click.wav');
  void playCardFlip() => playSound('sounds/card_flip.wav');
  void playBluffCall() => playSound('sounds/bluff_call.wav');
  void playVictory() => playSound('sounds/victory.wav');
  void playDefeat() => playSound('sounds/defeat.wav');
  void playTimer() => playSound('sounds/timer_tick.wav');
  void playNotification() => playSound('sounds/notification.wav');
  void playGlassClink() => playSound('sounds/glass_clink.wav');
}
