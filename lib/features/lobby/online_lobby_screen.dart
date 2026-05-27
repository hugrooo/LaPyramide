import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../app/theme.dart';
import '../../shared/widgets/animated_background.dart';
import '../../shared/widgets/gradient_button.dart';
import '../../shared/widgets/pulsar_button.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/game_mode_carousel.dart';
import '../auth/auth_service.dart';
import '../game/models/game_state.dart';
import '../game/models/player_model.dart';
import '../game/online/online_game_service.dart';

class OnlineLobbyScreen extends ConsumerStatefulWidget {
  const OnlineLobbyScreen({super.key});

  @override
  ConsumerState<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends ConsumerState<OnlineLobbyScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  GameSettings _settings = const GameSettings();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    try {
      final service = ref.read(onlineGameServiceProvider);
      final roomCode = await service.createRoom(_settings);
      ref.read(currentRoomCodeProvider.notifier).state = roomCode;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinRoom(String code) async {
    if (code.isEmpty) return;
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    try {
      final service = ref.read(onlineGameServiceProvider);
      await service.joinRoom(code);
      ref.read(currentRoomCodeProvider.notifier).state = code;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showJoinDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: GlassContainer(
          padding: const EdgeInsets.all(24),
          color: PyraTheme.bgCard,
          opacity: 0.6,
          border: Border.all(color: PyraTheme.primaryPurple.withOpacity(0.5)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Rejoindre', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _codeController,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 32, letterSpacing: 8, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  hintText: 'CODE',
                  hintStyle: TextStyle(color: PyraTheme.textMuted, fontSize: 24, letterSpacing: 4),
                  counterText: '',
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: PyraTheme.primaryPurple)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: PyraTheme.primaryPink, width: 2)),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler', style: TextStyle(color: PyraTheme.textMuted)),
                  ),
                  PulsarButton(
                    text: 'Rejoindre',
                    paddingHorizontal: 24,
                    paddingVertical: 12,
                    gradient: PyraTheme.purplePinkGradient,
                    onPressed: () {
                      Navigator.pop(context);
                      _joinRoom(_codeController.text.toUpperCase());
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _leaveRoom(String roomCode) async {
    final service = ref.read(onlineGameServiceProvider);
    await service.leaveRoom(roomCode);
    ref.read(currentRoomCodeProvider.notifier).state = null;
  }

  Future<void> _startGame(GameState state) async {
    final service = ref.read(onlineGameServiceProvider);
    final newState = state.copyWith(phase: GamePhase.distribution);
    await service.updateGameState(newState);
  }

  @override
  Widget build(BuildContext context) {
    final roomCode = ref.watch(currentRoomCodeProvider);
    final authState = ref.watch(authStateChangesProvider);

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: authState.when(
              data: (user) {
                if (user == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) context.goNamed('home');
                  });
                  return const Center(child: CircularProgressIndicator(color: PyraTheme.primaryPurple));
                }

                if (roomCode != null) {
                  return _buildWaitingRoom(roomCode, user.uid);
                }

                return _buildLobbyMenu(user.displayName, user.photoURL);
              },
              loading: () => const Center(child: CircularProgressIndicator(color: PyraTheme.primaryPurple)),
              error: (err, _) => Center(child: Text('Erreur: $err', style: const TextStyle(color: Colors.red))),
            ),
          ),

