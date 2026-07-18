import 'dart:math';
import 'package:uuid/uuid.dart';
import 'models/card_model.dart';
import 'models/player_model.dart';
import 'models/game_state.dart';

/// Logique centrale du jeu La Pyramide
class GameLogic {
  /// Crée un nouvel état de jeu initial
  static GameState initGame({
    required List<Player> players,
    required GameSettings settings,
  }) {
    List<PyraCard> deck = PyraCard.generateDeck();

    if (settings.mode == GameMode.powers) {
      deck = _injectPowers(deck, settings);
    } else if (settings.mode == GameMode.miniGames) {
      deck = _injectMiniGames(deck);
    }

    // Distribuer les missions secrètes si activé
    List<Player> tempPlayers = List.from(players);
    if (settings.mode == GameMode.secretMissions) {
      final missions = _getSecretMissions();
      missions.shuffle();
      for (int i = 0; i < tempPlayers.length; i++) {
        tempPlayers[i] = tempPlayers[i]
            .copyWith(secretMission: missions[i % missions.length]);
      }
    }

    int deckIndex = 0;

    // Distribuer les cartes aux joueurs (face cachée)
    final updatedPlayers = tempPlayers.map((player) {
      final hand = <PyraCard>[];
      for (int i = 0; i < settings.cardsPerPlayer; i++) {
        hand.add(deck[deckIndex++].copyWith(isFaceUp: false));
      }
      return player.copyWith(hand: hand);
    }).toList();

    // Construire la pyramide (sommet = 1 carte en haut, base = N cartes en bas)
    // Rangée 0 = sommet (plus de pénalités), dernière rangée = base (moins)
    // Pour s'aligner avec la logique en ligne et éviter les crashs de ligne,
    // on construit la pyramide avec la base en bas (ligne pyramidRows - 1)
    final pyramid = <List<PyraCard>>[];
    for (int row = 0; row < settings.pyramidRows; row++) {
      final rowSize = row +
          1; // Rangée 0 = 1 carte (sommet), dernière rangée = settings.pyramidRows (base)
      final rowCards = <PyraCard>[];
      for (int i = 0; i < rowSize; i++) {
        rowCards.add(deck[deckIndex++].copyWith(isFaceUp: false));
      }
      pyramid.add(rowCards);
    }

    return GameState(
      gameId: const Uuid().v4(),
      pyramid: pyramid,
      players: updatedPlayers,
      deck: deck.sublist(deckIndex),
      phase: GamePhase.revealing,
      currentRow: settings.pyramidRows - 1, // Commencer par la base (en bas)
      currentCardIndex: 0,
      pendingDrinks: [],
      settings: settings,
    );
  }

  /// Retourne la carte courante de la pyramide
  static GameState revealCurrentCard(GameState state) {
    if (state.currentCard == null) return state;

    final newPyramid = state.pyramid.map((row) => row.toList()).toList();
    final revealedCard =
        state.currentCard!.copyWith(isFaceUp: true, isRevealed: true);
    newPyramid[state.currentRow][state.currentCardIndex] = revealedCard;

    String? eventMessage;
    int? eventTime;
    if (state.settings.mode == GameMode.truthOrSip &&
        (revealedCard.value == 1 || revealedCard.value >= 11)) {
      eventMessage = "🎭 Vérité ou Pénalité ! " + _getRandomTruthOrSip();
      eventTime = DateTime.now().millisecondsSinceEpoch;
    }

    return state.copyWith(
      pyramid: newPyramid,
      phase: revealedCard.isMiniGame ? GamePhase.miniGame : GamePhase.assigning,
      lastRevealedCard: revealedCard,
      lastEventMessage: eventMessage ?? state.lastEventMessage,
      lastEventTime: eventTime ?? state.lastEventTime,
    );
  }

  /// Met fin à un mini-jeu
  static GameState endMiniGame(GameState state) {
    return state.copyWith(phase: GamePhase.assigning);
  }

