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
import '../profile/user_profile_provider.dart';

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

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent.shade700.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _joinRoom(String code) async {
    if (code.isEmpty) {
      _showErrorSnackBar("Veuillez saisir un code de salon.");
      return;
    }
    if (code.length < 4) {
      _showErrorSnackBar("Le code doit comporter 4 caractères.");
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    try {
      final service = ref.read(onlineGameServiceProvider);
      await service.joinRoom(code);
      ref.read(currentRoomCodeProvider.notifier).state = code;
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith("Exception: ")) {
        errorMessage = errorMessage.substring("Exception: ".length);
      }
      _showErrorSnackBar(errorMessage);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showJoinDialog() {
    _codeController.clear();
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
                    width: null,
                    paddingHorizontal: 24,
                    paddingVertical: 12,
                    gradient: PyraTheme.purplePinkGradient,
                    onPressed: () {
                      Navigator.pop(context);
                      _joinRoom(_codeController.text.trim().toUpperCase());
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
    final userProfileAsync = ref.watch(userProfileProvider);
    final String userEmoji = userProfileAsync.value?.emoji ?? '😎';

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

                return _buildLobbyMenu(user.displayName, userEmoji);
              },
              loading: () => const Center(child: CircularProgressIndicator(color: PyraTheme.primaryPurple)),
              error: (err, _) => Center(child: Text('Erreur: $err', style: const TextStyle(color: Colors.red))),
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildLobbyMenu(String? name, String emoji) {
    return Column(
      children: [
        // Top Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              const Expanded(
                child: Text(
                  'Mode en Ligne',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48), // Balance for title
            ],
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            children: [
              // User Card
              GlassContainer(
                padding: const EdgeInsets.all(20),
                borderRadius: BorderRadius.circular(24),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: PyraTheme.primaryPink.withOpacity(0.5), width: 2),
                        boxShadow: [
                          BoxShadow(color: PyraTheme.primaryPink.withOpacity(0.3), blurRadius: 15, spreadRadius: 2),
                        ],
                      ),
                      child: ClipOval(
                        child: Container(
                          color: PyraTheme.primaryPurple,
                          child: Center(
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Connecté en tant que', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          Text(
                            name ?? 'Invité',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),

              const SizedBox(height: 32),

              const Text(
                'Choix du Mode',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 16),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(child: CircularProgressIndicator(color: PyraTheme.primaryPink)),
                )
              else ...[
                GameModeCarousel(
                  selectedMode: _settings.mode,
                  replaceCardsWithPowers: _settings.replaceCardsWithPowers,
                  onModeChanged: (mode) => setState(() => _settings = _settings.copyWith(mode: mode)),
                  onReplaceCardsChanged: (v) => setState(() => _settings = _settings.copyWith(replaceCardsWithPowers: v)),
                ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.2),

                const SizedBox(height: 32),

                PulsarButton(
                  text: 'Créer un salon',
                  icon: Icons.add_circle_outline_rounded,
                  gradient: PyraTheme.purplePinkGradient,
                  onPressed: _createRoom,
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

                const SizedBox(height: 16),

                PulsarButton(
                  text: 'Rejoindre un salon',
                  icon: Icons.login_rounded,
                  gradient: PyraTheme.cyanGradient,
                  onPressed: _showJoinDialog,
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

                const SizedBox(height: 16),

                PulsarButton(
                  text: 'Scanner un QR Code',
                  icon: Icons.qr_code_scanner_rounded,
                  gradient: const LinearGradient(colors: [Colors.indigo, PyraTheme.primaryPurple]),
                  onPressed: _showScannerDialog,
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
              ],
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildWaitingRoom(String roomCode, String currentUserId) {
    final gameStateAsync = ref.watch(onlineGameStateProvider);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 750 || screenSize.width < 380;

    // Dimensions adaptatives pour petits écrans (iPhone 13 mini / SE)
    final double qrSize = isSmallScreen ? 110.0 : 160.0;
    final double tableSize = isSmallScreen ? 200.0 : 300.0;
    final double circleRadius = isSmallScreen ? 70.0 : 110.0;
    final double avatarSize = isSmallScreen ? 44.0 : 56.0;
    final double fontSizeRoom = isSmallScreen ? 48.0 : 64.0;
    final double centerCircleSize = isSmallScreen ? 60.0 : 100.0;
    final double centerIconSize = isSmallScreen ? 24.0 : 40.0;
    final double spaceTop = isSmallScreen ? 10.0 : 24.0;
    final double spaceMiddle = isSmallScreen ? 10.0 : 24.0;
    final double spaceBottom = isSmallScreen ? 14.0 : 28.0;

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
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
            
            SizedBox(height: spaceTop),
            Text(
              roomCode,
              style: TextStyle(
                fontSize: fontSizeRoom,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                color: PyraTheme.primaryOrange,
              ),
            ),
            const Text('Partage ce code à tes amis', style: TextStyle(color: PyraTheme.textSecondary)),
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: roomCode,
                  version: QrVersions.auto,
                  size: qrSize,
                ),
              ),
            ),
            SizedBox(height: spaceMiddle),

            Expanded(
              child: Center(
                child: SizedBox(
                  width: tableSize,
                  height: tableSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Centre de la table (Effet Holographique / Feu)
                      Container(
                        width: centerCircleSize,
                        height: centerCircleSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: PyraTheme.primaryCyan.withOpacity(0.2), blurRadius: 40, spreadRadius: 10),
                            BoxShadow(color: PyraTheme.primaryPink.withOpacity(0.1), blurRadius: 80, spreadRadius: 20),
                          ],
                        ),
                        child: Center(
                          child: Icon(Icons.wifi_tethering_rounded, color: Colors.white54, size: centerIconSize),
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.1,1.1), duration: 2.seconds),

                      // Joueurs autour de la table
                      ...List.generate(state.players.length, (index) {
                        final player = state.players[index];
                        final isMe = player.id == currentUserId;
                        final isHostPlayer = index == 0;
                        
                        // Calcul de la position sur le cercle
                        final double angle = (2 * math.pi / state.players.length) * index - math.pi / 2;
                        final double radius = circleRadius;
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
                                      // Anneau XP
                                      SizedBox(
                                        width: avatarSize + 8, height: avatarSize + 8,
                                        child: CircularProgressIndicator(
                                          value: (player.xp / (player.level * 100)).clamp(0.0, 1.0),
                                          strokeWidth: isSmallScreen ? 3 : 4,
                                          backgroundColor: Colors.white.withOpacity(0.05),
                                          valueColor: const AlwaysStoppedAnimation<Color>(PyraTheme.primaryCyan),
                                          strokeCap: StrokeCap.round,
                                        ),
                                      ),
                                      // Avatar avec effet "Pop" à l'entrée
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isMe ? PyraTheme.primaryPink : (isHostPlayer ? PyraTheme.primaryYellow : Colors.transparent),
                                            width: 1.5,
                                          ),
                                          boxShadow: isMe || isHostPlayer ? [
                                            BoxShadow(
                                              color: (isMe ? PyraTheme.primaryPink : PyraTheme.primaryYellow).withOpacity(0.5),
                                              blurRadius: 8,
                                            )
                                          ] : null,
                                        ),
                                        child: ClipOval(
                                          child: player.photoUrl != null
                                              ? Image.network(
                                                  player.photoUrl!,
                                                  width: avatarSize,
                                                  height: avatarSize,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => _buildFallbackAvatar(player.emoji, avatarSize),
                                                )
                                              : _buildFallbackAvatar(player.emoji, avatarSize),
                                        ),
                                      ),
                                      
                                      // Couronne pour l'hôte
                                      if (isHostPlayer)
                                        Positioned(
                                          top: isSmallScreen ? -10 : -12,
                                          child: Text('👑', style: TextStyle(fontSize: isSmallScreen ? 16 : 20))
                                            .animate(onPlay: (c) => c.repeat(reverse: true))
                                            .slideY(begin: 0, end: -0.2, duration: 1.seconds),
                                        ),

                                      // Badge de niveau
                                      Positioned(
                                        bottom: -2, right: -8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          decoration: BoxDecoration(
                                            gradient: PyraTheme.cyanGradient,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: PyraTheme.bgDark, width: 1.5),
                                          ),
                                          child: Text('${player.level}',
                                            style: const TextStyle(color: Colors.black,
                                                fontSize: 8, fontWeight: FontWeight.w900),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  // Titre + Nom
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        if (player.activeTitle.isNotEmpty)
                                          Text(
                                            player.activeTitle.toUpperCase(),
                                            style: TextStyle(color: PyraTheme.primaryCyan, fontSize: isSmallScreen ? 6 : 7, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        Text(
                                          player.name.split(' ').first, // Prénom uniquement
                                          style: TextStyle(color: Colors.white, fontSize: isSmallScreen ? 8 : 10, fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
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
                padding: EdgeInsets.all(spaceBottom),
                child: PulsarButton(
                  text: 'Démarrer la partie',
                  gradient: PyraTheme.orangeYellowGradient,
                  onPressed: state.players.length >= 2 
                      ? () => _startGame(state) 
                      : null,
                ),
              )
            else
              Padding(
                padding: EdgeInsets.all(spaceBottom),
                child: const Text('En attente de l\'hôte...', style: TextStyle(color: PyraTheme.textMuted)),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: PyraTheme.primaryPurple)),
      error: (err, _) => Center(child: Text('Erreur : $err', style: const TextStyle(color: Colors.red))),
    );
  }

  Widget _buildFallbackAvatar(String emoji, double size) {
    return Container(
      width: size,
      height: size,
      color: PyraTheme.bgSurface,
      child: Center(child: Text(emoji, style: TextStyle(fontSize: size * 0.43))),
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
