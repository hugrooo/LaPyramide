import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final AudioPlayer _player = AudioPlayer();
  bool isMuted = false;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isMuted = prefs.getBool('isMuted') ?? false;
  }

  void setMuted(bool muted) async {
    isMuted = muted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isMuted', muted);
  }

  void playSound(String path) async {
    if (isMuted) return;
    try {
      // On utilise un AudioPlayer jetable pour jouer plusieurs sons en même temps si besoin
      final p = AudioPlayer();
      await p.play(AssetSource(path));
      p.onPlayerComplete.listen((_) => p.dispose());
    } catch (e) {
      // Ignorer si le fichier n'est pas trouvé
      print("Erreur Audio: $e");
    }
  }

  void playTaunt() => playSound('sounds/taunt.mp3');
  void playDrink() => playSound('sounds/drink.mp3');
  void playBluff() => playSound('sounds/bluff.mp3');
  void playWin() => playSound('sounds/win.mp3');
}
