import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';
import '../../features/game/models/game_state.dart';
import 'glass_container.dart';

class GameModeCarousel extends StatelessWidget {
  final GameMode selectedMode;
  final bool replaceCardsWithPowers;
  final ValueChanged<GameMode> onModeChanged;
  final ValueChanged<bool> onReplaceCardsChanged;

  const GameModeCarousel({
    super.key,
    required this.selectedMode,
    required this.replaceCardsWithPowers,
    required this.onModeChanged,
    required this.onReplaceCardsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text('Mode de jeu', style: Theme.of(context).textTheme.headlineMedium),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildModeCard(
                context,
                mode: GameMode.classic,
                title: 'Classique',
                description: 'Le jeu Pyra original. Du bluff, de la stratégie, et beaucoup de pénalités.',
                icon: '🃏',
                color: PyraTheme.primaryPurple,
              ),
              const SizedBox(width: 16),
              _buildModeCard(
                context,
                mode: GameMode.powers,
                title: 'Pouvoirs Spéciaux',
                description: 'Des cartes uniques (Bouclier, Miroir...) pour retourner la partie !',
                icon: '⚡',
                color: PyraTheme.primaryPink,
              ),
              const SizedBox(width: 16),
              _buildModeCard(
                context,
                mode: GameMode.secretMissions,
                title: 'Missions Secrètes',
                description: 'Accomplis ton objectif caché sans te faire repérer par les autres !',
                icon: '🕵️',
                color: PyraTheme.primaryOrange,
              ),
              const SizedBox(width: 16),
              _buildModeCard(
                context,
                mode: GameMode.miniGames,
                title: 'Mini-Jeux',
                description: 'Des cartes spéciales déclenchent des mini-jeux délirants pendant la partie.',
                icon: '🎲',
                color: PyraTheme.primaryYellow,
              ),
              const SizedBox(width: 16),
              _buildModeCard(
                context,
                mode: GameMode.truthOrSip,
                title: 'Vérité ou Pénalité 🎭',
                description: 'Les têtes révélées forcent le joueur à répondre à une question ou prendre !',
                icon: '🤫',
                color: PyraTheme.primaryCyan,
              ),
              const SizedBox(width: 16),
              _buildModeCard(
                context,
                mode: GameMode.speedRun,
                title: 'Speed-Run ⏱️',
                description: 'Pas le temps de réfléchir ! Décision en 5s max sinon punition de 2 pénalités !',
                icon: '🚀',
                color: Colors.redAccent,
              ),
            ],
          ),
        ),
        if (selectedMode == GameMode.powers) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GlassContainer(
              padding: const EdgeInsets.all(16),
              color: PyraTheme.bgCard,
              opacity: 0.5,
              border: Border.all(color: PyraTheme.primaryPink.withOpacity(0.5)),
              child: Row(
                children: [
                  const Text('🔄', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Remplacer certaines cartes classiques par les pouvoirs',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  Switch.adaptive(
                    value: replaceCardsWithPowers,
                    activeColor: PyraTheme.primaryPink,
                    onChanged: onReplaceCardsChanged,
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.2),
          ),
        ],
      ],
    );
  }

  Widget _buildModeCard(
    BuildContext context, {
    required GameMode mode,
    required String title,
    required String description,
    required String icon,
    required Color color,
  }) {
    final isSelected = selectedMode == mode;

    return GestureDetector(
      onTap: () => onModeChanged(mode),
      child: AnimatedContainer(
        duration: 300.ms,
        curve: Curves.easeOutBack,
        width: 160,
        transform: Matrix4.identity()..scale(isSelected ? 1.05 : 0.95),
        child: GlassContainer(
          padding: const EdgeInsets.all(16),
          color: isSelected ? color : PyraTheme.bgCard,
          opacity: isSelected ? 0.3 : 0.6,
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PyraTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
