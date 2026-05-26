import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/audio/audio_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String? _savedRoomCode;
  String _savedAvatar = '😎';
  bool _isMuted = false;

  static const List<String> _avatars = [
    '😎', '🤠', '👻', '👽', '🤖', '💩', '🤡', '🦄', '🦁', '🦊',
    '🐯', '🐸', '🤑', '😈', '🥳', '🤩',
  ];

  // Animation controllers
  late AnimationController _floatController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  late Animation<double> _floatAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _loadSavedRoom();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _floatAnim = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _glowAnim = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedRoom() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('currentRoomCode');
    final avatar = prefs.getString('userAvatar');
    final isMuted = prefs.getBool('isMuted') ?? false;
    if (mounted) {
      setState(() {
        if (code != null && code.isNotEmpty) _savedRoomCode = code;
        if (avatar != null) _savedAvatar = avatar;
        _isMuted = isMuted;
      });
    }
  }

  void _showAvatarPicker() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _AvatarPickerSheet(
        currentAvatar: _savedAvatar,
        avatars: _avatars,
        onSelected: (emoji) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userAvatar', emoji);
          if (mounted) setState(() => _savedAvatar = emoji);
          if (mounted) Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: PyraTheme.bgDark,
      body: Stack(
        children: [
          // ── Fond : gradient + particules custom ──────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (_, __) => CustomPaint(
                painter: _HomeBgPainter(_particleController.value),
              ),
            ),
          ),

          // ── Contenu principal ─────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── Barre supérieure ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Bouton son
                      _TopBarButton(
                        onTap: () async {
                          HapticFeedback.selectionClick();
                          setState(() => _isMuted = !_isMuted);
                          AudioManager().setMuted(_isMuted);
                        },
                        child: Icon(
                          _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                          color: Colors.white.withOpacity(0.9),
                          size: 22,
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.3),

                      // Label version
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: PyraTheme.primaryPurple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: PyraTheme.primaryPurple.withOpacity(0.4)),
                        ),
                        child: const Text(
                          'v1.0',
                          style: TextStyle(color: PyraTheme.primaryPurple, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ).animate().fadeIn(delay: 300.ms),

                      // Avatar
                      GestureDetector(
                        onTap: _showAvatarPicker,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: PyraTheme.purplePinkGradient,
                            boxShadow: [BoxShadow(color: PyraTheme.primaryPurple.withOpacity(0.5), blurRadius: 12, spreadRadius: 1)],
                          ),
                          child: Center(
                            child: Text(_savedAvatar, style: const TextStyle(fontSize: 26)),
                          ),
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.3),
                    ],
                  ),
                ),

                // ── Hero central ─────────────────────────────────────────
                Expanded(
                  flex: 5,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Pyramide animée flottante avec glow
                        AnimatedBuilder(
                          animation: Listenable.merge([_floatController, _glowController]),
                          builder: (_, child) => Transform.translate(
                            offset: Offset(0, _floatAnim.value),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Glow derrière la pyramide
                                Container(
                                  width: 160,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: PyraTheme.primaryPurple.withOpacity(_glowAnim.value * 0.6),
                                        blurRadius: 80,
                                        spreadRadius: 20,
                                      ),
                                      BoxShadow(
                                        color: PyraTheme.primaryPink.withOpacity(_glowAnim.value * 0.3),
                                        blurRadius: 50,
                                        spreadRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                                child!,
                              ],
                            ),
                          ),
                          child: ShaderMask(
                            shaderCallback: (bounds) => PyraTheme.festiveGradient.createShader(bounds),
                            child: const Text('🔺', style: TextStyle(fontSize: 100, color: Colors.white)),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Titre principal avec double ligne
                        Column(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFFE879F9), Color(0xFFF97316), Color(0xFFE879F9)],
                                stops: [0, 0.5, 1],
                              ).createShader(bounds),
                              child: const Text(
                                'PYRAMIDE',
                                style: TextStyle(
                                  fontSize: 52,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 6,
                                  height: 1.0,
                                ),
                              ),
                            ),
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                              ).createShader(bounds),
                              child: const Text(
                                'PARTY',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 12,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ],
                        )
                            .animate()
                            .fadeIn(duration: 800.ms, delay: 100.ms)
                            .slideY(begin: -0.2, curve: Curves.easeOut),

                        const SizedBox(height: 12),

                        // Sous-titre avec icônes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _dot(),
                            const SizedBox(width: 8),
                            Text(
                              'Le jeu de cartes du chaos',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.55),
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _dot(),
                          ],
                        ).animate().fadeIn(delay: 500.ms),
                      ],
                    ),
                  ),
                ),

                // ── Boutons principaux ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Bouton Jouer en local — le principal
                      _MainActionButton(
                        label: '🃏  Jouer en local',
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          context.pushNamed('localLobby');
                        },
                      ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3, curve: Curves.easeOut),

                      const SizedBox(height: 14),

                      // Bouton Jouer en ligne — secondaire mais distinct
                      _MainActionButton(
                        label: '🌐  Jouer en ligne',
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF97316), Color(0xFFFBBF24)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          context.pushNamed('auth');
                        },
                      ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.3, curve: Curves.easeOut),

                      // Bandeau "Partie en cours" si applicable
                      if (_savedRoomCode != null) ...[
                        const SizedBox(height: 14),
                        _ResumeGameBanner(
                          roomCode: _savedRoomCode!,
                          onTap: () {
                            HapticFeedback.heavyImpact();
                            context.pushNamed('onlineGame', pathParameters: {'roomId': _savedRoomCode!});
                          },
                        ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Navigation secondaire ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      _NavTab(
                        icon: Icons.menu_book_rounded,
                        label: 'Règles',
                        onTap: () => context.pushNamed('rules'),
                      ).animate().fadeIn(delay: 850.ms),
                      const SizedBox(width: 10),
                      _NavTab(
                        icon: Icons.leaderboard_rounded,
                        label: 'Classement',
                        onTap: () => context.pushNamed('leaderboard'),
                      ).animate().fadeIn(delay: 900.ms),
                      const SizedBox(width: 10),
                      _NavTab(
                        icon: Icons.settings_rounded,
                        label: 'Paramètres',
                        onTap: () => context.pushNamed('settings'),
                      ).animate().fadeIn(delay: 950.ms),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot() => Container(
    width: 4,
    height: 4,
    decoration: BoxDecoration(
      color: PyraTheme.primaryPurple.withOpacity(0.5),
      shape: BoxShape.circle,
    ),
  );
}

// ── Widgets privés ───────────────────────────────────────────────────────────

class _TopBarButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _TopBarButton({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _MainActionButton extends StatefulWidget {
  final String label;
  final LinearGradient gradient;
  final VoidCallback onPressed;

  const _MainActionButton({
    required this.label,
    required this.gradient,
    required this.onPressed,
  });

  @override
  State<_MainActionButton> createState() => _MainActionButtonState();
}

class _MainActionButtonState extends State<_MainActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _ctrl.forward();
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.colors.last.withOpacity(0.45),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavTab({required this.icon, required this.label, required this.onTap});

  @override
  State<_NavTab> createState() => _NavTabState();
}

class _NavTabState extends State<_NavTab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _pressed = true);
          HapticFeedback.selectionClick();
        },
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _pressed
                ? PyraTheme.primaryPurple.withOpacity(0.25)
                : Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _pressed
                  ? PyraTheme.primaryPurple.withOpacity(0.6)
                  : Colors.white.withOpacity(0.1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                color: _pressed ? PyraTheme.primaryPurple : Colors.white.withOpacity(0.7),
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _pressed ? PyraTheme.primaryPurple : Colors.white.withOpacity(0.6),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResumeGameBanner extends StatelessWidget {
  final String roomCode;
  final VoidCallback onTap;

  const _ResumeGameBanner({required this.roomCode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  PyraTheme.primaryOrange.withOpacity(0.2),
                  PyraTheme.primaryYellow.withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: PyraTheme.primaryOrange.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: PyraTheme.primaryOrange.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('⚡', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Partie en cours',
                        style: TextStyle(color: PyraTheme.primaryOrange, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      Text(
                        'Reprendre le salon $roomCode',
                        style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: PyraTheme.primaryOrange, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarPickerSheet extends StatelessWidget {
  final String currentAvatar;
  final List<String> avatars;
  final ValueChanged<String> onSelected;

  const _AvatarPickerSheet({
    required this.currentAvatar,
    required this.avatars,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: PyraTheme.bgCard.withOpacity(0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ShaderMask(
                shaderCallback: (bounds) => PyraTheme.purplePinkGradient.createShader(bounds),
                child: const Text(
                  'Choisis ton Avatar',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: avatars.length,
                itemBuilder: (_, i) {
                  final emoji = avatars[i];
                  final isSelected = emoji == currentAvatar;
                  return GestureDetector(
                    onTap: () => onSelected(emoji),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? PyraTheme.primaryPurple.withOpacity(0.3)
                            : Colors.white.withOpacity(0.05),
                        border: Border.all(
                          color: isSelected ? PyraTheme.primaryPurple : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(emoji, style: const TextStyle(fontSize: 28)),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Peintre du fond premium ──────────────────────────────────────────────────

class _HomeBgPainter extends CustomPainter {
  final double progress;
  static final _random = Random(42); // seed fixe pour cohérence
  static final List<_BgParticle> _particles = List.generate(
    30,
    (_) => _BgParticle(_random),
  );

  _HomeBgPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    // Fond dégradé
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0A0A18), Color(0xFF130827), Color(0xFF0A0A18)],
        stops: [0, 0.5, 1],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Halo central violet
    final haloPaint = Paint()
      ..color = const Color(0xFF8B5CF6).withOpacity(0.07)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.38), 220, haloPaint);

    // Halo bas orange
    final haloOrange = Paint()
      ..color = const Color(0xFFF97316).withOpacity(0.05)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.85), 180, haloOrange);

    // Particules flottantes
    for (final p in _particles) {
      final y = (p.y - p.speed * progress) % 1.0;
      final opacity = (sin(progress * 2 * pi + p.phase) * 0.15 + p.baseOpacity).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withOpacity(opacity)
        ..maskFilter = p.size > 3
            ? MaskFilter.blur(BlurStyle.normal, p.size * 0.6)
            : null;
      canvas.drawCircle(
        Offset(p.x * size.width, y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_HomeBgPainter old) => old.progress != progress;
}

class _BgParticle {
  final double x, y, size, speed, phase, baseOpacity;
  final Color color;

  _BgParticle(Random r)
      : x = r.nextDouble(),
        y = r.nextDouble(),
        size = r.nextDouble() * 3 + 0.5,
        speed = r.nextDouble() * 0.08 + 0.02,
        phase = r.nextDouble() * 2 * pi,
        baseOpacity = r.nextDouble() * 0.2 + 0.05,
        color = _colors[r.nextInt(_colors.length)];

  static const _colors = [
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFFF97316),
    Color(0xFFFBBF24),
    Color(0xFFFFFFFF),
  ];
}