          // Bouton Retour Général
          if (roomCode == null)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLobbyMenu(String? name, String? photoUrl) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            ClipOval(
              child: photoUrl != null
                  ? Image.network(
                      photoUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 80,
                        height: 80,
                        color: PyraTheme.primaryPurple,
                        child: const Center(child: Text('👤', style: TextStyle(fontSize: 40))),
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: PyraTheme.primaryPurple,
                      child: const Center(child: Text('👤', style: TextStyle(fontSize: 40))),
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              'Connecté en tant que\n${name ?? "Invité"}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => ref.read(authServiceProvider).signOut(),
              child: const Text('Déconnexion', style: TextStyle(color: Colors.redAccent)),
            ),
            const SizedBox(height: 48),

            if (_isLoading)
              const CircularProgressIndicator(color: PyraTheme.primaryPink)
            else ...[
              GameModeCarousel(
                selectedMode: _settings.mode,
                replaceCardsWithPowers: _settings.replaceCardsWithPowers,
                onModeChanged: (mode) => setState(() => _settings = _settings.copyWith(mode: mode)),
                onReplaceCardsChanged: (v) => setState(() => _settings = _settings.copyWith(replaceCardsWithPowers: v)),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: PulsarButton(
                  text: 'Créer un salon',
                  gradient: PyraTheme.purplePinkGradient,
                  onPressed: _createRoom,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: PulsarButton(
                  text: 'Rejoindre un salon',
                  gradient: const LinearGradient(colors: [PyraTheme.bgCard, PyraTheme.bgCard]),
                  onPressed: _showJoinDialog,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: PulsarButton(
                  text: '📷 Scanner un QR Code',
                  gradient: const LinearGradient(colors: [PyraTheme.primaryPurple, Colors.indigo]),
                  onPressed: _showScannerDialog,
                ),
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }


  Widget _buildWaitingRoom(String roomCode, String currentUserId) {
    final gameStateAsync = ref.watch(onlineGameStateProvider);

    return gameStateAsync.when(
      data: (state) {
        if (state == null) {
          // Le salon a été détruit
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(currentRoomCodeProvider.notifier).state = null;
          });
          return const SizedBox();
        }

        // Si la partie a démarré, rediriger vers l'écran de jeu
        if (state.phase != GamePhase.setup) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
             if (context.mounted) {
               // Redirection vers le jeu
               context.pushReplacementNamed('onlineGame');
             }
          });
          return const Center(child: Text('Démarrage...', style: TextStyle(color: Colors.white)));
        }

        final isHost = state.players.isNotEmpty && state.players.first.id == currentUserId;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
                    onPressed: () => _leaveRoom(roomCode),
                  ),
                  const Spacer(),
                  const Text('SALON', style: TextStyle(color: PyraTheme.textMuted, letterSpacing: 2)),
                  const Spacer(),
                  const SizedBox(width: 48), // Equilibre
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            Text(
              roomCode,
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                color: PyraTheme.primaryOrange,
              ),
            ),
            const Text('Partage ce code à tes amis', style: TextStyle(color: PyraTheme.textSecondary)),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: roomCode,
                  version: QrVersions.auto,
                  size: 160.0,
                ),
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: Center(
                child: SizedBox(
                  width: 300,
                  height: 300,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Centre de la table (Effet Holographique / Feu)
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: PyraTheme.primaryCyan.withOpacity(0.2), blurRadius: 40, spreadRadius: 10),
                            BoxShadow(color: PyraTheme.primaryPink.withOpacity(0.1), blurRadius: 80, spreadRadius: 20),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.wifi_tethering_rounded, color: Colors.white54, size: 40),
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.1,1.1), duration: 2.seconds),

                      // Joueurs autour de la table
                      ...List.generate(state.players.length, (index) {
                        final player = state.players[index];
                        final isMe = player.id == currentUserId;
                        final isHostPlayer = index == 0;
                        
                        // Calcul de la position sur le cercle
                        final double angle = (2 * math.pi / state.players.length) * index - math.pi / 2;
                        const double radius = 110.0;
                        final double x = radius * math.cos(angle);
                        final double y = radius * math.sin(angle);

                        return Transform.translate(
                          offset: Offset(x, y),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                clipBehavior: Clip.none,
                                children: [
                                  // Avatar avec effet "Pop" à l'entrée
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isMe ? PyraTheme.primaryPink : (isHostPlayer ? PyraTheme.primaryYellow : Colors.white24),
                                        width: 2.5,
                                      ),
                                      boxShadow: isMe || isHostPlayer ? [
                                        BoxShadow(
                                          color: (isMe ? PyraTheme.primaryPink : PyraTheme.primaryYellow).withOpacity(0.5),
                                          blurRadius: 16,
                                        )
                                      ] : null,
                                    ),
                                    child: ClipOval(
                                      child: player.photoUrl != null
                                          ? Image.network(
                                              player.photoUrl!,
                                              width: 56,
                                              height: 56,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => _buildFallbackAvatar(player.emoji),
                                            )
                                          : _buildFallbackAvatar(player.emoji),
                                    ),
                                  ),
                                  
                                  // Couronne pour l'hôte
                                  if (isHostPlayer)
                                    Positioned(
                                      top: -12,
                                      child: const Text('👑', style: TextStyle(fontSize: 20))
                                        .animate(onPlay: (c) => c.repeat(reverse: true))
                                        .slideY(begin: 0, end: -0.2, duration: 1.seconds),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  player.name.split(' ').first, // Prénom uniquement pour prendre moins de place
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),

            if (isHost)
              Padding(
                padding: const EdgeInsets.all(28.0),
                child: PulsarButton(
                  text: 'Démarrer la partie',
                  gradient: PyraTheme.orangeYellowGradient,
                  onPressed: state.players.length >= 2 
                      ? () => _startGame(state) 
                      : null,
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.all(28.0),
                child: Text('En attente de l\'hôte...', style: TextStyle(color: PyraTheme.textMuted)),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: PyraTheme.primaryPurple)),
      error: (err, _) => Center(child: Text('Erreur : $err', style: const TextStyle(color: Colors.red))),
    );
  }

  Widget _buildFallbackAvatar(String emoji) {
    return Container(
      width: 56,
      height: 56,
      color: PyraTheme.bgSurface,
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
    );
  }

  void _showScannerDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: PyraTheme.bgDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text('Scanner un QR Code', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: MobileScanner(
                      onDetect: (capture) {
                        final List<Barcode> barcodes = capture.barcodes;
                        for (final barcode in barcodes) {
                          if (barcode.rawValue != null) {
                            final code = barcode.rawValue!.trim();
                            if (code.length == 4) {
                              Navigator.pop(context);
                              _joinRoom(code);
                              break;
                            }
                          }
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
