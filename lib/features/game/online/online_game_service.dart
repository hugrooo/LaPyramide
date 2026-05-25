import 'dart:convert';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/card_model.dart';
import '../models/game_state.dart';
import '../models/player_model.dart';
import '../game_logic.dart';
import '../distribution_logic.dart';
import '../../auth/auth_service.dart';
import '../../leaderboard/leaderboard_service.dart';

final onlineGameServiceProvider = Provider<OnlineGameService>((ref) {
  final auth = ref.watch(authServiceProvider);
  return OnlineGameService(FirebaseDatabase.instance, auth);
});

// État local du code de salon actuel
final currentRoomCodeProvider = StateProvider<String?>((ref) => null);

// Flux de l'état du jeu depuis Firebase
final onlineGameStateProvider = StreamProvider.autoDispose<GameState?>((ref) {
  final roomCode = ref.watch(currentRoomCodeProvider);
  final service = ref.watch(onlineGameServiceProvider);

  if (roomCode == null) return const Stream.empty();

  return service.streamGameState(roomCode);
});

class OnlineGameService {
  final FirebaseDatabase _db;
  final AuthService _auth;

  OnlineGameService(this._db, this._auth);

  /// Génère un code à 4 lettres majuscules / chiffres
  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(
      4, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  /// Crée un nouveau salon en ligne
  Future<String> createRoom(GameSettings settings) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    final String roomCode = _generateRoomCode();
    final DatabaseReference roomRef = _db.ref('games/$roomCode');

    // Vérifie si le code existe déjà (rare mais possible)
    final snapshot = await roomRef.get();
    if (snapshot.exists) {
      return createRoom(settings); // Retry
    }

    // Créer le joueur hôte
    final prefs = await SharedPreferences.getInstance();
    final avatar = prefs.getString('userAvatar') ?? '😎';

    final host = Player(
      id: user.uid,
      name: user.displayName ?? 'Joueur 1',
      emoji: avatar,
      photoUrl: user.photoURL,
      isReady: true, // L'hôte est prêt par défaut
    );

    // Initialisation de la partie
    final deck = PyraCard.generateDeck();
    final List<List<PyraCard>> pyramid = [];
    int cardIndex = 0;

    for (int r = 0; r < settings.pyramidRows; r++) {
      final row = <PyraCard>[];
      for (int c = 0; c <= r; c++) {
        if (cardIndex < deck.length) {
          row.add(deck[cardIndex++]);
        }
      }
      pyramid.add(row);
    }

    final initialState = GameState(
      gameId: roomCode,
      pyramid: pyramid,
      players: [host],
      deck: deck.sublist(cardIndex),
      phase: GamePhase.setup,
      currentRow: settings.pyramidRows - 1,
      currentCardIndex: 0,
      pendingDrinks: [],
      settings: settings,
      presence: {user.uid: true},
    );

    await roomRef.set(initialState.toJson());
    await roomRef.child('presence/${user.uid}').onDisconnect().set(false);
    
    // Sauvegarder localement pour la reconnexion
    await prefs.setString('currentRoomCode', roomCode);
    
    return roomCode;
  }

  /// Rejoindre un salon existant
  Future<void> joinRoom(String roomCode) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    final code = roomCode.toUpperCase();
    final DatabaseReference roomRef = _db.ref('games/$code');
    final snapshot = await roomRef.get();

    if (!snapshot.exists) {
      throw Exception('Salon introuvable');
    }

    // Lire l'état actuel
    final data = jsonDecode(jsonEncode(snapshot.value)) as Map<String, dynamic>;
    final state = GameState.fromJson(data);

    if (state.phase != GamePhase.setup) {
      throw Exception('La partie a déjà commencé');
    }

    // Vérifier si le joueur est déjà dans le salon (Reconnexion)
    if (state.players.any((p) => p.id == user.uid)) {
      final updatedPresence = Map<String, bool>.from(state.presence)..[user.uid] = true;
      await roomRef.child('presence').set(updatedPresence);
      await roomRef.child('presence/${user.uid}').onDisconnect().set(false);
      return; 
    }

