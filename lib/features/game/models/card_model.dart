import 'package:uuid/uuid.dart';

enum CardSuit { hearts, diamonds, clubs, spades }

extension CardSuitEmoji on CardSuit {
  String get emoji {
    switch (this) {
      case CardSuit.hearts:
        return '♥️';
      case CardSuit.diamonds:
        return '♦️';
      case CardSuit.clubs:
        return '♣️';
      case CardSuit.spades:
        return '♠️';
    }
  }

  bool get isRed => this == CardSuit.hearts || this == CardSuit.diamonds;
}

enum PowerType { none, shield, mirror, multiplier }

extension PowerTypeEmoji on PowerType {
  String get emoji {
    switch (this) {
      case PowerType.none:
        return '';
      case PowerType.shield:
        return '🛡️';
      case PowerType.mirror:
        return '🪞';
      case PowerType.multiplier:
        return '⚡';
    }
  }

  String get name {
    switch (this) {
      case PowerType.none:
        return '';
      case PowerType.shield:
        return 'Bouclier';
      case PowerType.mirror:
        return 'Miroir';
      case PowerType.multiplier:
        return 'Multiplicateur (x2)';
    }
  }
}

class PyraCard {
  final String id;
  final CardSuit suit;
  final int value; // 1 = As, 11 = Valet, 12 = Dame, 13 = Roi
  final PowerType powerType;

  bool isFaceUp;
  bool isRevealed; // Retournée depuis la pyramide

  // Mini-Jeux
  final bool isMiniGame;
  final String? miniGameTitle;
  final String? miniGameDescription;

  PyraCard({
    String? id,
    this.suit = CardSuit.hearts,
    this.value = 1,
    this.powerType = PowerType.none,
    this.isFaceUp = false,
    this.isRevealed = false,
    this.isMiniGame = false,
    this.miniGameTitle,
    this.miniGameDescription,
  }) : id = id ?? const Uuid().v4();

  String get displayValue {
    if (powerType != PowerType.none) return powerType.emoji;
    switch (value) {
      case 1:
        return 'A';
      case 11:
        return 'V';
      case 12:
        return 'D';
      case 13:
        return 'R';
      default:
        return value.toString();
    }
  }

  String get fullName {
    if (powerType != PowerType.none) return powerType.name;
    return '$displayValue${suit.emoji}';
  }

  /// Génère un jeu de 52 cartes mélangé, incluant potentiellement des pouvoirs
  static List<PyraCard> generateDeck({bool withPowers = false}) {
    final deck = <PyraCard>[];
    for (final suit in CardSuit.values) {
      for (int v = 1; v <= 13; v++) {
        deck.add(PyraCard(suit: suit, value: v));
      }
    }

    if (withPowers) {
      // On remplace 6 cartes (par exemple les valets et dames rouges) par des pouvoirs
      for (int i = 0; i < deck.length; i++) {
        if (deck[i].value == 11 && deck[i].suit.isRed) {
          deck[i] = PyraCard(
              suit: deck[i].suit, value: 11, powerType: PowerType.shield);
        } else if (deck[i].value == 12 && deck[i].suit.isRed) {
          deck[i] = PyraCard(
              suit: deck[i].suit, value: 12, powerType: PowerType.mirror);
        } else if (deck[i].value == 13 && deck[i].suit.isRed) {
          deck[i] = PyraCard(
              suit: deck[i].suit, value: 13, powerType: PowerType.multiplier);
        }
      }
    }

    deck.shuffle();
    return deck;
  }

  PyraCard copyWith({bool? isFaceUp, bool? isRevealed}) {
    return PyraCard(
      id: id,
      suit: suit,
      value: value,
      powerType: powerType,
      isFaceUp: isFaceUp ?? this.isFaceUp,
      isRevealed: isRevealed ?? this.isRevealed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'suit': suit.index,
        'value': value,
        'powerType': powerType.index,
        'isFaceUp': isFaceUp,
        'isRevealed': isRevealed,
        'isMiniGame': isMiniGame,
        'miniGameTitle': miniGameTitle,
        'miniGameDescription': miniGameDescription,
      };

  factory PyraCard.fromJson(Map<String, dynamic> json) => PyraCard(
        id: json['id'],
        suit: CardSuit.values[json['suit']],
        value: json['value'],
        powerType: json['powerType'] != null
            ? PowerType.values[json['powerType']]
            : PowerType.none,
        isFaceUp: json['isFaceUp'] ?? false,
        isRevealed: json['isRevealed'] ?? false,
        isMiniGame: json['isMiniGame'] ?? false,
        miniGameTitle: json['miniGameTitle'],
        miniGameDescription: json['miniGameDescription'],
      );
}
