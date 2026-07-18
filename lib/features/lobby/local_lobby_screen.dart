import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/animated_background.dart';
import '../game/models/player_model.dart';
import '../game/models/game_state.dart';
import '../../shared/widgets/pulsar_button.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/game_mode_carousel.dart';

/// Lobby pour le mode local — saisie des joueurs
class LocalLobbyScreen extends ConsumerStatefulWidget {
  const LocalLobbyScreen({super.key});

  @override
  ConsumerState<LocalLobbyScreen> createState() => _LocalLobbyScreenState();
}

class _LocalLobbyScreenState extends ConsumerState<LocalLobbyScreen> {
  final List<Player> _players = [];
  final _nameController = TextEditingController();
  int _selectedEmojiIndex = 0;
  GameSettings _settings = const GameSettings();

  static const _maxPlayers = 8;
  static const _minPlayers = 2;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addPlayer() {
    final name = _nameController.text.trim();
    if (name.isEmpty || _players.length >= _maxPlayers) return;

    setState(() {
      _players.add(Player(
        name: name,
        emoji: kDefaultEmojis[_selectedEmojiIndex % kDefaultEmojis.length],
      ));
      _nameController.clear();
      _selectedEmojiIndex++;
    });
    HapticFeedback.lightImpact();
  }

  void _removePlayer(int index) {
    setState(() => _players.removeAt(index));
    HapticFeedback.lightImpact();
  }

  void _startGame() {
    if (_players.length < _minPlayers) return;
    HapticFeedback.heavyImpact();
    context.goNamed('localGame', extra: {
      'players': _players,
      'settings': _settings,
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canStart = _players.length >= _minPlayers;

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // AppBar
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    onPressed: () => context.pop(),
                  ),
                  title: Text(l10n.home_play_local),
                  centerTitle: true,
                  floating: true,
                ),

                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Saisie du nom
                      _buildAddPlayerSection(context, l10n),
                      const SizedBox(height: 24),

                      // Liste des joueurs
                      if (_players.isNotEmpty) ...[
                        Text(
                          l10n.lobby_players_title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 12),
                        ..._players.asMap().entries.map(
                              (e) => _buildPlayerTile(e.key, e.value)
                                  .animate()
                                  .fadeIn(
                                      delay: Duration(milliseconds: e.key * 80))
                                  .slideX(begin: 0.3),
                            ),
                        const SizedBox(height: 24),
                      ],

                      // Modes de Jeu
                      GameModeCarousel(
                        selectedMode: _settings.mode,
                        penaltyMode: _settings.penaltyMode,
                        replaceCardsWithPowers:
                            _settings.replaceCardsWithPowers,
                        onModeChanged: (mode) => setState(
                            () => _settings = _settings.copyWith(mode: mode)),
                        onPenaltyModeChanged: (pm) => setState(() =>
                            _settings =
                                _settings.copyWith(penaltyMode: pm)),
                        onReplaceCardsChanged: (v) => setState(() => _settings =
                            _settings.copyWith(replaceCardsWithPowers: v)),
                      ),
                      const SizedBox(height: 24),

                      // Paramètres
                      _buildSettings(context, l10n),
                      const SizedBox(height: 32),

                      // Bouton démarrer
                      AnimatedOpacity(
                        opacity: canStart ? 1.0 : 0.4,
                        duration: 300.ms,
                        child: PulsarButton(
                          text: canStart
                              ? l10n.lobby_start_game
                              : '${l10n.lobby_min_players} (${_players.length}/$_minPlayers)',
                          gradient: PyraTheme.purplePinkGradient,
                          onPressed: canStart ? _startGame : null,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPlayerSection(BuildContext context, AppLocalizations l10n) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      border: Border.all(color: PyraTheme.primaryPurple.withOpacity(0.3)),
      color: PyraTheme.bgCard,
      opacity: 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sélecteur d'emoji
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: kDefaultEmojis.length,
              itemBuilder: (context, i) {
                final isSelected =
                    i == (_selectedEmojiIndex % kDefaultEmojis.length);
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmojiIndex = i),
                  child: AnimatedContainer(
                    duration: 200.ms,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? PyraTheme.primaryPurple.withOpacity(0.3)
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? PyraTheme.primaryPurple
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Text(kDefaultEmojis[i],
                        style: const TextStyle(fontSize: 24)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Champ de saisie + bouton
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: l10n.lobby_player_name,
                    hintStyle: TextStyle(color: PyraTheme.textMuted),
                    filled: true,
                    fillColor: PyraTheme.bgDark.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: (_) => _addPlayer(),
                  textInputAction: TextInputAction.done,
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
                    boxShadow: PyraTheme.glowPurple,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerTile(int index, Player player) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: PyraTheme.bgCard,
      opacity: 0.4,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withOpacity(0.05)),
      child: Row(
        children: [
          Text(player.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              player.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          IconButton(
            icon: Icon(Icons.remove_circle_outline,
                color: PyraTheme.primaryPink.withOpacity(0.7)),
            onPressed: () => _removePlayer(index),
          ),
        ],
      ),
    );
  }

  Widget _buildSettings(BuildContext context, AppLocalizations l10n) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      color: PyraTheme.bgCard,
      opacity: 0.4,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.05)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.lobby_variants,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),

          // Taille de la pyramide
          Row(
            children: [
              Expanded(
                child: Text(l10n.lobby_pyramid_size,
                    style: Theme.of(context).textTheme.bodyLarge),
              ),
              for (int rows in [3, 4, 5])
                GestureDetector(
                  onTap: () => setState(
                      () => _settings = GameSettings(pyramidRows: rows)),
                  child: AnimatedContainer(
                    duration: 200.ms,
                    margin: const EdgeInsets.only(left: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: _settings.pyramidRows == rows
                          ? PyraTheme.purplePinkGradient
                          : null,
                      color: _settings.pyramidRows == rows
                          ? null
                          : PyraTheme.bgDark,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$rows',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          _ToggleSetting(
            label: l10n.lobby_bluff_mode,
            emoji: '😈',
            value: _settings.bluffEnabled,
            onChanged: (v) =>
                setState(() => _settings = GameSettings(bluffEnabled: v)),
          ),
          _ToggleSetting(
            label: l10n.lobby_double_bet,
            emoji: '💰',
            value: _settings.doubleBluff,
            onChanged: (v) =>
                setState(() => _settings = GameSettings(doubleBluff: v)),
          ),
          _ToggleSetting(
            label: l10n.lobby_super_challenge,
            emoji: '⚡',
            value: _settings.superChallenge,
            onChanged: (v) =>
                setState(() => _settings = GameSettings(superChallenge: v)),
          ),
        ],
      ),
    );
  }
}

class _ToggleSetting extends StatelessWidget {
  final String label;
  final String emoji;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleSetting({
    required this.label,
    required this.emoji,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: PyraTheme.primaryPurple,
          ),
        ],
      ),
    );
  }
}
