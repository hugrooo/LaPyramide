import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/splash/disclaimer_screen.dart';
import '../features/home/home_screen.dart';
import '../features/lobby/local_lobby_screen.dart';
import '../features/lobby/online_lobby_screen.dart';
import '../features/game/local/local_game_screen.dart';
import '../features/game/online/online_game_screen.dart';
import '../features/game/scoreboard_screen.dart';
import '../features/rules/rules_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/auth/auth_screen.dart';
import '../features/leaderboard/leaderboard_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/disclaimer',
    routes: [
      GoRoute(
        path: '/disclaimer',
        name: 'disclaimer',
        builder: (context, state) => const DisclaimerScreen(),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/lobby/local',
        name: 'localLobby',
        builder: (context, state) => const LocalLobbyScreen(),
      ),
      GoRoute(
        path: '/lobby/online',
        name: 'onlineLobby',
        builder: (context, state) => const OnlineLobbyScreen(),
      ),
      GoRoute(
        path: '/game/local',
        name: 'localGame',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return LocalGameScreen(players: extra['players'], settings: extra['settings']);
        },
      ),
      GoRoute(
        path: '/game/online',
        name: 'onlineGame',
        builder: (context, state) => const OnlineGameScreen(),
      ),
      GoRoute(
        path: '/scoreboard',
        name: 'scoreboard',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ScoreboardScreen(players: extra['players']);
        },
      ),
      GoRoute(
        path: '/rules',
        name: 'rules',
        builder: (context, state) => const RulesScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/leaderboard',
        name: 'leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),
    ],
  );
});
