import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/security/screen_protection.dart';
import '../../shared/widgets/animated_background.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/pulsar_button.dart';
import '../game/models/card_model.dart';

class LiarGameScreen extends StatefulWidget {
  const LiarGameScreen({super.key});

  @override
  State<LiarGameScreen> createState() => _LiarGameScreenState();
}

class _LiarGameScreenState extends State<LiarGameScreen> {
  final List<String> _players = [];
  final _nameController = TextEditingController();
  bool _gameStarted = false;
  int _currentPlayerIndex = 0;
  int _roundNumber = 1;
  List<int> _scores = [];
  String? _lastClaim;
  int _lastClaimValue = 0;
  bool _showingCards = false;
  bool _roundOver = false;
  String _roundMessage = '';

  // Each player's hidden card value (1-13)
  List<int> _playerCards = [];

  @override
  void dispose() {
    ScreenProtection.disable();
    _nameController.dispose();
    super.dispose();
  }

  void _addPlayer() {
    final name = _nameController.text.trim();
    if (name.isEmpty || _players.length >= 8) return;
    setState(() {
      _players.add(name);
      _nameController.clear();
    });
    HapticFeedback.lightImpact();
  }

  void _startGame() {
    if (_players.length < 3) return;
    ScreenProtection.enable();
    setState(() {
      _gameStarted = true;
      _scores = List.filled(_players.length, 0);
      _startNewRound();
    });
    HapticFeedback.heavyImpact();
  }

  void _startNewRound() {
    final rng = Random();
    setState(() {
      _playerCards = List.generate(_players.length, (_) => rng.nextInt(13) + 1);
      _currentPlayerIndex = 0;
      _lastClaim = null;
      _lastClaimValue = 0;
      _showingCards = false;
      _roundOver = false;
      _roundMessage = '';
    });
  }

  void _makeClaim(int claimedValue) {
    if (claimedValue <= _lastClaimValue) return;
    setState(() {
      _lastClaim =
          '${_players[_currentPlayerIndex]} annonce : ${_cardName(claimedValue)}';
      _lastClaimValue = claimedValue;
      _currentPlayerIndex = (_currentPlayerIndex + 1) % _players.length;
    });
    HapticFeedback.lightImpact();
  }

  void _callLiar() {
    final accuserIndex = _currentPlayerIndex;
    final previousIndex =
        (accuserIndex - 1 + _players.length) % _players.length;
    final actualCard = _playerCards[previousIndex];
    final wasLying = actualCard < _lastClaimValue;

    setState(() {
      _roundOver = true;
      _showingCards = true;
      if (wasLying) {
        _scores[previousIndex] += 1;
        _roundMessage =
            '🎉 ${_players[accuserIndex]} a raison ! ${_players[previousIndex]} mentait ! (avait ${_cardName(actualCard)})';
      } else {
        _scores[accuserIndex] += 1;
        _roundMessage =
            '😅 ${_players[accuserIndex]} se trompe ! ${_players[previousIndex]} disait vrai ! (avait ${_cardName(actualCard)})';
      }
      _roundNumber++;
    });
    HapticFeedback.heavyImpact();
  }

  String _cardName(int value) {
    switch (value) {
      case 1:
        return 'As';
      case 11:
        return 'Valet';
      case 12:
        return 'Dame';
      case 13:
        return 'Roi';
      default:
        return '$value';
    }
  }

  bool get _isGameOver => _scores.any((s) => s >= 3);

  @override
  Widget build(BuildContext context) {
    if (!_gameStarted) return _buildSetup(context);
    if (_isGameOver) return _buildGameOver(context);
    return _buildGamePlay(context);
  }