    // Ajouter le joueur
    final prefs = await SharedPreferences.getInstance();
    final avatar = prefs.getString('userAvatar') ?? '😎';

    final newPlayer = Player(
      id: user.uid,
      name: user.displayName ?? 'Nouveau Joueur',
      emoji: avatar,
      photoUrl: user.photoURL,
      isReady: false,
    );

    final updatedPlayers = List<Player>.from(state.players)..add(newPlayer);
    final updatedPresence = Map<String, bool>.from(state.presence)..[user.uid] = true;
    final updatedState = state.copyWith(players: updatedPlayers, presence: updatedPresence);

    await roomRef.set(updatedState.toJson());
    await roomRef.child('presence/${user.uid}').onDisconnect().set(false);

    // Sauvegarder localement
    await prefs.setString('currentRoomCode', code);
  }

  /// Met à jour l'état global (utilisé lors d'une action comme retourner une carte)
  Future<void> updateGameState(GameState newState) async {
    // Sauvegarder les stats de fin de partie
    if (newState.phase == GamePhase.finished) {
      final oldState = await _fetchCurrentState(newState.gameId);
      if (oldState != null && oldState.phase != GamePhase.finished) {
        final leaderboardService = LeaderboardService();
        for (final player in newState.players) {
          try {
            await leaderboardService.savePlayerStats(player.id, player.name, player.totalSips, player.bluffsWon);
          } catch (e) {
            print("Erreur leaderboard: $e");
          }
        }
      }
    }

    final DatabaseReference roomRef = _db.ref('games/${newState.gameId}');
    await roomRef.set(newState.toJson());
  }

  /// Quitter le salon
  Future<void> leaveRoom(String roomCode) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final DatabaseReference roomRef = _db.ref('games/$roomCode');
    final snapshot = await roomRef.get();

    if (!snapshot.exists) return;

    final data = jsonDecode(jsonEncode(snapshot.value)) as Map<String, dynamic>;
    final state = GameState.fromJson(data);

    final updatedPlayers = state.players.where((p) => p.id != user.uid).toList();

    if (updatedPlayers.isEmpty) {
      // Supprimer le salon si vide
      await roomRef.remove();
    } else {
      final updatedPresence = Map<String, bool>.from(state.presence)..remove(user.uid);
      final updatedState = state.copyWith(players: updatedPlayers, presence: updatedPresence);
      await roomRef.set(updatedState.toJson());
      await roomRef.child('presence/${user.uid}').onDisconnect().cancel();
    }

    // Effacer localement
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentRoomCode');
  }

  /// Envoyer un Taunt (Provocation)
  Future<void> sendTaunt(String roomCode, String senderId, String emoji) async {
    final code = roomCode.toUpperCase();
    final DatabaseReference roomRef = _db.ref('games/$code');
    final taunt = {
      'senderId': senderId,
      'emoji': emoji,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await roomRef.child('lastTaunt').set(taunt);
  }

  /// Récupère l'état courant de manière asynchrone (helper)
  Future<GameState?> _fetchCurrentState(String roomCode) async {
    final snapshot = await _db.ref('games/$roomCode').get();
    if (!snapshot.exists || snapshot.value == null) return null;
    final data = jsonDecode(jsonEncode(snapshot.value)) as Map<String, dynamic>;
    return GameState.fromJson(data);
  }

  /// Pénalité d'une gorgée pour avoir regardé une carte (Peeking)
  Future<void> peekCard(String roomCode, String playerId) async {
    final state = await _fetchCurrentState(roomCode);
    if (state == null) return;
    
    final player = state.players.firstWhere((p) => p.id == playerId);
    final updatedPlayers = state.players.map((p) {
      if (p.id == playerId) return p.copyWith(totalSips: p.totalSips + 1);
      return p;
    }).toList();

    final newState = state.copyWith(
      players: updatedPlayers,
      lastEventMessage: "📢 ${player.name} a regardé une de ses cartes et prend 1 gorgée !",
      lastEventTime: DateTime.now().millisecondsSinceEpoch,
    );
    
    await updateGameState(newState);
  }

  /// Pénalité de 2 gorgées (Fin de partie)
  Future<void> addPenalty(String roomCode, String playerId) async {
    final state = await _fetchCurrentState(roomCode);
    if (state == null) return;
    
    final player = state.players.firstWhere((p) => p.id == playerId);
    final updatedPlayers = state.players.map((p) {
      if (p.id == playerId) return p.copyWith(totalSips: p.totalSips + 2);
      return p;
    }).toList();

    final newState = state.copyWith(
      players: updatedPlayers,
      lastEventMessage: "💥 ${player.name} s'est trompé(e) et prend 2 gorgées !",
      lastEventTime: DateTime.now().millisecondsSinceEpoch,
    );
    
    await updateGameState(newState);
  }

  /// Fin de tour (Fin de partie)
  Future<void> nextEndGamePlayer(String roomCode) async {
    final state = await _fetchCurrentState(roomCode);
    if (state == null) return;
    
    final newState = state.copyWith(endGamePlayerIndex: state.endGamePlayerIndex + 1);
    await updateGameState(newState);
  }

  /// Assigner une gorgée
  Future<void> assignDrink(String roomCode, String targetId, {bool isPigeon = false}) async {
    final state = await _fetchCurrentState(roomCode);
    if (state == null) return;
    
    final newState = GameLogic.assignDrink(
      state: state,
      fromPlayerId: _auth.currentUser!.uid,
      toPlayerId: targetId,
      isPigeon: isPigeon,
    );
    await updateGameState(newState);
  }

  /// Accepte les gorgées
  Future<void> acceptDrink(String roomCode) async {
    final state = await _fetchCurrentState(roomCode);
    if (state == null) return;
    final newState = GameLogic.acceptDrink(state);
    await updateGameState(newState);
  }

  /// Utiliser un pouvoir
  Future<void> usePower(String roomCode, String cardId) async {
    final state = await _fetchCurrentState(roomCode);
    if (state == null) return;
    
    final newState = GameLogic.usePower(
      state: state,
      playerId: _auth.currentUser!.uid,
      cardId: cardId,
    );
    await updateGameState(newState);
  }

  /// La cible crie au bluff
  Future<void> callBluff(String roomCode) async {
    final state = await _fetchCurrentState(roomCode);
    if (state == null) return;
    
    final newState = GameLogic.callBluff(state);
    await updateGameState(newState);
  }

  /// Le joueur accusé révèle une carte (ou avoue en passant null)
  Future<void> resolveBluff(String roomCode, String? cardId) async {
    final state = await _fetchCurrentState(roomCode);
    if (state == null) return;
    
    final newState = GameLogic.resolveBluff(
      state: state,
      fromPlayerId: _auth.currentUser!.uid,
      cardId: cardId,
    );
    await updateGameState(newState);
  }

  /// Distribuer les gorgées dans le Bus
  Future<void> distributeBusDrinks(String roomCode, String targetPlayerId) async {
    final state = await _fetchCurrentState(roomCode);
    if (state == null) return;
    
    final newState = DistributionLogic.distributeBusDrinks(state: state, targetPlayerId: targetPlayerId);
    await updateGameState(newState);
  }

  /// Écoute en temps réel de l'état du salon
  Stream<GameState> streamGameState(String roomCode) {
    return _db.ref('games/$roomCode').onValue.map((event) {
      if (event.snapshot.value == null) {
        throw Exception('Le salon a été fermé');
      }
      final data = jsonDecode(jsonEncode(event.snapshot.value)) as Map<String, dynamic>;
      return GameState.fromJson(data);
    });
  }
}
