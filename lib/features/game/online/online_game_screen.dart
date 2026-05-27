import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/audio/audio_manager.dart';
import '../../../shared/widgets/animated_background.dart';
import '../../auth/auth_service.dart';
import '../game_logic.dart';
import '../models/card_model.dart';
import '../models/game_state.dart';
import '../models/player_model.dart';
import '../online/online_game_service.dart';
import '../services/random_event_service.dart';
import '../widgets/drink_and_bluff_widgets.dart';
import '../widgets/player_hand_widget.dart';
import '../widgets/pyramid_widget.dart';
import '../../../shared/widgets/playing_card_widget.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/pulsar_button.dart';
import '../widgets/distribution_screen.dart';
import '../widgets/end_game_screen.dart';

class OnlineGameScreen extends ConsumerWidget {
  const OnlineGameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<GameState?>>(onlineGameStateProvider, (previous, next) {
      final oldState = previous?.value;
      final newState = next.value;

      if (newState != null && newState.lastEventTime != null) {
        if (oldState == null || oldState.lastEventTime != newState.lastEventTime) {
          if (newState.lastBluffResult != BluffResult.none && newState.lastRevealedCard != null) {
            // Afficher le résultat du bluff en grand
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) {
                Future.delayed(const Duration(seconds: 4), () {
                  if (ctx.mounted) Navigator.of(ctx).pop();
                });
                final isCaught = newState.lastBluffResult == BluffResult.caught;
                return Dialog(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isCaught ? '💥 MENTEUR !' : '✅ VÉRITÉ !',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: isCaught ? Colors.redAccent : Colors.greenAccent,
                        ),
                      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 200,
                        width: 140,
                        child: PlayingCardWidget(card: newState.lastRevealedCard!),
                      ).animate().flip(duration: 600.ms, direction: Axis.horizontal),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          newState.lastEventMessage ?? '',
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                      ).animate().fadeIn(delay: 600.ms),
                    ],
                  ),
                );
              },
            );
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
          // Bouton Mission Secrète
          if (gameStateAsync.value != null && gameStateAsync.value!.phase != GamePhase.setup)
            Positioned(
              top: 48,
              right: 16,
              child: _buildSecretMissionBtn(context, gameStateAsync.value!.players.firstWhere((p) => p.id == user.uid, orElse: () => gameStateAsync.value!.players.first).secretMission),
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
                           service.updateGameState(newState.copyWith(
                             currentRandomEvent: {
                               'title': event.title,
                               'description': event.description,
                               'emoji': event.emoji,
                               'type': event.type,
                             }
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
                    Column(
                      children: [
                        Text(fromPlayer.emoji, style: const TextStyle(fontSize: 40)),
                        Text(fromPlayer.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Icon(Icons.double_arrow, color: PyraTheme.primaryPink, size: 32),
                    Column(
                      children: [
                        Text(toPlayer.emoji, style: const TextStyle(fontSize: 40)),
                        Text(toPlayer.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
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
            // Seul l'hôte peut redémarrer la partie pour le moment
            // Ou on permet à tout le monde d'aller au scoreboard
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

            // Bouton Tir au Pigeon
            if (!me.hasUsedPigeon) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: PulsarButton(
                  paddingVertical: 10,
                  text: '🐦 Tir au Pigeon → ${state.currentSips * 2} gorgées',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
                  ),
                  onPressed: () {
                    _showPlayerSelectionDialog(context, state, currentUserId, service, isPigeon: true);
                  },
                ),
              ).animate(key: ValueKey('pigeon_${state.currentRow}_${state.currentCardIndex}')).slideY(begin: 0.4, end: 0, duration: 300.ms).fadeIn(delay: 80.ms),
            ],

            // Tour suivant (hôte seulement)
            if (isHost) ...[
              const SizedBox(height: 2),
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
                  spacing: 8,
                  runSpacing: 8,
                  children: state.players.where((p) => p.id != myId).map((p) {
                    return ActionChip(
                      backgroundColor: PyraTheme.primaryPurple.withOpacity(0.2),
                      label: Text(p.name, style: const TextStyle(color: Colors.white)),
                      avatar: Text(p.emoji),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        AudioManager().playDrink();
                        Navigator.pop(ctx);
                        service.assignDrink(state.gameId, p.id, isPigeon: isPigeon);
                      },
                    );
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

class RandomEventOverlay extends StatelessWidget {
  final Map<String, dynamic> eventMap;
  final VoidCallback onClose;

  const RandomEventOverlay({super.key, required this.eventMap, required this.onClose});

  @override
  Widget build(BuildContext context) {
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
                  eventMap['emoji'] ?? '🎲',
                  style: const TextStyle(fontSize: 80),
                ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack).shake(delay: 500.ms),
                const SizedBox(height: 16),
                Text(
                  eventMap['title'] ?? 'Événement Aléatoire',
                  style: const TextStyle(
                    color: PyraTheme.primaryPink,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 16),
                Text(
                  eventMap['description'] ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 32),
                PulsarButton(
                  text: 'Continuer',
                  gradient: PyraTheme.festiveGradient,
                  onPressed: onClose,
                ).animate().slideY(begin: 0.5, end: 0, duration: 300.ms, delay: 600.ms).fadeIn(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
