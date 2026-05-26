import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/random_event.dart';

final randomEventProvider = StateNotifierProvider<RandomEventNotifier, RandomEvent?>((ref) {
  return RandomEventNotifier();
});

class RandomEventNotifier extends StateNotifier<RandomEvent?> {
  RandomEventNotifier() : super(null);

  final _random = Random();

  final List<RandomEvent> _possibleEvents = const [
    RandomEvent(
      title: "La Cascade 🌊",
      description: "Tout le monde commence à boire. Le Maître du Jeu s'arrête, puis le suivant, etc.",
      emoji: "🌊",
      type: "global",
    ),
    RandomEvent(
      title: "Le Roi des Pouces 👍",
      description: "Le dernier à mettre son pouce sur l'écran boit 2 gorgées !",
      emoji: "👍",
      type: "mini_game",
    ),
    RandomEvent(
      title: "Je n'ai jamais 🚫",
      description: "Le Maître du Jeu dit 'Je n'ai jamais...'. Ceux qui l'ont fait boivent 1 gorgée.",
      emoji: "🤫",
      type: "global",
    ),
    RandomEvent(
      title: "Gorgée de la Mort ☠️",
      description: "Le jeu désigne une personne au hasard qui boit 3 gorgées... Courage.",
      emoji: "☠️",
      type: "target",
    ),
    RandomEvent(
      title: "Changement de Sens 🔄",
      description: "Le sens du jeu s'inverse. Celui qui vient de jouer rejoue.",
      emoji: "🔄",
      type: "global",
    ),
    RandomEvent(
      title: "Cul Sec Général 🍻",
      description: "TRÈS RARE ! Tout le monde finit son verre. Santé !",
      emoji: "🍻",
      type: "global",
    ),
  ];

  /// Tente de déclencher un événement avec une probabilité donnée (ex: 0.1 pour 10%)
  void tryTriggerEvent({double probability = 0.15}) {
    if (_random.nextDouble() < probability) {
      final eventIndex = _random.nextInt(_possibleEvents.length);
      state = _possibleEvents[eventIndex];
    }
  }

  void clearEvent() {
    state = null;
  }
}
