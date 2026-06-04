import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final AudioPlayer _player = AudioPlayer();
  bool soundEnabled = true;
  double sfxVolume = 1.0;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    soundEnabled = prefs.getBool('soundEnabled') ?? true;
    sfxVolume = prefs.getDouble('sfxVolume') ?? 1.0;
  }

  void updateSettings(bool enabled, double volume) {
    soundEnabled = enabled;
    sfxVolume = volume;
  }

  void playSound(String path) async {
    if (!soundEnabled) return;
    try {
      // Les fichiers originaux étaient corrompus (fichiers HTML au lieu de WAV).
      // L'appel à p.play est temporairement désactivé pour éviter les crashs Web.
      // Un fichier audio valide devra être ajouté dans assets/sounds/
      print("Lecture audio demandée pour: $path");
    } catch (e) {
      print("Erreur Audio: $e");
    }
  }

  void playClick() => playSound('sounds/click.wav');
  void playCardFlip() => playSound('sounds/card_flip.wav');
  void playGlassClink() => playSound('sounds/glass_clink.wav');
  void playVictory() => playSound('sounds/victory.wav');
}
