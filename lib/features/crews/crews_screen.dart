import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../shared/widgets/animated_background.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/pulsar_button.dart';
import '../auth/auth_service.dart';
import 'crew_service.dart';

class CrewsScreen extends ConsumerStatefulWidget {
  const CrewsScreen({super.key});

  @override
  ConsumerState<CrewsScreen> createState() => _CrewsScreenState();
}

class _CrewsScreenState extends ConsumerState<CrewsScreen> {
  final _nameController = TextEditingController();
  String _selectedEmoji = '🔥';

  final _emojis = ['🔥', '⚡', '🎯', '👑', '💀', '🦁', '🐉', '🎲'];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showCreateDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: PyraTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Créer un Crew',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            // Emoji picker
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _emojis.map((e) {
                  final isSelected = _selectedEmoji == e;
                  return GestureDetector(
                    onTap: () {
                      setDialogState(() => _selectedEmoji = e);
                      setState(() {});
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? PyraTheme.primaryPurple.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: isSelected
                                ? PyraTheme.primaryPurple
                                : Colors.white12),
                      ),
                      child:
                          Center(child: Text(e, style: const TextStyle(fontSize: 22))),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Nom du crew',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            PulsarButton(
              text: 'Créer',
              gradient: PyraTheme.purplePinkGradient,
              onPressed: () async {
                if (_nameController.text.trim().isEmpty) return;
                final uid = ref.read(authStateChangesProvider).value?.uid;
                if (uid == null) return;
                await ref.read(crewServiceProvider).createCrew(
                      name: _nameController.text.trim(),
                      emoji: _selectedEmoji,
                      creatorId: uid,
                    );
                _nameController.clear();
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ],
        ),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authStateChangesProvider).value?.uid ?? '';
    final crewsAsync = ref.watch(crewsProvider(uid));

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text('Mes Crews',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: -0.2),

                Expanded(
                  child: crewsAsync.when(
                    data: (crews) {
                      if (crews.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('👥',
                                  style: TextStyle(fontSize: 64)),
                              const SizedBox(height: 16),
                              const Text('Aucun crew',
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 16)),
                              const SizedBox(height: 8),
                              const Text(
                                  'Crée un crew pour jouer avec tes amis !',
                                  style: TextStyle(
                                      color: Colors.white30, fontSize: 13)),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: crews.length,
                        itemBuilder: (ctx, i) {
                          final crew = crews[i];
                          return _buildCrewCard(crew, i);
                        },
                      );
                    },
                    loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: PyraTheme.primaryPurple)),
                    error: (e, _) => Center(
                        child: Text('Erreur: $e',
                            style: const TextStyle(color: Colors.red))),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: PulsarButton(
                    text: 'Créer un Crew',
                    icon: Icons.group_add_rounded,
                    gradient: PyraTheme.purplePinkGradient,
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _showCreateDialog();
                    },
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrewCard(CrewData crew, int index) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: PyraTheme.primaryPurple.withValues(alpha: 0.3)),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: PyraTheme.primaryPurple.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
                child: Text(crew.emoji, style: const TextStyle(fontSize: 28))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(crew.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.people_rounded,
                        color: Colors.white38, size: 14),
                    const SizedBox(width: 4),
                    Text('${crew.memberCount} membres',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12)),
                    const SizedBox(width: 12),
                    const Icon(Icons.sports_esports_rounded,
                        color: Colors.white38, size: 14),
                    const SizedBox(width: 4),
                    Text('${crew.gamesPlayed} parties',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: Colors.white24, size: 14),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX(begin: 0.1);
  }
}
