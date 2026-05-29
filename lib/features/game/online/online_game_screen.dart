import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/audio/audio_manager.dart';
import '../../../shared/widgets/animated_background.dart';
import '../../auth/auth_service.dart';
import '../../../shared/widgets/card_3d_showcase.dart';
import '../../../shared/widgets/avatar_with_border.dart';
import 'dart:math';
import '../game_logic.dart';
import '../models/card_model.dart';
import '../models/game_state.dart';
import '../models/player_model.dart';
import '../online/online_game_service.dart';
import '../services/random_event_service.dart';
import '../widgets/drink_and_bluff_widgets.dart';
import '../widgets/player_hand_widget.dart';
import '../widgets/pyramid_widget.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/pulsar_button.dart';
import '../widgets/distribution_screen.dart';
import '../widgets/end_game_screen.dart';
import '../../profile/user_profile_provider.dart';
import '../widgets/sip_scoreboard_widget.dart';
import '../widgets/totem_card_animation.dart';

class OnlineGameScreen extends ConsumerWidget {
  const OnlineGameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<GameState?>>(onlineGameStateProvider, (previous, next) {
      final oldState = previous?.value;
      final newState = next.value;

      if (newState != null) {
        // --- GESTION FIN DE PARTIE & RECOMPENSES ---
        if (newState.phase == GamePhase.finished && (oldState == null || oldState.phase != GamePhase.finished)) {
          final user = ref.read(authServiceProvider).currentUser;
          if (user != null) {
            final me = newState.players.firstWhere((p) => p.id == user.uid, orElse: () => newState.players.first);
            final int xpBase = 50;
            final int xpDrinks = me.drinksGiven * 5;
            final int xpBluffs = me.bluffsWon * 15;
            final int totalXp = xpBase + xpDrinks + xpBluffs;
            
            // Appliquer dans Firebase
            UserProfile.addGameRewards(user.uid, totalXp, me.drinksGiven, me.bluffsWon);

            // Pop-up Résumé
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: GlassContainer(
                  innerGlow: true,
                  padding: const EdgeInsets.all(24),
                  border: Border.all(color: PyraTheme.primaryYellow, width: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🏆 PARTIE TERMINÉE !', style: TextStyle(color: PyraTheme.primaryYellow, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Text('+ $totalXp XP', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              const Icon(Icons.water_drop, color: PyraTheme.primaryCyan),
                              Text('${me.drinksGiven} Gorgées', style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                          Column(
                            children: [
                              const Icon(Icons.local_fire_department, color: PyraTheme.primaryOrange),
                              Text('${me.bluffsWon} Bluffs', style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: PyraTheme.primaryPink),
                        onPressed: () {
                          Navigator.pop(ctx);
                        },
                        child: const Text('Génial !', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
            );
          }
        }

        if (newState.lastEventTime != null && (oldState == null || oldState.lastEventTime != newState.lastEventTime)) {
          if (newState.lastBluffResult != BluffResult.none && newState.lastPlayerRevealedCard != null) {
            // Afficher le résultat du bluff en grand avec l'animation Totem
            // (on utilise lastPlayerRevealedCard = la carte réelle choisie par le joueur, pas la carte de la pyramide)
            final isTruth = newState.lastBluffResult == BluffResult.success;
            
            // Récupérer le skin du joueur qui a posé la carte (celui qui a initié le bluff)
            String? revealerSkin;
            if (newState.lastBlufferId != null) {
              try {
                final revealer = newState.players.firstWhere((p) => p.id == newState.lastBlufferId);
                revealerSkin = revealer.activeCardBack;
              } catch (_) {}
            }
            
            showTotemAnimation(context, newState.lastPlayerRevealedCard!, isTruth, overrideSkin: revealerSkin);
          } else if (newState.lastEventMessage != null) {
            if (newState.lastEventMessage!.startsWith('📢') || newState.lastEventMessage!.startsWith('💥')) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) {
                  Future.delayed(const Duration(seconds: 3), () {
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  });
                  return Dialog(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    child: GlassContainer(
                      innerGlow: true,
                      padding: const EdgeInsets.all(24),
                      border: Border.all(color: Colors.redAccent, width: 2),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 64)
                              .animate().shake(duration: 500.ms),
                          const SizedBox(height: 16),
                          Text(
                            newState.lastEventMessage!,
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack);
                },
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(newState.lastEventMessage!),
                  backgroundColor: PyraTheme.primaryPink,
                  duration: const Duration(seconds: 3),
                ),
              );
              }
            }
          }
        }
    });

    final gameStateAsync = ref.watch(onlineGameStateProvider);
    final user = ref.watch(authServiceProvider).currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Erreur: Non connecté')));
    }

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: gameStateAsync.when(
              data: (state) {
                if (state == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Le salon a été fermé.', style: TextStyle(color: Colors.white, fontSize: 18)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => context.goNamed('home'),
                          child: const Text('Retour à l\'accueil'),
                        ),
                      ],
                    ),
                  );
                }
                return SizedBox.expand(child: _buildGameUI(context, ref, state, user.uid));
              },
              loading: () => const Center(child: CircularProgressIndicator(color: PyraTheme.primaryPink)),
              error: (err, _) => Center(child: Text('Erreur: $err', style: const TextStyle(color: Colors.red))),
            ),
          ),
          // Bouton quitter
          Positioned(
            top: 48,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white54),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: PyraTheme.bgCard,
                    title: const Text('Quitter ?', style: TextStyle(color: Colors.white)),
                    content: const Text('Tu quitteras le salon pour de bon.', style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Annuler', style: TextStyle(color: PyraTheme.textMuted)),
                      ),
                      TextButton(
                        onPressed: () {
                          final roomCode = ref.read(currentRoomCodeProvider);
                          if (roomCode != null) {
                            ref.read(onlineGameServiceProvider).leaveRoom(roomCode);
                          }
                          Navigator.pop(ctx);
                          context.goNamed('home');
                        },
                        child: const Text('Quitter', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Bouton Taunt
          if (gameStateAsync.value != null && gameStateAsync.value!.phase != GamePhase.setup)
            Positioned(
              bottom: 24,
              right: 24,
              child: FloatingActionButton(
                heroTag: 'taunt_btn',
                backgroundColor: PyraTheme.primaryPink,
                onPressed: () => _showTauntDialog(context, ref, gameStateAsync.value!.gameId, user.uid),
                child: const Icon(Icons.emoji_emotions, color: Colors.white),
              ),
            ),
          // Boutons Top Right (Scores & Mission)
          if (gameStateAsync.value != null && gameStateAsync.value!.phase != GamePhase.setup)
            Positioned(
              top: 48,
              right: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ActionChip(
                    backgroundColor: PyraTheme.bgSurface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    avatar: const Icon(Icons.leaderboard, color: PyraTheme.primaryYellow),
                    label: const Text('Scores', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      showScoreboard(context, gameStateAsync.value!.players);
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildSecretMissionBtn(context, gameStateAsync.value!.players.firstWhere((p) => p.id == user.uid, orElse: () => gameStateAsync.value!.players.first).secretMission),
                ],
              ),
            ),
          // Overlay Taunt
          if (gameStateAsync.value?.lastTaunt != null)
            TauntOverlay(tauntData: gameStateAsync.value!.lastTaunt!),

          // Overlay Random Event
          if (gameStateAsync.value != null && 
              gameStateAsync.value!.currentRandomEvent != null && 
              gameStateAsync.value!.currentRandomEvent!.isNotEmpty)
            RandomEventOverlay(
              eventMap: gameStateAsync.value!.currentRandomEvent!,
              isHost: gameStateAsync.value!.players.isNotEmpty && gameStateAsync.value!.players.first.id == user.uid,
              onClose: () {
                final hostId = gameStateAsync.value!.players.isNotEmpty ? gameStateAsync.value!.players.first.id : '';
                if (hostId == user.uid) {
                   ref.read(onlineGameServiceProvider).updateGameState(
                     gameStateAsync.value!.copyWith(currentRandomEvent: {})
                   );
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSecretMissionBtn(BuildContext context, String? mission) {
    if (mission == null) return const SizedBox.shrink();
    return ActionChip(
      backgroundColor: PyraTheme.bgSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      avatar: const Icon(Icons.security, color: PyraTheme.primaryOrange),
      label: const Text('Mission', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      onPressed: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: PyraTheme.bgDark,
            title: const Text('🕵️ Ta Mission Secrète', style: TextStyle(color: Colors.white)),
            content: Text(mission, style: const TextStyle(color: Colors.white70, fontSize: 16)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Fermer', style: TextStyle(color: PyraTheme.primaryOrange)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTauntDialog(BuildContext context, WidgetRef ref, String roomId, String userId) {
    final taunts = ['🍻', '🍅', '💩', '🤡', '💤', '🤣'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GlassContainer(
        innerGlow: true,
        padding: const EdgeInsets.all(24.0),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Envoyer une provocation !', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 24),
            Wrap(
              spacing: 24,
              runSpacing: 24,
              children: taunts.map((emoji) => GestureDetector(
                onTap: () {
                  ref.read(onlineGameServiceProvider).sendTaunt(roomId, userId, emoji);
                  Navigator.pop(ctx);
                },
                child: Text(emoji, style: const TextStyle(fontSize: 48)),
              )).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGameUI(BuildContext context, WidgetRef ref, GameState state, String currentUserId) {
    if (state.phase == GamePhase.distribution) {
      return DistributionScreen(state: state, currentUserId: currentUserId);
    }
    if (state.phase == GamePhase.finished) {
      return EndGameScreen(state: state, currentUserId: currentUserId);
    }

    final service = ref.read(onlineGameServiceProvider);
    
    // Identifier l'hôte pour le contrôle du jeu (seul l'hôte révèle les cartes)
    final hostId = state.players.isNotEmpty ? state.players.first.id : '';
    final isHost = hostId == currentUserId;
    
    // Identifier le joueur actuel
    final me = state.players.firstWhere((p) => p.id == currentUserId, orElse: () => state.players.first);

    if (state.phase == GamePhase.miniGame) {
      return Center(
        child: GlassContainer(
          innerGlow: true,
          padding: const EdgeInsets.all(32),
          border: Border.all(color: PyraTheme.primaryYellow, width: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎲 MINI-JEU !', style: TextStyle(color: PyraTheme.primaryYellow, fontSize: 32, fontWeight: FontWeight.bold))
                  .animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 24),
              Text(
                state.lastRevealedCard?.miniGameTitle ?? '',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                state.lastRevealedCard?.miniGameDescription ?? '',
                style: const TextStyle(color: Colors.white70, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (isHost)
                PulsarButton(
                  text: 'Terminer le Mini-Jeu',
                  gradient: PyraTheme.festiveGradient,
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    final newState = GameLogic.endMiniGame(state);
                    service.updateGameState(newState);
                  },
                ),
              if (!isHost)
                const Text('En attente de l\'hôte...', style: TextStyle(color: PyraTheme.textMuted)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        // Phase de jeu (Titre)
        Text(
          _getPhaseTitle(state.phase),
          style: const TextStyle(color: PyraTheme.primaryOrange, fontSize: 24, fontWeight: FontWeight.bold),
        ).animate().fadeIn().scale(),

        const SizedBox(height: 16),
        
        // La pyramide — FittedBox garantit qu'elle tient toujours dans l'espace alloué
        // et que toutes les cartes sont cliquables (Flutter transforme les hit tests)
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.center,
              child: PyramidWidget(
                pyramid: state.pyramid,
                currentRow: state.currentRow,
                currentCardIndex: state.currentCardIndex,
                phase: state.phase,
                onRevealCard: isHost && state.phase == GamePhase.revealing
                    ? () {
                        HapticFeedback.lightImpact();
                        ref.read(randomEventProvider.notifier).tryTriggerEvent(probability: 0.2);
                        final event = ref.read(randomEventProvider);
                        ref.read(randomEventProvider.notifier).clearEvent();
                        final newState = GameLogic.revealCurrentCard(state);
                        if (event != null) {
                           String finalDescription = event.description;
                           List<Player> updatedPlayers = newState.players;
                           
                           final titleLower = event.title.toLowerCase();
                           if ((titleLower.contains("mort") || titleLower.contains("gorgée")) && updatedPlayers.isNotEmpty) {
                             final random = Random();
                             final chosenPlayer = updatedPlayers[random.nextInt(updatedPlayers.length)];
                             finalDescription = "Le jeu désigne ${chosenPlayer.emoji} ${chosenPlayer.name} au hasard qui boit 3 gorgées... Courage !";
                             
                             updatedPlayers = updatedPlayers.map((p) {
                               if (p.id == chosenPlayer.id) {
                                 return p.copyWith(totalSips: p.totalSips + 3);
                               }
                               return p;
                             }).toList();
                           }

                           service.updateGameState(newState.copyWith(
                             players: updatedPlayers,
                             currentRandomEvent: {
                               'title': event.title,
                               'description': finalDescription,
                               'emoji': event.emoji,
                               'type': event.type,
                             },
                           ));
                         } else {
                            service.updateGameState(newState);
                         }
                      }
                    : null,
              ),
            ),
          ),
        ),

        // Action Zone (Milieu)
        Expanded(
          flex: 2,
          child: _buildActionZone(context, ref, state, currentUserId, service),
        ),

        // La main du joueur (En bas)
        SizedBox(
          height: 160,
          child: PlayerHandWidget(
            player: me,
            isInteractive: state.phase == GamePhase.bluffing && state.pendingDrinks.isNotEmpty && state.pendingDrinks.first.isBluffCalled && state.pendingDrinks.first.fromPlayerId == currentUserId, 
            allowPeeking: state.phase != GamePhase.finished && !(state.phase == GamePhase.bluffing && state.pendingDrinks.isNotEmpty && state.pendingDrinks.first.isBluffCalled && state.pendingDrinks.first.fromPlayerId == currentUserId),
            onPeekCard: (index) {
              final roomCode = ref.read(currentRoomCodeProvider);
              if (roomCode != null) {
                service.peekCard(roomCode, currentUserId);
              }
            },
            onCardSelected: (card) {
              if (card != null && state.phase == GamePhase.bluffing && state.pendingDrinks.isNotEmpty && state.pendingDrinks.first.isBluffCalled && state.pendingDrinks.first.fromPlayerId == currentUserId) {
                // Révéler la carte pour le bluff
                service.resolveBluff(state.gameId, card.id);
              }
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildActionZone(BuildContext context, WidgetRef ref, GameState state, String currentUserId, OnlineGameService service) {
    final hostId = state.players.isNotEmpty ? state.players.first.id : '';
    final isHost = hostId == currentUserId;
    final me = state.players.firstWhere((p) => p.id == currentUserId, orElse: () => state.players.first);

    if (state.phase == GamePhase.revealing) {
      return Center(
        child: Text(
          isHost ? 'Appuie sur la carte à révéler !' : 'L\'hôte retourne les cartes...',
          style: const TextStyle(color: PyraTheme.textSecondary, fontSize: 18),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(duration: 1.seconds),
      );
    }

    if (state.phase == GamePhase.bluffing && state.pendingDrinks.isNotEmpty) {
      final assignment = state.pendingDrinks.first;
      final fromPlayer = state.players.firstWhere((p) => p.id == assignment.fromPlayerId);
      final toPlayer = state.players.firstWhere((p) => p.id == assignment.toPlayerId);

      if (assignment.isBluffCalled) {
        if (assignment.fromPlayerId == currentUserId) {
          // C'est à MOI de prouver
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${toPlayer.name} a crié "Tu bluffes !" 😱\nChoisis la bonne carte dans ta main pour le prouver !',
                style: const TextStyle(color: PyraTheme.primaryOrange, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => service.resolveBluff(state.gameId, null),
                child: const Text("J'avoue, j'ai menti... (Cul Sec)"),
              )
            ],
          ).animate().shake();
        } else {
          return GlassContainer(
            innerGlow: true,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            border: Border.all(color: PyraTheme.primaryOrange.withOpacity(0.5), width: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '😱 BLUFF ?!',
                  style: TextStyle(color: PyraTheme.primaryOrange, fontSize: 24, fontWeight: FontWeight.bold),
                ).animate().shake(duration: 500.ms),
                const SizedBox(height: 16),
                Text(
                  '${toPlayer.name} ne croit pas ${fromPlayer.name} !',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Preuve en attente...',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(duration: 1.seconds),
              ],
            ),
          ).animate().fadeIn();
        }
      } else {
        if (assignment.toPlayerId == currentUserId) {
          // C'est à MOI de boire ou de refuser
          final availablePowers = toPlayer.hand.where((c) => c.powerType != PowerType.none).toList();
          return BluffDialog(
            accuser: fromPlayer,
            accused: toPlayer,
            sips: assignment.sips,
            availablePowers: availablePowers,
            isSpeedRun: state.settings.mode == GameMode.speedRun,
            onTimeout: () {
              HapticFeedback.heavyImpact();
              service.speedRunTimeout(state.gameId);
            },
            onAccept: () {
              HapticFeedback.lightImpact();
              service.acceptDrink(state.gameId);
            },
            onChallenge: () {
              HapticFeedback.heavyImpact();
              service.callBluff(state.gameId);
            },
            onUsePower: (cardId) {
              service.usePower(state.gameId, cardId);
            },
            onUseJoker: (jokerId) {
              service.useJoker(state.gameId, jokerId);
            },
          );
        } else {
          // Je regarde l'action des autres
          return GlassContainer(
            innerGlow: true,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            border: Border.all(color: PyraTheme.primaryPink.withOpacity(0.5), width: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '⚔️ ATTAQUE !',
                  style: TextStyle(color: PyraTheme.primaryPink, fontSize: 24, fontWeight: FontWeight.bold),
                ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Donneur
                    Column(
                      children: [
                        AvatarWithBorder(
                          emoji: fromPlayer.emoji,
                          photoUrl: fromPlayer.photoUrl,
                          size: 50,
                          borderType: fromPlayer.selectedBorder,
                        ),
                        const SizedBox(height: 4),
                        Text(fromPlayer.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ).animate().slideX(begin: -0.5, end: 0, duration: 400.ms, curve: Curves.easeOutBack),
                    
                    // Projectiles
                    Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        const SizedBox(width: 60, height: 40),
                        // Tir principal
                        const Icon(Icons.flash_on_rounded, color: PyraTheme.primaryPink, size: 40)
                            .animate(onPlay: (c) => c.repeat())
                            .slideX(begin: -1.5, end: 1.5, duration: 600.ms)
                            .fadeIn(duration: 200.ms)
                            .fadeOut(delay: 400.ms, duration: 200.ms),
                        
                        // Second tir décalé (pour l'effet de rafale)
                        const Icon(Icons.flash_on_rounded, color: PyraTheme.primaryYellow, size: 30)
                            .animate(onPlay: (c) => c.repeat())
                            .slideX(begin: -1.5, end: 1.5, duration: 600.ms, curve: Curves.easeIn)
                            .fadeIn(delay: 200.ms, duration: 200.ms)
                            .fadeOut(delay: 400.ms, duration: 200.ms),
                      ],
                    ),

                    // Victime (Secouée)
                    Column(
                      children: [
                        AvatarWithBorder(
                          emoji: toPlayer.emoji,
                          photoUrl: toPlayer.photoUrl,
                          size: 50,
                          borderType: toPlayer.selectedBorder,
                        ),
                        const SizedBox(height: 4),
                        Text(toPlayer.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).shake(hz: 8),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${assignment.sips} gorgées en jeu...',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 12),
                const CircularProgressIndicator(color: PyraTheme.primaryPink),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms);
        }
      }
    }

    if (state.phase == GamePhase.finished) {
      return Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: PyraTheme.primaryOrange),
          onPressed: () {
             context.goNamed('scoreboard', extra: {
                'players': state.players,
                'isOnline': true,
                'roomCode': state.gameId,
             });
          },
          child: const Text('Voir le Classement', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    if (state.phase == GamePhase.assigning && state.pendingDrinks.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicateur compact
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: PyraTheme.orangeYellowGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '🍺 ${state.currentSips} gorgée${state.currentSips > 1 ? 's' : ''}',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 10),

            // Bouton principal — Je l'ai !
            SizedBox(
              width: double.infinity,
              child: PulsarButton(
                paddingVertical: 11,
                text: '🃏 Je l\'ai ! → Donner ${state.currentSips} gorgée${state.currentSips > 1 ? 's' : ''}',
                gradient: PyraTheme.festiveGradient,
                onPressed: () {
                  _showPlayerSelectionDialog(context, state, currentUserId, service);
                },
              ),
            ).animate(key: ValueKey('btn_${state.currentRow}_${state.currentCardIndex}')).slideY(begin: 0.4, end: 0, duration: 300.ms).fadeIn(),

            // Bouton Passer ce tour (disponible pour tous — invités ET hôte)
            ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: PulsarButton(
                  paddingVertical: 10,
                  text: me.hasPassedThisTurn ? '💤 Je ne joue pas ce tour ✅' : '💤 Je ne joue pas ce tour',
                  gradient: me.hasPassedThisTurn
                      ? const LinearGradient(
                          colors: [Color(0xFF4B5563), Color(0xFF374151)],
                        )
                      : const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                        ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    final newPlayers = state.players.map((p) {
                      if (p.id == currentUserId) {
                        return p.copyWith(hasPassedThisTurn: !p.hasPassedThisTurn);
                      }
                      return p;
                    }).toList();
                    
                    // Tous les joueurs (hôte inclus) doivent avoir coché pour passer automatiquement
                    final allPassed = newPlayers.isNotEmpty && newPlayers.every((p) => p.hasPassedThisTurn);
                    
                    final updatedState = state.copyWith(players: newPlayers);
                    if (allPassed) {
                      HapticFeedback.mediumImpact();
                      final nextState = GameLogic.nextCard(updatedState);
                      
                      if (nextState.phase == GamePhase.revealing) {
                        ref.read(randomEventProvider.notifier).tryTriggerEvent(probability: 0.2);
                        final event = ref.read(randomEventProvider);
                        ref.read(randomEventProvider.notifier).clearEvent();
                        final newState = GameLogic.revealCurrentCard(nextState);
                        
                        if (event != null) {
                           String finalDescription = event.description;
                           List<Player> updatedPlayers = newState.players;
                           
                           final titleLower = event.title.toLowerCase();
                           if ((titleLower.contains("mort") || titleLower.contains("gorgée")) && updatedPlayers.isNotEmpty) {
                             final random = Random();
                             final chosenPlayer = updatedPlayers[random.nextInt(updatedPlayers.length)];
                             finalDescription = "Le jeu désigne ${chosenPlayer.emoji} ${chosenPlayer.name} au hasard qui boit 3 gorgées... Courage !";
                             
                             updatedPlayers = updatedPlayers.map((p) {
                               if (p.id == chosenPlayer.id) {
                                 return p.copyWith(totalSips: p.totalSips + 3);
                               }
                               return p;
                             }).toList();
                           }

                           service.updateGameState(newState.copyWith(
                             players: updatedPlayers,
                             currentRandomEvent: {
                               'title': event.title,
                               'description': finalDescription,
                               'emoji': event.emoji,
                               'type': event.type,
                             },
                           ));
                         } else {
                            service.updateGameState(newState);
                         }
                      } else {
                        service.updateGameState(nextState);
                      }
                    } else {
                      service.updateGameState(updatedState);
                    }
                  },
                ),
              ).animate(key: ValueKey('pass_${me.hasPassedThisTurn}_${state.currentRow}_${state.currentCardIndex}')).slideY(begin: 0.4, end: 0, duration: 300.ms).fadeIn(delay: 80.ms),
            ],

            const SizedBox(height: 8),

            // Statut de passage des joueurs (visible par tout le monde pour se coordonner)
            _buildPlayersPassStatus(state, currentUserId),

            // Tour suivant (hôte seulement)
            if (isHost) ...[
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  final newState = GameLogic.nextCard(state);
                  service.updateGameState(newState);
                },
                icon: const Icon(Icons.skip_next, color: PyraTheme.textMuted, size: 15),
                label: const Text(
                  'Personne — Tour suivant',
                  style: TextStyle(color: PyraTheme.textMuted, fontSize: 12),
                ),
              ).animate(key: ValueKey('next_${state.currentRow}_${state.currentCardIndex}')).fadeIn(delay: 300.ms),
            ],
          ],
        ),
      );
    }

    if (state.phase == GamePhase.transition) {
      if (isHost) {
        return Center(
          child: PulsarButton(
            paddingHorizontal: 64,
            text: 'Tour Suivant',
            gradient: PyraTheme.purplePinkGradient,
            onPressed: () {
              HapticFeedback.mediumImpact();
              final newState = GameLogic.nextCard(state);
              service.updateGameState(newState);
            },
          ),
        );
      } else {
        return const Center(
          child: Text('En attente de l\'hôte pour passer au tour suivant...', style: TextStyle(color: PyraTheme.textMuted)),
        );
      }
    }

    return const SizedBox();
  }

  void _showPlayerSelectionDialog(
    BuildContext context, 
    GameState state, 
    String myId, 
    OnlineGameService service,
    {bool isPigeon = false}
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return GlassContainer(
          innerGlow: true,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'À qui donner ${isPigeon ? state.currentSips * 2 : state.currentSips} gorgées ?',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: state.players.where((p) => p.id != myId).map((p) {
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        AudioManager().playGlassClink();
                        Navigator.pop(ctx);
                        service.assignDrink(state.gameId, p.id, isPigeon: isPigeon);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: PyraTheme.primaryPurple.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: PyraTheme.primaryPink.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(p.emoji, style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 8),
                            Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ).animate().scale(curve: Curves.easeOutBack, duration: 300.ms);
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  }

  String _getPhaseTitle(GamePhase phase) {
    switch (phase) {
      case GamePhase.setup: return 'Préparation...';
      case GamePhase.distribution: return 'Le Bus 🚌';
      case GamePhase.revealing: return 'Révélation !';
      case GamePhase.assigning: return 'Distribution !';
      case GamePhase.bluffing: return 'Bluff en cours...';
      case GamePhase.transition: return 'Suivant...';
      case GamePhase.miniGame: return 'Mini-Jeu !';
      case GamePhase.finished: return 'Terminé !';
    }
  }

  Widget _buildPlayersPassStatus(GameState state, String currentUserId) {
    // Tous les joueurs — y compris soi-même pour visualiser son propre statut
    // On affiche tout le monde sauf soi-même (son statut est déjà visible sur le bouton)
    final otherPlayers = state.players.where((p) => p.id != currentUserId).toList();
    if (otherPlayers.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Statut des joueurs :',
            style: TextStyle(color: PyraTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: otherPlayers.map((p) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: p.hasPassedThisTurn 
                      ? Colors.green.withOpacity(0.12) 
                      : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: p.hasPassedThisTurn 
                        ? Colors.greenAccent.withOpacity(0.4) 
                        : Colors.white.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(p.emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      p.name, 
                      style: TextStyle(
                        color: p.hasPassedThisTurn ? Colors.greenAccent : Colors.white70, 
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      p.hasPassedThisTurn ? '💤' : '⏳',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class TauntOverlay extends StatefulWidget {
  final Map<String, dynamic> tauntData;
  const TauntOverlay({super.key, required this.tauntData});

  @override
  State<TauntOverlay> createState() => _TauntOverlayState();
}

class _TauntOverlayState extends State<TauntOverlay> {
  int _lastTauntTime = 0;

  @override
  Widget build(BuildContext context) {
    final timestamp = widget.tauntData['timestamp'] as int;
    if (timestamp == _lastTauntTime) return const SizedBox.shrink();

    // Reset after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _lastTauntTime != timestamp) {
        setState(() => _lastTauntTime = timestamp);
      }
    });

    final emoji = widget.tauntData['emoji'] as String;
    return IgnorePointer(
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 150))
            .animate(key: ValueKey(timestamp))
            .scale(duration: 400.ms, curve: Curves.easeOutBack)
            .shake(delay: 400.ms)
            .then(delay: 1000.ms)
            .fadeOut(duration: 300.ms)
            .scale(end: const Offset(0, 0)),
      ),
    );
  }
}

class RandomEventOverlay extends StatefulWidget {
  final Map<String, dynamic> eventMap;
  final bool isHost;
  final VoidCallback onClose;

  const RandomEventOverlay({
    super.key,
    required this.eventMap,
    required this.isHost,
    required this.onClose,
  });

  @override
  State<RandomEventOverlay> createState() => _RandomEventOverlayState();
}

class _RandomEventOverlayState extends State<RandomEventOverlay> {
  bool _hasPressedThumb = false;

  @override
  Widget build(BuildContext context) {
    final title = widget.eventMap['title'] ?? 'Événement Aléatoire';
    final isThumbGame = title.toString().toLowerCase().contains('pouce');

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: Center(
          child: GlassContainer(
            innerGlow: true,
            padding: const EdgeInsets.all(32),
            border: Border.all(color: PyraTheme.primaryPink, width: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.eventMap['emoji'] ?? '🎲',
                  style: const TextStyle(fontSize: 80),
                ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack).shake(delay: 500.ms),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: PyraTheme.primaryPink,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 16),
                Text(
                  widget.eventMap['description'] ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 32),

                // Si c'est le jeu des pouces, tout le monde doit pouvoir appuyer
                if (isThumbGame) ...[
                  if (!_hasPressedThumb)
                    PulsarButton(
                      text: '👍 POUCE !',
                      gradient: PyraTheme.cyanGradient,
                      onPressed: () {
                        HapticFeedback.heavyImpact();
                        setState(() {
                          _hasPressedThumb = true;
                        });
                      },
                    ).animate().scale(duration: 300.ms)
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.greenAccent, width: 2),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Colors.greenAccent, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Pouce posé ! ✅ (Sauvé !)',
                            style: TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ).animate().scale().fadeIn(),
                  const SizedBox(height: 24),
                ],

                // Le bouton Continuer n'est affiché que pour l'hôte !
                if (widget.isHost)
                  PulsarButton(
                    text: 'Continuer',
                    gradient: PyraTheme.festiveGradient,
                    onPressed: widget.onClose,
                  ).animate().slideY(begin: 0.5, end: 0, duration: 300.ms, delay: 300.ms).fadeIn()
                else if (!isThumbGame)
                  // Si ce n'est pas le jeu des pouces et qu'on n'est pas l'hôte, indicateur d'attente
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: PyraTheme.primaryPink),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "En attente de l'hôte... ⏳",
                          style: TextStyle(color: PyraTheme.textMuted, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().scale(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
