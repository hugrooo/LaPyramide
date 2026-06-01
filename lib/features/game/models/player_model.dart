import 'package:uuid/uuid.dart';
import 'card_model.dart';

const List<String> kDefaultEmojis = [
  '🎉',
  '🔥',
  '😎',
  '🍺',
  '👑',
  '🎲',
  '💀',
  '🤪',
];

class Player {
  final String id;
  String name;
  String emoji;
  String? photoUrl; // Nouveau champ pour la photo de profil
  String activeCardBack;
  String activeTitle;
  String selectedBorder;
  int level;
  int xp;
  List<PyraCard> hand;

  // Statistiques de la partie
  int totalSips;
  int drinksGiven;
  int bluffsWon;
  int bluffsLost;
  int challengesWon;
  int challengesLost;

  // État en ligne
  bool isReady;
  bool isConnected;

  // Mode Spécial
  String? secretMission;
  bool missionCompleted;

  // Mécanique Tir au Pigeon
  bool hasUsedPigeon;

  // Mécanique Passage de Tour
  bool hasPassedThisTurn;

  Player({
    String? id,
    required this.name,
    String? emoji,
    this.photoUrl,
    this.activeCardBack = 'classic',
    this.activeTitle = '',
    this.selectedBorder = 'classic',
    this.level = 1,
    this.xp = 0,
    List<PyraCard>? hand,
    this.totalSips = 0,
    this.drinksGiven = 0,
    this.bluffsWon = 0,
    this.bluffsLost = 0,
    this.challengesWon = 0,
    this.challengesLost = 0,
    this.isReady = false,
    this.isConnected = true,
    this.secretMission,
    this.missionCompleted = false,
    this.hasUsedPigeon = false,
    this.hasPassedThisTurn = false,
  })  : id = id ?? const Uuid().v4(),
        emoji = emoji ?? kDefaultEmojis[0],
        hand = hand ?? [];

  int get score => bluffsWon + challengesWon - bluffsLost - challengesLost;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'photoUrl': photoUrl,
        'activeCardBack': activeCardBack,
        'activeTitle': activeTitle,
        'selectedBorder': selectedBorder,
        'level': level,
        'xp': xp,
        'hand': hand.map((c) => c.toJson()).toList(),
        'totalSips': totalSips,
        'drinksGiven': drinksGiven,
        'bluffsWon': bluffsWon,
        'bluffsLost': bluffsLost,
        'challengesWon': challengesWon,
        'challengesLost': challengesLost,
        'isReady': isReady,
        'isConnected': isConnected,
        'secretMission': secretMission,
        'missionCompleted': missionCompleted,
        'hasUsedPigeon': hasUsedPigeon,
        'hasPassedThisTurn': hasPassedThisTurn,
      };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'],
        name: json['name'],
        emoji: json['emoji'],
        photoUrl: json['photoUrl'],
        activeCardBack: json['activeCardBack'] ?? 'classic',
        activeTitle: json['activeTitle'] ?? '',
        selectedBorder: json['selectedBorder'] ?? 'classic',
        level: json['level'] ?? 1,
        xp: json['xp'] ?? 0,
        hand: json['hand'] != null
            ? (json['hand'] as List).map((c) => PyraCard.fromJson(c)).toList()
            : [],
        totalSips: json['totalSips'],
        drinksGiven: json['drinksGiven'] ?? 0,
        bluffsWon: json['bluffsWon'],
        bluffsLost: json['bluffsLost'],
        challengesWon: json['challengesWon'],
        challengesLost: json['challengesLost'] ?? 0,
        isReady: json['isReady'] ?? false,
        isConnected: json['isConnected'] ?? true,
        secretMission: json['secretMission'],
        missionCompleted: json['missionCompleted'] ?? false,
        hasUsedPigeon: json['hasUsedPigeon'] ?? false,
        hasPassedThisTurn: json['hasPassedThisTurn'] ?? false,
      );

  Player copyWith({
    String? id,
    String? name,
    String? emoji,
    String? photoUrl,
    String? activeCardBack,
    String? activeTitle,
    String? selectedBorder,
    int? level,
    int? xp,
    List<PyraCard>? hand,
    int? totalSips,
    int? drinksGiven,
    int? bluffsWon,
    int? bluffsLost,
    int? challengesWon,
    int? challengesLost,
    bool? isReady,
    bool? isConnected,
    String? secretMission,
    bool? missionCompleted,
    bool? hasUsedPigeon,
    bool? hasPassedThisTurn,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      photoUrl: photoUrl ?? this.photoUrl,
      activeCardBack: activeCardBack ?? this.activeCardBack,
      activeTitle: activeTitle ?? this.activeTitle,
      selectedBorder: selectedBorder ?? this.selectedBorder,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      hand: hand ?? this.hand,
      totalSips: totalSips ?? this.totalSips,
      drinksGiven: drinksGiven ?? this.drinksGiven,
      bluffsWon: bluffsWon ?? this.bluffsWon,
      bluffsLost: bluffsLost ?? this.bluffsLost,
      challengesWon: challengesWon ?? this.challengesWon,
      challengesLost: challengesLost ?? this.challengesLost,
      isReady: isReady ?? this.isReady,
      isConnected: isConnected ?? this.isConnected,
      secretMission: secretMission ?? this.secretMission,
      missionCompleted: missionCompleted ?? this.missionCompleted,
      hasUsedPigeon: hasUsedPigeon ?? this.hasUsedPigeon,
      hasPassedThisTurn: hasPassedThisTurn ?? this.hasPassedThisTurn,
    );
  }
}