  Widget _buildSetup(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(height: 16),
                  Text('Menteur 🃏',
                      style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 8),
                  const Text(
                    'Chaque joueur reçoit une carte cachée. Tour à tour, annoncez une valeur (en bluffant ou non). Le suivant peut accuser de mentir !',
                    style: TextStyle(color: PyraTheme.textMuted, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Nom du joueur',
                            hintStyle: TextStyle(color: PyraTheme.textMuted),
                            filled: true,
                            fillColor: PyraTheme.bgDark.withValues(alpha: 0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (_) => _addPlayer(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _addPlayer,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: PyraTheme.purplePinkGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child:
                              const Icon(Icons.add, color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _players.length,
                      itemBuilder: (ctx, i) => GlassContainer(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        borderRadius: BorderRadius.circular(12),
                        child: Row(
                          children: [
                            Text('${i + 1}.',
                                style:
                                    const TextStyle(color: PyraTheme.textMuted)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(_players[i],
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white38),
                              onPressed: () =>
                                  setState(() => _players.removeAt(i)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  PulsarButton(
                    text: _players.length >= 3
                        ? 'Commencer (${_players.length} joueurs)'
                        : 'Minimum 3 joueurs',
                    gradient: PyraTheme.purplePinkGradient,
                    onPressed: _players.length >= 3 ? _startGame : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamePlay(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Round $_roundNumber',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: const Icon(Icons.close, color: Colors.white54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Scores
                  GlassContainer(
                    padding: const EdgeInsets.all(12),
                    borderRadius: BorderRadius.circular(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _players.asMap().entries.map((e) {
                        final isCurrent = e.key == _currentPlayerIndex;
                        return Column(
                          children: [
                            Text(
                              e.value.substring(
                                  0, e.value.length > 4 ? 4 : e.value.length),
                              style: TextStyle(
                                color:
                                    isCurrent ? PyraTheme.primaryCyan : Colors.white70,
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_scores[e.key]}/3',
                              style: TextStyle(
                                color: _scores[e.key] >= 2
                                    ? PyraTheme.primaryPink
                                    : Colors.white54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_lastClaim != null)
                    Text(_lastClaim!,
                            style: const TextStyle(
                                color: PyraTheme.primaryYellow, fontSize: 16))
                        .animate()
                        .fadeIn()
                        .slideY(begin: -0.2),

                  const SizedBox(height: 16),

                  if (_roundOver) ...[
                    GlassContainer(
                      padding: const EdgeInsets.all(20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: PyraTheme.primaryPurple.withValues(alpha: 0.5)),
                      child: Column(
                        children: [
                          Text(_roundMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16)),
                          const SizedBox(height: 20),
                          PulsarButton(
                            text: 'Round suivant',
                            gradient: PyraTheme.purplePinkGradient,
                            onPressed: _startNewRound,
                          ),
                        ],
                      ),
                    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                  ] else ...[
                    // Current player's turn
                    Text(
                      "C'est au tour de ${_players[_currentPlayerIndex]}",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ta carte : ${_cardName(_playerCards[_currentPlayerIndex])}',
                      style: const TextStyle(
                          color: PyraTheme.primaryCyan, fontSize: 16),
                    ),
                    const SizedBox(height: 24),

                    // Claim buttons
                    if (_lastClaimValue > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: PulsarButton(
                          text: '🚨 MENTEUR !',
                          gradient: const LinearGradient(
                              colors: [Colors.red, Colors.deepOrange]),
                          onPressed: _callLiar,
                        ),
                      ),

                    const Text('Annonce une valeur :',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 12),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 4,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.5,
                        children: List.generate(13, (i) {
                          final value = i + 1;
                          final enabled = value > _lastClaimValue;
                          return GestureDetector(
                            onTap: enabled ? () => _makeClaim(value) : null,
                            child: AnimatedContainer(
                              duration: 200.ms,
                              decoration: BoxDecoration(
                                color: enabled
                                    ? PyraTheme.primaryPurple.withValues(alpha: 0.3)
                                    : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: enabled
                                      ? PyraTheme.primaryPurple
                                      : Colors.white12,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _cardName(value),
                                  style: TextStyle(
                                    color: enabled ? Colors.white : Colors.white30,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOver(BuildContext context) {
    final loserIndex = _scores.indexWhere((s) => s >= 3);
    final winnerIndex =
        _scores.indexWhere((s) => s == _scores.reduce(min));

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: GlassContainer(
                  padding: const EdgeInsets.all(32),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: PyraTheme.primaryYellow.withValues(alpha: 0.5)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 60)),
                      const SizedBox(height: 16),
                      const Text('Partie terminée !',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        '${_players[loserIndex]} a perdu ! 😵',
                        style: const TextStyle(
                            color: PyraTheme.primaryPink, fontSize: 18),
                      ),
                      const SizedBox(height: 24),
                      ..._players.asMap().entries.map((e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(e.value,
                                    style:
                                        const TextStyle(color: Colors.white)),
                                Text('${_scores[e.key]} fautes',
                                    style: TextStyle(
                                      color: _scores[e.key] >= 3
                                          ? PyraTheme.primaryPink
                                          : PyraTheme.primaryCyan,
                                      fontWeight: FontWeight.bold,
                                    )),
                              ],
                            ),
                          )),
                      const SizedBox(height: 32),
                      PulsarButton(
                        text: 'Rejouer',
                        gradient: PyraTheme.purplePinkGradient,
                        onPressed: () {
                          setState(() {
                            _roundNumber = 1;
                            _scores = List.filled(_players.length, 0);
                            _startNewRound();
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: const Text('Retour',
                            style: TextStyle(color: Colors.white54)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
