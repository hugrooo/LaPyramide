import 'card_model.dart';
import 'player_model.dart';

enum GamePhase {
  setup, // Configuration
  distribution, // Le Bus (distribution)
  revealing, // Révélation des cartes
  assigning, // Attribution des pénalités
  bluffing, // Phase de bluff en cours
  transition, // Passage au joueur suivant
  miniGame, // Phase d'un mini-jeu
  finished, // Partie terminée
}

enum GameMode {
  classic,
  powers,
  secretMissions,
  miniGames,
  truthOrSip,
  speedRun,
}

enum BluffResult { none, caught, success }

class DrinkAssignment {
  final String fromPlayerId; // Celui qui assigne
  final String toPlayerId; // Celui qui doit prendre
  final int sips;
  final bool isBluff; // Vrai si la carte posée est un bluff
  final bool isBluffCalled; // Vrai si la cible a crié au bluff

  DrinkAssignment({
    required this.fromPlayerId,
    required this.toPlayerId,
    required this.sips,
    this.isBluff = false,
    this.isBluffCalled = false,
  });

  Map<String, dynamic> toJson() => {
        'fromPlayerId': fromPlayerId,
        'toPlayerId': toPlayerId,
        'sips': sips,
        'isBluff': isBluff,
        'isBluffCalled': isBluffCalled,
      };

  factory DrinkAssignment.fromJson(Map<String, dynamic> json) =>
      DrinkAssignment(
        fromPlayerId: json['fromPlayerId'],
        toPlayerId: json['toPlayerId'],
        sips: json['sips'],
        isBluff: json['isBluff'] ?? false,
        isBluffCalled: json['isBluffCalled'] ?? false,
      );
}

class GameSettings {
  final GameMode mode; // Mode de jeu actuel
  final bool
      replaceCardsWithPowers; // Si le joueur a choisi de remplacer des cartes classiques par les pouvoirs
  final int pyramidRows; // Nombre de rangées (3, 4 ou 5)
  final bool bluffEnabled; // Bluff activé
  final bool doubleBluff; // Double mise sur bluff
  final bool superChallenge; // Super challenge (triple mise)
  final int cardsPerPlayer; // Cartes par joueur (défaut 4)

  const GameSettings({
    this.mode = GameMode.classic,
    this.replaceCardsWithPowers = false,
    this.pyramidRows = 5,
    this.bluffEnabled = true,
    this.doubleBluff = false,
    this.superChallenge = false,
    this.cardsPerPlayer = 4,
  });

  GameSettings copyWith({
    GameMode? mode,
    bool? replaceCardsWithPowers,
    int? pyramidRows,
    bool? bluffEnabled,
    bool? doubleBluff,
    bool? superChallenge,
    int? cardsPerPlayer,
  }) {
    return GameSettings(
      mode: mode ?? this.mode,
      replaceCardsWithPowers:
          replaceCardsWithPowers ?? this.replaceCardsWithPowers,
      pyramidRows: pyramidRows ?? this.pyramidRows,
      bluffEnabled: bluffEnabled ?? this.bluffEnabled,
      doubleBluff: doubleBluff ?? this.doubleBluff,
      superChallenge: superChallenge ?? this.superChallenge,
      cardsPerPlayer: cardsPerPlayer ?? this.cardsPerPlayer,
    );
  }

  /// Nombre de pénalités pour une rangée donnée (0-indexed depuis le bas)
  int sipsForRow(int rowIndex) => rowIndex + 1;

  Map<String, dynamic> toJson() => {
        'mode': mode.index,
        'replaceCardsWithPowers': replaceCardsWithPowers,
        'pyramidRows': pyramidRows,
        'bluffEnabled': bluffEnabled,
        'doubleBluff': doubleBluff,
        'superChallenge': superChallenge,
        'cardsPerPlayer': cardsPerPlayer,
      };

  factory GameSettings.fromJson(Map<String, dynamic> json) => GameSettings(
        mode: json['mode'] != null
            ? GameMode.values[json['mode']]
            : GameMode.classic,
        replaceCardsWithPowers: json['replaceCardsWithPowers'] ?? false,
        pyramidRows: json['pyramidRows'] ?? 5,
        bluffEnabled: json['bluffEnabled'] ?? true,
        doubleBluff: json['doubleBluff'] ?? false,
        superChallenge: json['superChallenge'] ?? false,
        cardsPerPlayer: json['cardsPerPlayer'] ?? 4,
      );
}

