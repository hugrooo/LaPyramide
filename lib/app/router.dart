import 'package:flutter/material.dart';
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

// ─── Transitions ────────────────────────────────────────────────────────────

/// Glissement depuis la droite (navigation vers l'avant)
CustomTransitionPage<T> _slideRight<T>(BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic));
      final fadeOut = Tween<double>(begin: 1.0, end: 0.7)
          .chain(CurveTween(curve: Curves.easeOut));
      return SlideTransition(
        position: animation.drive(tween),
        child: FadeTransition(
          opacity: secondaryAnimation.drive(fadeOut),
          child: child,
        ),
      );
    },
  );
}

/// Fondu + montée depuis le bas (pages modales/importantes)
CustomTransitionPage<T> _fadeSlideUp<T>(BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 450),
    reverseTransitionDuration: const Duration(milliseconds: 350),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slideTween = Tween(begin: const Offset(0.0, 0.06), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic));
      final fadeTween = Tween<double>(begin: 0.0, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOut));
      return FadeTransition(
        opacity: animation.drive(fadeTween),
        child: SlideTransition(
          position: animation.drive(slideTween),
          child: child,
        ),
      );
    },
  );
}

/// Zoom fondu (pour les transitions de jeu dramatiques)
CustomTransitionPage<T> _zoomFade<T>(BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 500),
    reverseTransitionDuration: const Duration(milliseconds: 400),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final scaleTween = Tween<double>(begin: 0.92, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOutCubic));
      final fadeTween = Tween<double>(begin: 0.0, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOut));
      return FadeTransition(
        opacity: animation.drive(fadeTween),
        child: ScaleTransition(
          scale: animation.drive(scaleTween),
          child: child,
        ),
      );
    },
  );
}

// ─── Router ─────────────────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/disclaimer',
    routes: [
      GoRoute(
        path: '/disclaimer',
        name: 'disclaimer',
        pageBuilder: (context, state) => _fadeSlideUp(context, state, const DisclaimerScreen()),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder: (context, state) => _fadeSlideUp(context, state, const HomeScreen()),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        pageBuilder: (context, state) => _slideRight(context, state, const AuthScreen()),
      ),
      GoRoute(
        path: '/lobby/local',
        name: 'localLobby',
        pageBuilder: (context, state) => _slideRight(context, state, const LocalLobbyScreen()),
      ),
      GoRoute(
        path: '/lobby/online',
        name: 'onlineLobby',
        pageBuilder: (context, state) => _slideRight(context, state, const OnlineLobbyScreen()),
      ),
      GoRoute(
        path: '/game/local',
        name: 'localGame',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return _zoomFade(context, state, LocalGameScreen(players: extra['players'], settings: extra['settings']));
        },
      ),
      GoRoute(
        path: '/game/online',
        name: 'onlineGame',
        pageBuilder: (context, state) => _zoomFade(context, state, const OnlineGameScreen()),
      ),
      GoRoute(
        path: '/scoreboard',
        name: 'scoreboard',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return _zoomFade(context, state, ScoreboardScreen(players: extra['players']));
        },
      ),
      GoRoute(
        path: '/rules',
        name: 'rules',
        pageBuilder: (context, state) => _slideRight(context, state, const RulesScreen()),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => _slideRight(context, state, const SettingsScreen()),
      ),
      GoRoute(
        path: '/leaderboard',
        name: 'leaderboard',
        pageBuilder: (context, state) => _slideRight(context, state, const LeaderboardScreen()),
      ),
    ],
  );
});
