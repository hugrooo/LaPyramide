import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/theme.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/gradient_button.dart';

class BoardGamesScreen extends StatefulWidget {
  const BoardGamesScreen({super.key});

  @override
  State<BoardGamesScreen> createState() => _BoardGamesScreenState();
}

class _BoardGamesScreenState extends State<BoardGamesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PyraTheme.bgDark,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: PyraTheme.mainGradient,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header / AppBar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Expanded(
                        child: Text(
                          'Outils de Table 🎲',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // Spacer for centering title
                    ],
                  ),
                ),

                // Glass TabBar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: GlassContainer(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withOpacity(0.05),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                    padding: const EdgeInsets.all(4),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: Colors.transparent,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white60,
                      labelPadding: EdgeInsets.zero,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        gradient: PyraTheme.purplePinkGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      tabs: const [
                        Tab(text: '🐺 Loup'),
                        Tab(text: '🔄 Uno'),
                        Tab(text: '🎩 Monop'),
                        Tab(text: '⏱️ Timer'),
                      ],
                    ),
                  ),
                ),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      _LoupGarouTool(),
                      _UnoHelperTool(),
                      _MonopolyJailTool(),
                      _TimesUpTimerTool(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. LOUP-GAROU ROLE DISTRIBUTOR
// ─────────────────────────────────────────────────────────────────────────────
class _LoupGarouTool extends StatefulWidget {
  const _LoupGarouTool();

  @override
  State<_LoupGarouTool> createState() => _LoupGarouToolState();
}

class _LoupGarouToolState extends State<_LoupGarouTool> {
  int _playerCount = 5;
  List<String> _assignedRoles = [];
  int _currentRevealIndex = 0;
  bool _isRevealed = false;

  void _generateRoles() {
    HapticFeedback.heavyImpact();
    final roles = <String>[];
    
    // Assure basic roles first
    roles.add('Loup-Garou 🐺');
    if (_playerCount >= 6) roles.add('Loup-Garou 🐺');
    roles.add('Voyante 🔮');
    if (_playerCount >= 5) roles.add('Sorcière 🧙‍♀️');
    if (_playerCount >= 7) roles.add('Cupidon 💘');
    
    // Fill remaining with Villagers
    while (roles.length < _playerCount) {
      roles.add('Villageois 🧑🌾');
    }

    // Shuffle roles
    roles.shuffle(Random());

    setState(() {
      _assignedRoles = roles;
      _currentRevealIndex = 0;
      _isRevealed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Text(
            'Distribuez secrètement les rôles pour votre partie de Loup-Garou.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 24),
          if (_assignedRoles.isEmpty) ...[
            // Setup Section
            GlassContainer(
              padding: const EdgeInsets.all(20),
              borderRadius: BorderRadius.circular(24),
              color: PyraTheme.bgCard.withOpacity(0.4),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              child: Column(
                children: [
                  const Text(
                    'Nombre de joueurs',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: PyraTheme.primaryPink, size: 32),
                        onPressed: _playerCount > 4 ? () => setState(() => _playerCount--) : null,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '$_playerCount',
                        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: PyraTheme.primaryCyan, size: 32),
                        onPressed: _playerCount < 12 ? () => setState(() => _playerCount++) : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  GradientButton(
                    label: 'Distribuer les Rôles 🎲',
                    gradient: PyraTheme.purplePinkGradient,
                    glow: PyraTheme.glowPurple,
                    onPressed: _generateRoles,
                  ),
                ],
              ),
            ),
          ] else ...[
            // Distribution workflow
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Joueur ${_currentRevealIndex + 1} sur $_playerCount',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      setState(() {
                        _isRevealed = !_isRevealed;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 200,
                      height: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: _isRevealed
                            ? PyraTheme.purplePinkGradient
                            : PyraTheme.mainGradient,
                        boxShadow: [
                          BoxShadow(
                            color: (_isRevealed ? PyraTheme.primaryPink : Colors.black).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        border: Border.all(
                          color: _isRevealed ? PyraTheme.primaryCyan : Colors.white24,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: _isRevealed
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Ton rôle :', style: TextStyle(color: Colors.white70, fontSize: 16)),
                                  const SizedBox(height: 16),
                                  Text(
                                    _assignedRoles[_currentRevealIndex],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  const Text('Re-clique pour masquer', style: TextStyle(color: Colors.white60, fontSize: 12)),
                                ],
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.lock_rounded, color: Colors.white60, size: 64),
                                  SizedBox(height: 16),
                                  Text(
                                    'Tape pour révéler',
                                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_isRevealed)
                    GradientButton(
                      label: _currentRevealIndex < _playerCount - 1 ? 'Suivant ➡️' : 'Terminer 🎉',
                      gradient: PyraTheme.purplePinkGradient,
                      glow: PyraTheme.glowPurple,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        if (_currentRevealIndex < _playerCount - 1) {
                          setState(() {
                            _currentRevealIndex++;
                            _isRevealed = false;
                          });
                        } else {
                          setState(() {
                            _assignedRoles.clear();
                          });
                        }
                      },
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. UNO TURN HELPER & SENS DU JEU
// ─────────────────────────────────────────────────────────────────────────────
class _UnoHelperTool extends StatefulWidget {
  const _UnoHelperTool();

  @override
  State<_UnoHelperTool> createState() => _UnoHelperToolState();
}

class _UnoHelperToolState extends State<_UnoHelperTool>
    with SingleTickerProviderStateMixin {
  bool _isClockwise = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _reverseDirection() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isClockwise = !_isClockwise;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Text(
            'Indicateur visuel pour suivre le sens de rotation de la table.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 48),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _reverseDirection,
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      final angle = _animationController.value * 2 * pi * (_isClockwise ? 1 : -1);
                      return Transform.rotate(
                        angle: angle,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: PyraTheme.festiveGradient,
                        boxShadow: [
                          BoxShadow(
                            color: PyraTheme.primaryPink.withOpacity(0.4),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.sync_rounded,
                          color: Colors.white,
                          size: 96,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  _isClockwise ? 'Sens Horaire 🔄' : 'Sens Anti-Horaire 🔃',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Cliquez sur la roue pour changer de sens',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. MONOPOLY PRISON ROLLER
// ─────────────────────────────────────────────────────────────────────────────
class _MonopolyJailTool extends StatefulWidget {
  const _MonopolyJailTool();

  @override
  State<_MonopolyJailTool> createState() => _MonopolyJailToolState();
}

class _MonopolyJailToolState extends State<_MonopolyJailTool> {
  int _die1 = 1;
  int _die2 = 1;
  bool _isRolling = false;
  String _resultText = '';
  Color _resultColor = Colors.white;

  void _rollDice() {
    if (_isRolling) return;
    HapticFeedback.lightImpact();
    setState(() {
      _isRolling = true;
      _resultText = 'Lancement... 🎲';
    });

    Timer(const Duration(milliseconds: 800), () {
      final random = Random();
      final d1 = random.nextInt(6) + 1;
      final d2 = random.nextInt(6) + 1;
      
      final isDouble = d1 == d2;

      setState(() {
        _die1 = d1;
        _die2 = d2;
        _isRolling = false;
        if (isDouble) {
          _resultText = 'DOUBLE ! Vous sortez de prison ! 🎉';
          _resultColor = PyraTheme.primaryGreen;
          HapticFeedback.heavyImpact();
        } else {
          _resultText = 'Pas de double... Essayez encore ! 😢';
          _resultColor = PyraTheme.primaryPink;
          HapticFeedback.mediumImpact();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Text(
            'Lancez les dés pour tenter un double et sortir de prison !',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 48),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildDie(_die1),
                    const SizedBox(width: 24),
                    _buildDie(_die2),
                  ],
                ),
                const SizedBox(height: 48),
                Text(
                  _resultText,
                  style: TextStyle(color: _resultColor, fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                GradientButton(
                  label: 'Lancer les dés 🎲',
                  gradient: PyraTheme.purplePinkGradient,
                  glow: PyraTheme.glowPurple,
                  onPressed: _rollDice,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDie(int value) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.5),
            blurRadius: 16,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$value',
          style: const TextStyle(color: Colors.black, fontSize: 36, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. TIME'S UP 30s TIMER
// ─────────────────────────────────────────────────────────────────────────────
class _TimesUpTimerTool extends StatefulWidget {
  const _TimesUpTimerTool();

  @override
  State<_TimesUpTimerTool> createState() => _TimesUpTimerToolState();
}

class _TimesUpTimerToolState extends State<_TimesUpTimerTool> {
  int _secondsLeft = 30;
  Timer? _timer;
  bool _isRunning = false;

  void _startTimer() {
    if (_isRunning) return;
    HapticFeedback.lightImpact();
    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        _stopTimer();
        HapticFeedback.vibrate();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    HapticFeedback.lightImpact();
    _stopTimer();
    setState(() {
      _secondsLeft = 30;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _secondsLeft / 30.0;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Text(
            'Minuteur de 30 secondes pour vos manches de Time\'s Up.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 48),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 10,
                        backgroundColor: Colors.white10,
                        color: progress > 0.3 ? PyraTheme.primaryCyan : PyraTheme.primaryPink,
                      ),
                    ),
                    Text(
                      '$_secondsLeft',
                      style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GradientButton(
                      label: _isRunning ? 'Pause ⏸️' : 'Démarrer ▶️',
                      gradient: PyraTheme.purplePinkGradient,
                      glow: PyraTheme.glowPurple,
                      onPressed: _isRunning ? _stopTimer : _startTimer,
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 36),
                      onPressed: _resetTimer,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