class GameState {
  final String gameId;
  final List<List<PyraCard>> pyramid; // [rangée][carte] — rangée 0 = sommet
  final List<Player> players;
  final List<PyraCard> deck;
  final GamePhase phase;
  final int currentRow; // Rangée en cours de révélation (0 = sommet)
  final int currentCardIndex; // Index dans la rangée en cours
  final int currentDistributionPlayerIndex;
  final int currentDistributionCardIndex;
  final int endGamePlayerIndex;
  final String? lastEventMessage;
  final int? lastEventTime;
  final List<DrinkAssignment> pendingDrinks;
  final GameSettings settings;
  final BluffResult lastBluffResult;
  final PyraCard? lastRevealedCard;
  final PyraCard?
      lastPlayerRevealedCard; // Carte réelle révélée par le joueur lors du bluff (pour animation Totem)
  final String? lastBlufferId; // ID du joueur qui a posé la carte lors du bluff
  final Map<String, bool> presence; // Map playerId -> isOnline
  final Map<String, dynamic>? lastTaunt;
  final Map<String, dynamic>? currentRandomEvent;
  final int? updatedAt;

  const GameState({
    required this.gameId,
    required this.pyramid,
    required this.players,
    required this.deck,
    required this.phase,
    required this.currentRow,
    required this.currentCardIndex,
    this.currentDistributionPlayerIndex = 0,
    this.currentDistributionCardIndex = 0,
    this.endGamePlayerIndex = 0,
    this.lastEventMessage,
    this.lastEventTime,
    required this.pendingDrinks,
    required this.settings,
    this.lastBluffResult = BluffResult.none,
    this.lastRevealedCard,
    this.lastPlayerRevealedCard,
    this.lastBlufferId,
    this.presence = const {},
    this.lastTaunt,
    this.currentRandomEvent,
    this.updatedAt,
  });

  PyraCard? get currentCard {
    if (currentRow >= pyramid.length) return null;
    final row = pyramid[currentRow];
    if (currentCardIndex >= row.length) return null;
    return row[currentCardIndex];
  }

  bool get isFinished => currentRow < 0;

  int get currentSips => settings.sipsForRow(pyramid.length - 1 - currentRow);