  /// Divise les pénalités entre plusieurs joueurs
  static GameState assignDrinkSplit({
    required GameState state,
    required String fromPlayerId,
    required List<String> toPlayerIds,
    required int totalSips,
  }) {
    final perPlayer = (totalSips / toPlayerIds.length).ceil();
    final totalGiven = perPlayer * toPlayerIds.length;

    final updatedPlayers = state.players.map((p) {
      if (toPlayerIds.contains(p.id)) {
        return p.copyWith(totalSips: p.totalSips + perPlayer);
      }
      if (p.id == fromPlayerId) {
        return p.copyWith(drinksGiven: p.drinksGiven + totalGiven);
      }
      return p;
    }).toList();

    final from = state.players.firstWhere((p) => p.id == fromPlayerId);
    final targets = state.players
        .where((p) => toPlayerIds.contains(p.id))
        .map((p) => p.emoji)
        .join(' ');
    final unit = state.settings.penaltyUnitPlural;

    return state.copyWith(
      players: updatedPlayers,
      phase: GamePhase.transition,
      lastEventMessage:
          "🎯 ${from.name} divise $totalSips $unit → $perPlayer chacun à $targets !",
      lastEventTime: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Un joueur assigne des pénalités à un autre joueur
  /// Peut poser une carte (vraie ou bluff) ou assigner directement
  static GameState assignDrink({
    required GameState state,
    required String fromPlayerId,
    required String toPlayerId,
    bool isPigeon = false,
  }) {
    final sips = isPigeon ? state.currentSips * 2 : state.currentSips;
    final assignment = DrinkAssignment(
      fromPlayerId: fromPlayerId,
      toPlayerId: toPlayerId,
      sips: sips,
      isBluff: false, // Inconnu à ce stade
      isBluffCalled: false,
    );

    var newPlayers = state.players;
    if (isPigeon) {
      newPlayers = newPlayers.map((p) {
        if (p.id == fromPlayerId) return p.copyWith(hasUsedPigeon: true);
        return p;
      }).toList();
    }

    return state.copyWith(
      phase: GamePhase.bluffing,
      players: newPlayers,
      pendingDrinks: [...state.pendingDrinks, assignment],
    );
  }

  /// Le joueur ciblé crie au bluff
  static GameState callBluff(GameState state) {
    if (state.pendingDrinks.isEmpty) return state;

    final assignment = state.pendingDrinks.last;
    final updatedAssignment = DrinkAssignment(
      fromPlayerId: assignment.fromPlayerId,
      toPlayerId: assignment.toPlayerId,
      sips: assignment.sips,
      isBluff: assignment.isBluff,
      isBluffCalled: true,
    );

    final newPending = List<DrinkAssignment>.from(state.pendingDrinks);
    newPending[newPending.length - 1] = updatedAssignment;

    return state.copyWith(pendingDrinks: newPending);
  }

  /// Le joueur accusé révèle une carte ou avoue
  static GameState resolveBluff({
    required GameState state,
    required String fromPlayerId,
    String? cardId, // S'il avoue, cardId est null
  }) {
    if (state.pendingDrinks.isEmpty) return state;

    final assignment = state.pendingDrinks.last;
    GameState newState =
        state.copyWith(pendingDrinks: []); // On résout l'action

    // Trouver la carte si fournie
    PyraCard? revealedCard;
    if (cardId != null) {
      final player = state.players.firstWhere((p) => p.id == fromPlayerId);
      revealedCard = player.hand.firstWhere((c) => c.id == cardId);

      // On la marque comme révélée pour qu'elle soit retournée face visible
      final updatedHand = player.hand
          .map((c) => c.id == cardId ? c.copyWith(isFaceUp: true) : c)
          .toList();
      newState = newState.copyWith(
        players: newState.players
            .map(
                (p) => p.id == fromPlayerId ? p.copyWith(hand: updatedHand) : p)
            .toList(),
      );
    }

    final targetCard = state.lastRevealedCard ?? state.currentCard;
    final isActuallyBluff = revealedCard == null ||
        targetCard == null ||
        revealedCard.value != targetCard.value;

    if (isActuallyBluff) {
      // Le bluffeur a menti (ou s'est trompé) -> il prend le double
      final penalty = DrinkAssignment(
        fromPlayerId: assignment.toPlayerId,
        toPlayerId: assignment.fromPlayerId,
        sips: assignment.sips * (state.settings.doubleBluff ? 3 : 2),
      );
      final fromPlayer = state.players.firstWhere((p) => p.id == fromPlayerId);
      final toPlayer =
          state.players.firstWhere((p) => p.id == assignment.toPlayerId);
      final unit = state.settings.penaltyUnitPlural;

      newState = _applyDrink(newState, penalty);
      newState = _updateBluffStats(
        newState,
        blufferId: assignment.fromPlayerId,
        challengerId: assignment.toPlayerId,
        bluffCaught: true,
      );
      return newState.copyWith(
        phase: GamePhase.assigning,
        lastBluffResult: BluffResult.caught,
        lastPlayerRevealedCard: revealedCard?.copyWith(isFaceUp: true),
        lastBlufferId: assignment.fromPlayerId,
        lastEventMessage:
            "💥 Bluff démasqué ! ${fromPlayer.name} prend ${penalty.sips} $unit !",
        lastEventTime: DateTime.now().millisecondsSinceEpoch,
      );
    } else {
      // Le joueur dit la vérité -> la cible prend le double
      final penalty = DrinkAssignment(
        fromPlayerId: assignment.fromPlayerId,
        toPlayerId: assignment.toPlayerId,
        sips: assignment.sips * (state.settings.doubleBluff ? 3 : 2),
      );
      final fromPlayer = state.players.firstWhere((p) => p.id == fromPlayerId);
      final toPlayer =
          state.players.firstWhere((p) => p.id == assignment.toPlayerId);
      final unit = state.settings.penaltyUnitPlural;

      newState = _applyDrink(newState, penalty);
      newState = _updateBluffStats(
        newState,
        blufferId: assignment.fromPlayerId,
        challengerId: assignment.toPlayerId,
        bluffCaught: false,
      );
      return newState.copyWith(
        phase: GamePhase.assigning,
        lastBluffResult: BluffResult.success,
        lastPlayerRevealedCard: revealedCard?.copyWith(isFaceUp: true),
        lastBlufferId: assignment.fromPlayerId,
        lastEventMessage:
            "✅ Pas de bluff ! ${toPlayer.name} prend ${penalty.sips} $unit !",
        lastEventTime: DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  /// Le joueur ciblé accepte (prend sans challenger)
  static GameState acceptDrink(GameState state) {
    if (state.pendingDrinks.isEmpty) return state;

    final assignment = state.pendingDrinks.last;
    GameState newState = state.copyWith(pendingDrinks: []);
    return _applyDrink(newState, assignment);
  }

  /// Le temps est écoulé en mode Speed-Run, on prend les pénalités + 2 de punition
  static GameState speedRunTimeoutPenalty(GameState state) {
    if (state.pendingDrinks.isEmpty) return state;

    final assignment = state.pendingDrinks.last;
    GameState newState = state.copyWith(pendingDrinks: []);

    // On ajoute 2 pénalités de pénalité pour trop de temps
    final penaltyAssignment = DrinkAssignment(
      fromPlayerId: assignment.fromPlayerId,
      toPlayerId: assignment.toPlayerId,
      sips: assignment.sips + 2,
    );

    return _applyDrink(newState, penaltyAssignment);
  }

  /// Le joueur ciblé utilise un pouvoir pour se défendre
  static GameState usePower({
    required GameState state,
    required String playerId,
    required String cardId,
  }) {
    if (state.pendingDrinks.isEmpty) return state;

    final assignment = state.pendingDrinks.last;
    if (assignment.toPlayerId != playerId) return state;

    final playerIndex = state.players.indexWhere((p) => p.id == playerId);
    if (playerIndex == -1) return state;

    final player = state.players[playerIndex];
    final cardIndex = player.hand.indexWhere((c) => c.id == cardId);
    if (cardIndex == -1) return state;

    final card = player.hand[cardIndex];
    if (card.powerType == PowerType.none) return state;

    // Retirer la carte de la main (le pouvoir est consommé)
    final newHand = List<PyraCard>.from(player.hand)..removeAt(cardIndex);
    final updatedPlayer = player.copyWith(hand: newHand);

    final updatedPlayers = List<Player>.from(state.players);
    updatedPlayers[playerIndex] = updatedPlayer;

    GameState newState = state.copyWith(
      pendingDrinks: [],
      players: updatedPlayers,
      lastRevealedCard: card.copyWith(isFaceUp: true), // On montre le pouvoir
    );

    final unit = state.settings.penaltyUnitPlural;
    if (card.powerType == PowerType.shield) {
      return newState.copyWith(
        phase: GamePhase.transition,
        lastEventMessage:
            "🛡️ ${player.name} utilise un Bouclier ! $unit annulé(e)s.",
        lastEventTime: DateTime.now().millisecondsSinceEpoch,
      );
    } else if (card.powerType == PowerType.mirror) {
      final reflection = DrinkAssignment(
        fromPlayerId: assignment.toPlayerId,
        toPlayerId: assignment.fromPlayerId,
        sips: assignment.sips,
      );

      final attacker =
          state.players.firstWhere((p) => p.id == assignment.fromPlayerId);
      newState = _applyDrink(newState, reflection);

      return newState.copyWith(
        phase: GamePhase.transition,
        lastEventMessage:
            "🪞 ${player.name} sort le Miroir ! ${attacker.name} prend le retour : ${reflection.sips} $unit !",
        lastEventTime: DateTime.now().millisecondsSinceEpoch,
      );
    } else if (card.powerType == PowerType.multiplier) {
      final reflection = DrinkAssignment(
        fromPlayerId: assignment.toPlayerId,
        toPlayerId: assignment.fromPlayerId,
        sips: assignment.sips * 2,
      );

      final attacker =
          state.players.firstWhere((p) => p.id == assignment.fromPlayerId);
      newState = _applyDrink(newState, reflection);

      return newState.copyWith(
        phase: GamePhase.transition,
        lastEventMessage:
            "⚡ ${player.name} utilise un Multiplicateur ! ${attacker.name} prend ${reflection.sips} $unit (x2) !",
        lastEventTime: DateTime.now().millisecondsSinceEpoch,
      );
    }

    return state;
  }

  /// Passe à la carte suivante / rangée suivante
  static GameState nextCard(GameState state) {
    final currentRow = state.pyramid[state.currentRow];
    final nextCardIndex = state.currentCardIndex + 1;
    final newPlayers =
        state.players.map((p) => p.copyWith(hasPassedThisTurn: false)).toList();

    if (nextCardIndex < currentRow.length) {
      // Carte suivante dans la même rangée
      return state.copyWith(
        players: newPlayers,
        currentCardIndex: nextCardIndex,
        phase: GamePhase.revealing,
        lastBluffResult: BluffResult.none,
        clearLastPlayerRevealedCard: true,
      );
    }

    // Rangée suivante (on monte)
    final nextRow = state.currentRow - 1;
    if (nextRow < 0) {
      // Partie terminée
      return state.copyWith(
        players: newPlayers,
        phase: GamePhase.finished,
        clearLastPlayerRevealedCard: true,
      );
    }

    return state.copyWith(
      players: newPlayers,
      currentRow: nextRow,
      currentCardIndex: 0,
      phase: GamePhase.revealing,
      lastBluffResult: BluffResult.none,
      clearLastPlayerRevealedCard: true,
    );
  }

  // === Helpers privés ===

  static List<PyraCard> _injectPowers(
      List<PyraCard> originalDeck, GameSettings settings) {
    final powers = [
      PyraCard(powerType: PowerType.shield),
      PyraCard(powerType: PowerType.shield),
      PyraCard(powerType: PowerType.mirror),
      PyraCard(powerType: PowerType.mirror),
      PyraCard(powerType: PowerType.multiplier),
      PyraCard(powerType: PowerType.multiplier),
    ];

    if (settings.replaceCardsWithPowers) {
      // Remplace des cartes aléatoires du deck
      final newDeck = List<PyraCard>.from(originalDeck);
      newDeck.shuffle();
      for (int i = 0; i < powers.length; i++) {
        newDeck[i] = powers[i];
      }
      newDeck.shuffle();
      return newDeck;
    } else {
      // Ajoute simplement les pouvoirs au deck
      final newDeck = [...originalDeck, ...powers];
      newDeck.shuffle();
      return newDeck;
    }
  }

  static bool _playerHasCard(GameState state, String playerId, PyraCard card) {
    final player = state.players.firstWhere((p) => p.id == playerId);
    return player.hand.any((c) => c.value == card.value);
  }

  static GameState _applyDrink(GameState state, DrinkAssignment assignment) {
    final updatedPlayers = state.players.map((p) {
      if (p.id == assignment.toPlayerId) {
        return p.copyWith(totalSips: p.totalSips + assignment.sips);
      }
      if (p.id == assignment.fromPlayerId) {
        return p.copyWith(drinksGiven: p.drinksGiven + assignment.sips);
      }
      return p;
    }).toList();

    return state.copyWith(
      players: updatedPlayers,
      phase: GamePhase.transition,
    );
  }

  static GameState _updateBluffStats(
    GameState state, {
    required String blufferId,
    required String challengerId,
    required bool bluffCaught,
  }) {
    final updatedPlayers = state.players.map((p) {
      if (p.id == blufferId) {
        return bluffCaught
            ? p.copyWith(bluffsLost: p.bluffsLost + 1)
            : p.copyWith(bluffsWon: p.bluffsWon + 1);
      }
      if (p.id == challengerId) {
        return bluffCaught
            ? p.copyWith(challengesWon: p.challengesWon + 1)
            : p.copyWith(challengesLost: p.challengesLost + 1);
      }
      return p;
    }).toList();

    return state.copyWith(players: updatedPlayers);
  }

  static List<PyraCard> _injectMiniGames(List<PyraCard> originalDeck) {
    final miniGames = [
      PyraCard(
          isMiniGame: true,
          miniGameTitle: 'Dans ma valise',
          miniGameDescription:
              'Tour à tour, chacun répète les objets précédents et en ajoute un nouveau. Le premier qui se trompe est pénalisé !'),
      PyraCard(
          isMiniGame: true,
          miniGameTitle: 'Le jeu des Rimes',
          miniGameDescription:
              'L\'hôte choisit un mot. Chacun doit trouver une rime. Le premier qui bloque est pénalisé !'),
      PyraCard(
          isMiniGame: true,
          miniGameTitle: 'Thème',
          miniGameDescription:
              'L\'hôte choisit un thème (ex: Marques de voitures). Chacun donne un exemple. Le premier qui bloque est pénalisé !'),
      PyraCard(
          isMiniGame: true,
          miniGameTitle: 'Action ou Vérité',
          miniGameDescription:
              'Le joueur qui a retourné la carte choisit quelqu\'un. Action ou Vérité ? S\'il refuse, il est pénalisé !'),
    ];
    miniGames.shuffle();

    // Remplacer 3 cartes aléatoires du deck
    final newDeck = List<PyraCard>.from(originalDeck);
    newDeck.shuffle();
    for (int i = 0; i < 3 && i < miniGames.length; i++) {
      newDeck[i] = miniGames[i];
    }
    newDeck.shuffle();
    return newDeck;
  }

  static List<String> _getSecretMissions() {
    return [
      'Glisse le mot "Parapluie" dans une phrase sans te faire remarquer.',
      'Fais prendre 2 fois le joueur à ta droite pendant cette partie.',
      'Place 3 bluffs sans jamais te faire prendre.',
      'Fais en sorte que quelqu\'un d\'autre utilise le mot "Pyramide".',
      'Appelle l\'hôte par un surnom inventé sans qu\'il s\'en rende compte.',
      'Dénonce un bluff (à tort ou à raison) au moins une fois.',
    ];
  }

  static String _getRandomTruthOrSip() {
    final questions = [
      "Vérité: Raconte ton pire rencard amoureux.",
      "Action: Danse la carioca pendant 30 secondes ou tu es pénalisé !",
      "Vérité: Quel est le joueur le plus menteur selon toi ?",
      "Action: Fais rire quelqu'un d'autre ou tu es pénalisé !",
      "Vérité: Quel est le secret inavouable que tu gardes ?",
      "Action: Fais un câlin à un joueur ou tu es pénalisé !",
      "Vérité: Qui a le meilleur bluff à cette table ?",
      "Action: Laisse ton voisin de droite lire tes SMS ou tu es pénalisé !",
    ];
    return questions[Random().nextInt(questions.length)];
  }

  static GameState useJoker({
    required GameState state,
    required String playerId,
    required String jokerId,
  }) {
    if (state.pendingDrinks.isEmpty) return state;

    final assignment = state.pendingDrinks.last;
    final unit = state.settings.penaltyUnitPlural;

    if (jokerId == 'miroir' && assignment.toPlayerId == playerId) {
      final reflection = DrinkAssignment(
        fromPlayerId: assignment.toPlayerId,
        toPlayerId: assignment.fromPlayerId,
        sips: assignment.sips,
      );
      final attacker =
          state.players.firstWhere((p) => p.id == assignment.fromPlayerId);

      GameState newState = state.copyWith(pendingDrinks: []);
      newState = _applyDrink(newState, reflection);

      return newState.copyWith(
        phase: GamePhase.transition,
        lastEventMessage:
            "🪞 Joker Miroir ! Les ${reflection.sips} $unit de ${attacker.name} se retournent contre lui !",
        lastEventTime: DateTime.now().millisecondsSinceEpoch,
      );
    } else if (jokerId == 'bouclier' && assignment.toPlayerId == playerId) {
      final defender = state.players.firstWhere((p) => p.id == playerId);
      final reducedSips = (assignment.sips / 2).ceil();

      final shielded = DrinkAssignment(
        fromPlayerId: assignment.fromPlayerId,
        toPlayerId: assignment.toPlayerId,
        sips: reducedSips,
      );

      GameState newState = state.copyWith(pendingDrinks: []);
      newState = _applyDrink(newState, shielded);

      return newState.copyWith(
        phase: GamePhase.transition,
        lastEventMessage:
            "🛡️ Joker Bouclier ! ${defender.name} réduit à $reducedSips $unit (au lieu de ${assignment.sips}) !",
        lastEventTime: DateTime.now().millisecondsSinceEpoch,
      );
    } else if (jokerId == 'double_dose' &&
        assignment.fromPlayerId == playerId) {
      final newSips = assignment.sips * 2;
      final doubledAssignment = DrinkAssignment(
        fromPlayerId: assignment.fromPlayerId,
        toPlayerId: assignment.toPlayerId,
        sips: newSips,
        isBluff: assignment.isBluff,
        isBluffCalled: assignment.isBluffCalled,
      );

      final newPending = List<DrinkAssignment>.from(state.pendingDrinks);
      newPending[newPending.length - 1] = doubledAssignment;

      final fromPlayer = state.players.firstWhere((p) => p.id == playerId);

      return state.copyWith(
        pendingDrinks: newPending,
        lastEventMessage:
            "🧪 Joker Double Dose ! ${fromPlayer.name} double la punition : $newSips $unit !",
        lastEventTime: DateTime.now().millisecondsSinceEpoch,
      );
    }

    return state;
  }
}
