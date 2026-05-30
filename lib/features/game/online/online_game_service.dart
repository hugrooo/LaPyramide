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
import '../../profile/user_profile_provider.dart';

final onlineGameServiceProvider = Provider<OnlineGameService>((ref) {
  final auth = ref.watch(authServiceProvider);
  return OnlineGameService(FirebaseDatabase.instance, auth, ref);
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
  final Ref _ref;

  OnlineGameService(this._db, this._auth, this._ref);

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
    
    // Fetch profile safely from Firebase to guarantee we have the data
    UserProfile? userProfile;
    try {
      final profileSnap = await _db.ref('users/${user.uid}').get();
      if (profileSnap.exists && profileSnap.value != null) {
        userProfile = UserProfile.fromMap(profileSnap.value as Map<dynamic, dynamic>);
      }
    } catch (_) {}

    final activeCardBack = userProfile?.activeCardBack ?? 'classic';
    final activeTitle = userProfile?.activeTitle ?? '';
    final selectedBorder = userProfile?.selectedBorder ?? 'classic';
    final level = userProfile?.level ?? 1;
    final xp = userProfile?.xp ?? 0;

    final host = Player(
      id: user.uid,
      name: user.displayName ?? 'Joueur 1',
      emoji: avatar,
      photoUrl: user.photoURL,
      activeCardBack: activeCardBack,
      activeTitle: activeTitle,
      selectedBorder: selectedBorder,
      level: level,
      xp: xp,
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
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await roomRef.set(initialState.toJson());
    await roomRef.child('presence/${user.uid}').onDisconnect().set(false);
    
    // Lancement asynchrone en arrière-plan du nettoyage des vieux salons
    cleanupOldRooms();
    
    // Sauvegarder localement pour la reconnexion
    await prefs.setString('currentRoomCode', roomCode);
    
    return roomCode;
  }

  /// Rejoindre un salon existant
  Future<void> joinRoom(String roomCode) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    final code = roomCode.trim().toUpperCase();
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
      await roomRef.child('updatedAt').set(DateTime.now().millisecondsSinceEpoch);
      await roomRef.child('presence/${user.uid}').onDisconnect().set(false);
      
      // Lancement asynchrone en arrière-plan du nettoyage
      cleanupOldRooms();
      return; 
    }

    // Ajouter le joueur
    final prefs = await SharedPreferences.getInstance();
    final avatar = prefs.getString('userAvatar') ?? '😎';
    
    // Fetch profile safely from Firebase to guarantee we have the data
    UserProfile? userProfile;
    try {
      final profileSnap = await _db.ref('users/${user.uid}').get();
      if (profileSnap.exists && profileSnap.value != null) {
        userProfile = UserProfile.fromMap(profileSnap.value as Map<dynamic, dynamic>);
      }
    } catch (_) {}

    final activeCardBack = userProfile?.activeCardBack ?? 'classic';
    final activeTitle = userProfile?.activeTitle ?? '';
    final selectedBorder = userProfile?.selectedBorder ?? 'classic';
    final level = userProfile?.level ?? 1;
    final xp = userProfile?.xp ?? 0;

    final newPlayer = Player(
      id: user.uid,
      name: user.displayName ?? 'Nouveau Joueur',
      emoji: avatar,
      photoUrl: user.photoURL,
      activeCardBack: activeCardBack,
      activeTitle: activeTitle,
      selectedBorder: selectedBorder,
      level: level,
      xp: xp,
      isReady: false,
    );

    final updatedPlayers = List<Player>.from(state.players)..add(newPlayer);
    final updatedPresence = Map<String, bool>.from(state.presence)..[user.uid] = true;
    final updatedState = state.copyWith(
      players: updatedPlayers, 
      presence: updatedPresence,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await roomRef.set(updatedState.toJson());
    await roomRef.child('presence/${user.uid}').onDisconnect().set(false);

    // Lancement asynchrone en arrière-plan du nettoyage
    cleanupOldRooms();

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

    final stateWithTime = newState.copyWith(updatedAt: DateTime.now().millisecondsSinceEpoch);
    final DatabaseReference roomRef = _db.ref('games/${stateWithTime.gameId}');
    await roomRef.set(stateWithTime.toJson());
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

  /// Pénalité d'une pénalité pour avoir regardé une carte (Peeking)
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
      lastEventMessage: "📢 ${player.name} a regardé une de ses cartes et prend 1 pénalité !",
      lastEventTime: DateTime.now().millisecondsSinceEpoch,
    );
    
    await updateGameState(newState);
  }

  /// Pénalité de 2 pénalités (Fin de partie)
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
      lastEventMessage: "💥 ${player.name} s'est trompé(e) et prend 2 pénalités !",
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

  /// Assigner une pénalité
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

  /// Accepte les pénalités
  Future<void> acceptDrink(String roomCode) async {
    final state = await _fetchCurrentState(roomCode);
    if (state == null) return;
    final newState = GameLogic.acceptDrink(state);
    await updateGameState(newState);
  }

  /// Timeout en mode Speed-Run
  Future<void> speedRunTimeout(String roomCode) async {
    final state = await _fetchCurrentState(roomCode);
    if (state == null) return;
    
    // Ajoute un message de notification d'événement pour que tout le monde le voie
    final newState = GameLogic.speedRunTimeoutPenalty(state).copyWith(
      lastEventMessage: "⏱️ Trop lent ! 2 pénalités de pénalité !",
      lastEventTime: DateTime.now().millisecondsSinceEpoch,
    );
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

  /// Utiliser un joker
  Future<void> useJoker(String roomCode, String jokerId) async {
    final state = await _fetchCurrentState(roomCode);
    if (state == null) return;
    
    final newState = GameLogic.useJoker(
      state: state,
      playerId: _auth.currentUser!.uid,
      jokerId: jokerId,
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

  /// Distribuer les pénalités dans le Bus
  Future<void> distributeBusDrinks(String roomCode, String targetPlayerId) async {
    final state = await _fetchCurrentState(roomCode);
    if (state == null) return;
    
    final newState = DistributionLogic.distributeBusDrinks(state: state, targetPlayerId: targetPlayerId);
    await updateGameState(newState);
  }

  /// Écoute en temps réel de l'état du salon
  Stream<GameState> streamGameState(String roomCode) {
    return _db.ref('games/$roomCode').onValue
        .where((event) => event.snapshot.value != null) // Ignorer silencieusement si le salon est supprimé
        .map((event) {
      final data = jsonDecode(jsonEncode(event.snapshot.value)) as Map<String, dynamic>;
      return GameState.fromJson(data);
    });
  }


  /// Remet le salon en phase de préparation avec les mêmes joueurs (Rejouer)
  Future<void> restartRoom(String roomCode) async {
    final state = await _fetchCurrentState(roomCode);
    if (state == null) throw Exception('Salon introuvable');

    // Recrée un deck et une pyramide frais
    final settings = state.settings;
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

    // Réinitialise les joueurs (main vide, stats à zéro, mais on garde noms/emojis)
    final resetPlayers = state.players.map((p) => Player(
      id: p.id,
      name: p.name,
      emoji: p.emoji,
      photoUrl: p.photoUrl,
      activeCardBack: p.activeCardBack,
      activeTitle: p.activeTitle,
      selectedBorder: p.selectedBorder,
      level: p.level,
      xp: p.xp,
      isReady: p.id == state.players.first.id, // L'hôte est prêt par défaut
    )).toList();

    final newState = GameState(
      gameId: roomCode,
      pyramid: pyramid,
      players: resetPlayers,
      deck: deck.sublist(cardIndex),
      phase: GamePhase.setup,
      currentRow: settings.pyramidRows - 1,
      currentCardIndex: 0,
      pendingDrinks: [],
      settings: settings,
      presence: state.presence,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    final DatabaseReference roomRef = _db.ref('games/$roomCode');
    await roomRef.set(newState.toJson());
  }

  /// Nettoie les salons de jeu obsolètes (inactifs depuis plus de 2 heures)
  Future<void> cleanupOldRooms() async {
    try {
      final DatabaseReference gamesRef = _db.ref('games');
      final snapshot = await gamesRef.get();
      if (!snapshot.exists || snapshot.value == null) return;

      final now = DateTime.now().millisecondsSinceEpoch;
      final twoHoursAgo = now - (2 * 3600 * 1000); // 2 heures d'inactivité

      final gamesData = snapshot.value as Map<dynamic, dynamic>;
      
      for (final entry in gamesData.entries) {
        final roomCode = entry.key as String;
        final roomData = entry.value;
        
        if (roomData is Map) {
          final updatedAt = roomData['updatedAt'] as int?;
          
          if (updatedAt == null || updatedAt < twoHoursAgo) {
            // Salon obsolète ou sans date, suppression de la base
            await gamesRef.child(roomCode).remove();
            print("Cleanup Firebase: suppression du salon $roomCode obsolète/inactif.");
          }
        }
      }
    } catch (e) {
      print("Erreur lors du nettoyage passif des salons Firebase: $e");
    }
  }
}
