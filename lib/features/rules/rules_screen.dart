import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../shared/widgets/animated_background.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    onPressed: () => context.pop(),
                  ),
                  title: const Text('📖 Règles du jeu'),
                  centerTitle: true,
                  floating: true,
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _RuleCard(
                        emoji: '🔺',
                        title: 'La Pyramide',
                        content:
                            'Les cartes sont disposées en pyramide face cachée. La base comporte le plus de cartes et vaut 1 gorgée. Le sommet comporte 1 carte et vaut autant de gorgées que de rangées.',
                      ),
                      _RuleCard(
                        emoji: '🃏',
                        title: 'Distribution',
                        content:
                            'Chaque joueur reçoit 4 cartes face cachée. Ces cartes peuvent être utilisées pour envoyer des gorgées aux autres joueurs.',
                      ),
                      _RuleCard(
                        emoji: '🔄',
                        title: 'Déroulement',
                        content:
                            'On retourne les cartes de la pyramide rangée par rangée, de la base vers le sommet. Quand une carte est retournée, tout joueur qui prétend avoir la même valeur en main peut l\'envoyer à quelqu\'un.',
                      ),
                      _RuleCard(
                        emoji: '😈',
                        title: 'Le Bluff',
                        content:
                            'Tu peux poser une carte même si tu ne l\'as pas ! C\'est du bluff. La personne ciblée peut te "challenger". Si tu bluffais, tu bois le double. Si elle challange à tort, elle boit le double.',
                      ),
                      _RuleCard(
                        emoji: '🏆',
                        title: 'Fin de partie',
                        content:
                            'La partie se termine quand toutes les cartes de la pyramide ont été retournées. Le classement final affiche qui a bu le plus et qui est le meilleur bluffeur !',
                      ),
                      _RuleCard(
                        emoji: '⚡',
                        title: 'Variante : Super Challenge',
                        content:
                            'Activez cette option pour que le challenger parie le triple des gorgées en jeu. Pour les courageux seulement !',
                      ),
                      _RuleCard(
                        emoji: '💰',
                        title: 'Variante : Double Mise',
                        content:
                            'Tous les montants de gorgées en cas de bluff ou challenge sont doublés. Ambiance garantie !',
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
}

class _RuleCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String content;

  const _RuleCard({
    required this.emoji,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PyraTheme.bgCard.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: PyraTheme.primaryPurple,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: PyraTheme.textSecondary,
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }
}