  GameState copyWith({
    List<List<PyraCard>>? pyramid,
    List<Player>? players,
    List<PyraCard>? deck,
    GamePhase? phase,
    int? currentRow,
    int? currentCardIndex,
    int? currentDistributionPlayerIndex,
    int? currentDistributionCardIndex,
    int? endGamePlayerIndex,
    String? lastEventMessage,
    int? lastEventTime,
    List<DrinkAssignment>? pendingDrinks,
    BluffResult? lastBluffResult,
    PyraCard? lastRevealedCard,
    PyraCard? lastPlayerRevealedCard,
    String? lastBlufferId,
    bool clearLastPlayerRevealedCard = false,
    Map<String, bool>? presence,
    Map<String, dynamic>? lastTaunt,
    Map<String, dynamic>? currentRandomEvent,
    int? updatedAt,
  }) {
    return GameState(
      gameId: gameId,
      pyramid: pyramid ?? this.pyramid,
      players: players ?? this.players,
      deck: deck ?? this.deck,
      phase: phase ?? this.phase,
      currentRow: currentRow ?? this.currentRow,
      currentCardIndex: currentCardIndex ?? this.currentCardIndex,
      currentDistributionPlayerIndex:
          currentDistributionPlayerIndex ?? this.currentDistributionPlayerIndex,
      currentDistributionCardIndex:
          currentDistributionCardIndex ?? this.currentDistributionCardIndex,
      endGamePlayerIndex: endGamePlayerIndex ?? this.endGamePlayerIndex,
      lastEventMessage: lastEventMessage ?? this.lastEventMessage,
      lastEventTime: lastEventTime ?? this.lastEventTime,
      pendingDrinks: pendingDrinks ?? this.pendingDrinks,
      settings: settings,
      lastBluffResult: lastBluffResult ?? this.lastBluffResult,
      lastRevealedCard: lastRevealedCard ?? this.lastRevealedCard,
      lastPlayerRevealedCard: clearLastPlayerRevealedCard
          ? null
          : (lastPlayerRevealedCard ?? this.lastPlayerRevealedCard),
      lastBlufferId: lastBlufferId ?? this.lastBlufferId,
      presence: presence ?? this.presence,
      lastTaunt: lastTaunt ?? this.lastTaunt,
      currentRandomEvent: currentRandomEvent ?? this.currentRandomEvent,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'gameId': gameId,
        'pyramid':
            pyramid.map((row) => row.map((c) => c.toJson()).toList()).toList(),
        'players': players.map((p) => p.toJson()).toList(),
        'deck': deck.map((c) => c.toJson()).toList(),
        'phase': phase.index,
        'currentRow': currentRow,
        'currentCardIndex': currentCardIndex,
        'currentDistributionPlayerIndex': currentDistributionPlayerIndex,
        'currentDistributionCardIndex': currentDistributionCardIndex,
        'endGamePlayerIndex': endGamePlayerIndex,
        'lastEventMessage': lastEventMessage,
        'lastEventTime': lastEventTime,
        'pendingDrinks': pendingDrinks.map((d) => d.toJson()).toList(),
        'settings': settings.toJson(),
        'lastBluffResult': lastBluffResult.index,
        'lastRevealedCard': lastRevealedCard?.toJson(),
        'lastPlayerRevealedCard': lastPlayerRevealedCard?.toJson(),
        'lastBlufferId': lastBlufferId,
        'presence': presence,
        'lastTaunt': lastTaunt,
        'currentRandomEvent': currentRandomEvent,
        'updatedAt': updatedAt,
      };

  factory GameState.fromJson(Map<String, dynamic> json) => GameState(
        gameId: json['gameId'],
        pyramid: (json['pyramid'] as List)
            .map((row) =>
                (row as List).map((c) => PyraCard.fromJson(c)).toList())
            .toList(),
        players:
            (json['players'] as List).map((p) => Player.fromJson(p)).toList(),
        deck: json['deck'] != null
            ? (json['deck'] as List).map((c) => PyraCard.fromJson(c)).toList()
            : [],
        phase: GamePhase.values[json['phase']],
        currentRow: json['currentRow'],
        currentCardIndex: json['currentCardIndex'],
        currentDistributionPlayerIndex:
            json['currentDistributionPlayerIndex'] ?? 0,
        currentDistributionCardIndex: json['currentDistributionCardIndex'] ?? 0,
        endGamePlayerIndex: json['endGamePlayerIndex'] ?? 0,
        lastEventMessage: json['lastEventMessage'],
        lastEventTime: json['lastEventTime'],
        pendingDrinks: json['pendingDrinks'] != null
            ? (json['pendingDrinks'] as List)
                .map((d) => DrinkAssignment.fromJson(d))
                .toList()
            : [],
        settings: json['settings'] != null
            ? GameSettings.fromJson(json['settings'])
            : const GameSettings(),
        lastBluffResult: json['lastBluffResult'] != null
            ? BluffResult.values[json['lastBluffResult']]
            : BluffResult.none,
        lastRevealedCard: json['lastRevealedCard'] != null
            ? PyraCard.fromJson(json['lastRevealedCard'])
            : null,
        lastPlayerRevealedCard: json['lastPlayerRevealedCard'] != null
            ? PyraCard.fromJson(json['lastPlayerRevealedCard'])
            : null,
        lastBlufferId: json['lastBlufferId'],
        presence: json['presence'] != null
            ? Map<String, bool>.from(json['presence'])
            : {},
        lastTaunt: json['lastTaunt'] != null
            ? Map<String, dynamic>.from(json['lastTaunt'])
            : null,
        currentRandomEvent: json['currentRandomEvent'] != null
            ? Map<String, dynamic>.from(json['currentRandomEvent'])
            : null,
        updatedAt: json['updatedAt'],
      );
}
