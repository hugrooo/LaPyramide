import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/home/home_screen.dart';
import '../features/lobby/local_lobby_screen.dart';
import '../features/lobby/online_lobby_screen.dart';
import '../features/game/local/local_game_screen.dart';
import '../features/game/online/online_game_screen.dart';
import '../features/game/scoreboard_screen.dart';
import '../features/rules/rules_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/auth/auth_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/profile_setup_screen.dart';
import '../features/leaderboard/leaderboard_screen.dart';
import '../features/main/main_layout.dart';
import '../features/store/store_screen.dart';
import '../features/friends/friends_screen.dart';
import '../features/shared/screens/coming_soon_screen.dart';
import '../features/profile/level_screen.dart';
import '../features/profile/public_profile_screen.dart';
import '../features/shared/screens/quests_screen.dart';
import '../features/minigames/minigames_hub_screen.dart';
import '../features/minigames/liar_game_screen.dart';
import '../features/custom_decks/custom_decks_screen.dart';
import '../features/stats/stats_screen.dart';
import '../features/tutorial/tutorial_screen.dart';
import '../features/seasons/battle_pass_screen.dart';
import '../features/crews/crews_screen.dart';
import '../features/game/online/spectator_screen.dart';

// ─── Transitions ────────────────────────────────────────────────────────────

/// Glissement depuis la droite (navigation vers l'avant)
CustomTransitionPage<T> _slideRight<T>(
    BuildContext context, GoRouterState state, Widget child) {
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

/// Fondu simple (fade) pour les onglets de navigation
CustomTransitionPage<T> _fadeTransition<T>(
    BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fadeTween = Tween<double>(begin: 0.0, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOut));
      return FadeTransition(
        opacity: animation.drive(fadeTween),
        child: child,
      );
    },
  );
}

/// Fondu + montée depuis le bas (pages modales/importantes)
CustomTransitionPage<T> _fadeSlideUp<T>(
    BuildContext context, GoRouterState state, Widget child) {
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
CustomTransitionPage<T> _zoomFade<T>(
    BuildContext context, GoRouterState state, Widget child) {
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

final rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final initialRouteProvider = Provider<String>((ref) => '/home');

final routerProvider = Provider<GoRouter>((ref) {
  final initialRoute = ref.watch(initialRouteProvider);
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialRoute,
    routes: [
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: OnboardingScreen()),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/profile-setup',
        name: 'profileSetup',
        pageBuilder: (context, state) =>
            _slideRight(context, state, const ProfileSetupScreen()),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          // Wrapper pour la barre de navigation
          return MainLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            pageBuilder: (context, state) =>
                _fadeTransition(context, state, const HomeScreen()),
          ),
          GoRoute(
            path: '/rules',
            name: 'rules',
            pageBuilder: (context, state) =>
                _fadeTransition(context, state, const RulesScreen()),
          ),
          GoRoute(
            path: '/leaderboard',
            name: 'leaderboard',
            pageBuilder: (context, state) =>
                _fadeTransition(context, state, const LeaderboardScreen()),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) =>
                _fadeTransition(context, state, const SettingsScreen()),
          ),
          GoRoute(
            path: '/store',
            name: 'store',
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final tabString = extra?['tab'] as String?;
              StoreTab? initialTab;
              if (tabString == 'coins') initialTab = StoreTab.coins;
              if (tabString == 'jokers') initialTab = StoreTab.jokers;
              if (tabString == 'cosmetics') initialTab = StoreTab.cosmetics;
              
              final scrollToBetaGifts = extra != null && extra['scrollToBetaGifts'] == true;
              final scrollToTitle = extra != null && extra['scrollToTitle'] == true;

              return _fadeTransition(
                context, 
                state, 
                StoreScreen(
                  initialTab: initialTab,
                  scrollToBetaGifts: scrollToBetaGifts,
                  scrollToTitle: scrollToTitle,
                )
              );
            },
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/auth',
        name: 'auth',
        pageBuilder: (context, state) =>
            _slideRight(context, state, const AuthScreen()),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/level',
        name: 'level',
        pageBuilder: (context, state) =>
            _slideRight(context, state, const LevelScreen()),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/public-profile/:uid',
        name: 'publicProfile',
        pageBuilder: (context, state) {
          final uid = state.pathParameters['uid']!;
          return _slideRight(context, state, PublicProfileScreen(uid: uid));
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/lobby/local',
        name: 'localLobby',
        pageBuilder: (context, state) =>
            _slideRight(context, state, const LocalLobbyScreen()),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/lobby/online',
        name: 'onlineLobby',
        pageBuilder: (context, state) =>
            _slideRight(context, state, const OnlineLobbyScreen()),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/game/local',
        name: 'localGame',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return _zoomFade(
              context,
              state,
              LocalGameScreen(
                  players: extra['players'], settings: extra['settings']));
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/game/online',
        name: 'onlineGame',
        pageBuilder: (context, state) =>
            _zoomFade(context, state, const OnlineGameScreen()),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/scoreboard',
        name: 'scoreboard',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return _zoomFade(
              context,
              state,
              ScoreboardScreen(
                players: extra['players'],
                isOnline: extra['isOnline'] ?? false,
                roomCode: extra['roomCode'],
                settings: extra['settings'],
              ));
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/coming-soon',
        name: 'comingSoon',
        pageBuilder: (context, state) {
          final title = state.extra as String? ?? 'Bientôt';
          return _slideRight(context, state, ComingSoonScreen(title: title));
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/friends',
        name: 'friends',
        pageBuilder: (context, state) =>
            _slideRight(context, state, const FriendsScreen()),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/quests',
        name: 'quests',
        pageBuilder: (context, state) =>
            _slideRight(context, state, const QuestsScreen()),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/minigames',
        name: 'minigames',
        pageBuilder: (context, state) =>
            _slideRight(context, state, const MinigamesHubScreen()),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/minigames/liar',
        name: 'minigameLiar',
        pageBuilder: (context, state) =>
            _slideRight(context, state, const LiarGameScreen()),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/custom-decks',
        name: 'customDecks',
        pageBuilder: (context, state) =>
            _slideRight(context, state, const CustomDecksScreen()),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/stats',
        name: 'stats',
        pageBuilder: (context, state) =>
            _slideRight(context, state, const StatsScreen()),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/tutorial',
        name: 'tutorial',
        pageBuilder: (context, state) =>
            _fadeSlideUp(context, state, const TutorialScreen()),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/battle-pass',
        name: 'battlePass',
        pageBuilder: (context, state) =>
            _slideRight(context, state, const BattlePassScreen()),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/crews',
        name: 'crews',
        pageBuilder: (context, state) =>
            _slideRight(context, state, const CrewsScreen()),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/game/spectate',
        name: 'spectate',
        pageBuilder: (context, state) {
          final roomCode = state.extra as String? ?? '';
          return _slideRight(
              context, state, SpectatorScreen(roomCode: roomCode));
        },
      ),
    ],
  );
});
