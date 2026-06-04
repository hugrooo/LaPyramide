import 'models/card_model.dart';
import 'models/game_state.dart';
import 'models/player_model.dart';

class DistributionLogic {
  static GameState processChoice({
    required GameState state,
    required dynamic
        choice, // ex: CardColor, 'plus', 'moins', 'egal', 'interieur', 'exterieur', Suit
  }) {
    // 1. Tirer une carte du deck
    if (state.deck.isEmpty) return state; // Sécurité

    final drawnCard = state.deck.last;
    final newDeck = List<PyraCard>.from(state.deck)..removeLast();

    // 2. Trouver le joueur courant
    final playerIndex = state.currentDistributionPlayerIndex;
    final cardIndex = state.currentDistributionCardIndex;
    final player = state.players[playerIndex];

    // 3. Évaluer la réponse
    bool isCorrect = false;

    if (cardIndex == 0) {
      // Rouge ou Noir
      final colorStr = choice as String;
      final isCardRed = drawnCard.suit.isRed;
      if (colorStr == 'rouge') isCorrect = isCardRed;
      if (colorStr == 'noir') isCorrect = !isCardRed;
    } else if (cardIndex == 1) {
      // Plus, Moins, Égal
      final previousCard = player.hand[0];
      final option = choice as String;
      if (option == 'plus') isCorrect = drawnCard.value > previousCard.value;
      if (option == 'moins') isCorrect = drawnCard.value < previousCard.value;
      if (option == 'egal') isCorrect = drawnCard.value == previousCard.value;
    } else if (cardIndex == 2) {
      // Intérieur ou Extérieur
      final c1 = player.hand[0];
      final c2 = player.hand[1];
      final minVal = c1.value < c2.value ? c1.value : c2.value;
      final maxVal = c1.value > c2.value ? c1.value : c2.value;
      final option = choice as String;

      if (option == 'interieur') {
        isCorrect = drawnCard.value > minVal && drawnCard.value < maxVal;
      } else if (option == 'exterieur') {
        isCorrect = drawnCard.value < minVal || drawnCard.value > maxVal;
      } else {
        // Variante où c'est égal à l'une des bornes (souvent on prend d'office, ou c'est faux)
        isCorrect = false;
      }
    } else if (cardIndex == 3) {
      // Signe
      final suit = choice as CardSuit;
      isCorrect = drawnCard.suit == suit;
    }

    // 4. Mettre à jour la main du joueur
    final updatedHand = List<PyraCard>.from(player.hand)
      ..add(drawnCard.copyWith(isFaceUp: true));

    // 5. Appliquer les pénalités (si faux, le joueur prend)
    int sipsToAdd = isCorrect ? 0 : (cardIndex + 1);
    final updatedPlayer = player.copyWith(
      hand: updatedHand,
      totalSips: player.totalSips + sipsToAdd,
    );

    String message = isCorrect
        ? "✅ ${player.name} a juste ! Il distribue ${cardIndex + 1} pénalité(s) !"
        : "💥 ${player.name} a faux ! Il prend ${cardIndex + 1} pénalité(s) !";

    final updatedPlayers = List<Player>.from(state.players);
    updatedPlayers[playerIndex] = updatedPlayer;

    if (isCorrect) {
      final nextPending = [
        DrinkAssignment(
            fromPlayerId: player.id,
            toPlayerId: '',
            sips: cardIndex + 1,
            isBluff: false)
      ];
      return state.copyWith(
        deck: newDeck,
        players: updatedPlayers,
        pendingDrinks: nextPending,
        lastEventMessage: message,
        lastEventTime: DateTime.now().millisecondsSinceEpoch,
        lastBluffResult: BluffResult.success,
      );
    } else {
      // 6. Passer au joueur / carte suivante si faux (il a bu, c'est au suivant)
      int nextPlayerIndex = playerIndex + 1;
      int nextCardIndex = cardIndex;
      GamePhase nextPhase = GamePhase.distribution;

      if (nextPlayerIndex >= state.players.length) {
        nextPlayerIndex = 0;
        nextCardIndex++;
        if (nextCardIndex >= state.settings.cardsPerPlayer) {
          nextPhase = GamePhase.revealing;
          for (int i = 0; i < updatedPlayers.length; i++) {
            updatedPlayers[i] = updatedPlayers[i].copyWith(
                hand: updatedPlayers[i]
                    .hand
                    .map((c) => c.copyWith(isFaceUp: false))
                    .toList());
          }
        }
      }

      return state.copyWith(
        deck: newDeck,
        players: updatedPlayers,
        currentDistributionPlayerIndex: nextPlayerIndex,
        currentDistributionCardIndex: nextCardIndex,
        phase: nextPhase,
        lastEventMessage: message,
        lastEventTime: DateTime.now().millisecondsSinceEpoch,
        lastBluffResult: BluffResult.caught,
      );
    }
  }

  /// Lorsqu'un joueur a juste et distribue ses pénalités
  static GameState distributeBusDrinks({
    required GameState state,
    required String targetPlayerId,
  }) {
    if (state.pendingDrinks.isEmpty) return state;

    final assignment = state.pendingDrinks.first;

    // Ajouter les pénalités à la cible
    final updatedPlayers = state.players.map((p) {
      if (p.id == targetPlayerId) {
        return p.copyWith(totalSips: p.totalSips + assignment.sips);
      }
      return p;
    }).toList();

    // Passer au joueur / carte suivante
    int nextPlayerIndex = state.currentDistributionPlayerIndex + 1;
    int nextCardIndex = state.currentDistributionCardIndex;
    GamePhase nextPhase = GamePhase.distribution;

    if (nextPlayerIndex >= state.players.length) {
      nextPlayerIndex = 0;
      nextCardIndex++;
      if (nextCardIndex >= state.settings.cardsPerPlayer) {
        nextPhase = GamePhase.revealing;
        for (int i = 0; i < updatedPlayers.length; i++) {
          updatedPlayers[i] = updatedPlayers[i].copyWith(
              hand: updatedPlayers[i]
                  .hand
                  .map((c) => c.copyWith(isFaceUp: false))
                  .toList());
        }
      }
    }

    final fromPlayer =
        updatedPlayers.firstWhere((p) => p.id == assignment.fromPlayerId);
    final toPlayer = updatedPlayers.firstWhere((p) => p.id == targetPlayerId);

    return state.copyWith(
      players: updatedPlayers,
      currentDistributionPlayerIndex: nextPlayerIndex,
      currentDistributionCardIndex: nextCardIndex,
      phase: nextPhase,
      pendingDrinks: [],
      lastEventMessage:
          "🎯 ${fromPlayer.name} a donné ${assignment.sips} pénalité(s) à ${toPlayer.name} !",
      lastEventTime: DateTime.now().millisecondsSinceEpoch,
    );
  }
}
