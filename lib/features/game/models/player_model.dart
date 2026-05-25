import 'package:uuid/uuid.dart';
import 'card_model.dart';

const List<String> kDefaultEmojis = [
  '🎉', '🔥', '😎', '🍺', '👑', '🎲', '💀', '🤪',
];

class Player {
  final String id;
  String name;
  String emoji;
  String? photoUrl; // Nouveau champ pour la photo de profil
  List<PyraCard> hand;

  // Statistiques de la partie
  int totalSips;
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

  Player({
    String? id,
    required this.name,
    String? emoji,
    this.photoUrl,
    List<PyraCard>? hand,
    this.totalSips = 0,
    this.bluffsWon = 0,
    this.bluffsLost = 0,
    this.challengesWon = 0,
    this.challengesLost = 0,
    this.isReady = false,
    this.isConnected = true,
    this.secretMission,
    this.missionCompleted = false,
    this.hasUsedPigeon = false,
  })  : id = id ?? const Uuid().v4(),
        emoji = emoji ?? kDefaultEmojis[0],
        hand = hand ?? [];

  int get score => bluffsWon + challengesWon - bluffsLost - challengesLost;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'photoUrl': photoUrl,
    'hand': hand.map((c) => c.toJson()).toList(),
    'totalSips': totalSips,
    'bluffsWon': bluffsWon,
    'bluffsLost': bluffsLost,
    'challengesWon': challengesWon,
    'challengesLost': challengesLost,
    'isReady': isReady,
    'isConnected': isConnected,
    'secretMission': secretMission,
    'missionCompleted': missionCompleted,
    'hasUsedPigeon': hasUsedPigeon,
  };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
    id: json['id'],
    name: json['name'],
    emoji: json['emoji'],
    photoUrl: json['photoUrl'],
    hand: json['hand'] != null 
        ? (json['hand'] as List).map((c) => PyraCard.fromJson(c)).toList()
        : [],
    totalSips: json['totalSips'],
    bluffsWon: json['bluffsWon'],
    bluffsLost: json['bluffsLost'],
    challengesWon: json['challengesWon'],
    challengesLost: json['challengesLost'] ?? 0,
    isReady: json['isReady'] ?? false,
    isConnected: json['isConnected'] ?? true,
    secretMission: json['secretMission'],
    missionCompleted: json['missionCompleted'] ?? false,
    hasUsedPigeon: json['hasUsedPigeon'] ?? false,
  );

  Player copyWith({
    String? id,
    String? name,
    String? emoji,
    String? photoUrl,
    List<PyraCard>? hand,
    int? totalSips,
    int? bluffsWon,
    int? bluffsLost,
    int? challengesWon,
    int? challengesLost,
    bool? isReady,
    bool? isConnected,
    String? secretMission,
    bool? missionCompleted,
    bool? hasUsedPigeon,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      photoUrl: photoUrl ?? this.photoUrl,
      hand: hand ?? this.hand,
      totalSips: totalSips ?? this.totalSips,
      bluffsWon: bluffsWon ?? this.bluffsWon,
      bluffsLost: bluffsLost ?? this.bluffsLost,
      challengesWon: challengesWon ?? this.challengesWon,
      challengesLost: challengesLost ?? this.challengesLost,
      isReady: isReady ?? this.isReady,
      isConnected: isConnected ?? this.isConnected,
      secretMission: secretMission ?? this.secretMission,
      missionCompleted: missionCompleted ?? this.missionCompleted,
      hasUsedPigeon: hasUsedPigeon ?? this.hasUsedPigeon,
    );
  }
}
