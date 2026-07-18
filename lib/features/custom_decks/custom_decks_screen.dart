import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app/theme.dart';
import '../../shared/widgets/animated_background.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/pulsar_button.dart';
import 'custom_deck_service.dart';

class CustomDecksScreen extends ConsumerStatefulWidget {
  const CustomDecksScreen({super.key});

  @override
  ConsumerState<CustomDecksScreen> createState() => _CustomDecksScreenState();
}

class _CustomDecksScreenState extends ConsumerState<CustomDecksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_ios,
                            color: Colors.white),
                      ),
                      Expanded(
                        child: Text(
                          'Decks Personnalisés',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(color: PyraTheme.primaryCyan),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),

                // Tab bar
                GlassContainer(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(4),
                  borderRadius: BorderRadius.circular(16),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: PyraTheme.purplePinkGradient,
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: PyraTheme.textSecondary,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Communauté'),
                      Tab(text: 'Mes Decks'),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 16),

                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _CommunityTab(),
                      _MyDecksTab(),
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

// ─── Community Tab ───────────────────────────────────────────────────────────
class _CommunityTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(communityDecksProvider);

    return decksAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: PyraTheme.primaryCyan),
      ),
      error: (e, _) => Center(
        child: Text('Erreur: $e',
            style: const TextStyle(color: PyraTheme.textSecondary)),
      ),
      data: (decks) {
        if (decks.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Aucun deck communautaire',
                        style: TextStyle(
                            color: PyraTheme.textSecondary, fontSize: 16))
                    .animate()
                    .fadeIn(),
                const SizedBox(height: 8),
                const Text('Sois le premier à en créer un !',
                        style: TextStyle(
                            color: PyraTheme.textMuted, fontSize: 14))
                    .animate()
                    .fadeIn(delay: 200.ms),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: decks.length,
          itemBuilder: (context, index) {
            final deck = decks[index];
            return _DeckCard(deck: deck, showCreator: true)
                .animate()
                .fadeIn(delay: Duration(milliseconds: 100 * index))
                .slideX(begin: 0.1);
          },
        );
      },
    );
  }
}

// ─── My Decks Tab ────────────────────────────────────────────────────────────
class _MyDecksTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(
        child: Text('Connecte-toi pour créer des decks',
            style: TextStyle(color: PyraTheme.textSecondary)),
      );
    }

    final decksAsync = ref.watch(myDecksProvider(user.uid));

    return decksAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: PyraTheme.primaryPurple),
      ),
      error: (e, _) => Center(
        child: Text('Erreur: $e',
            style: const TextStyle(color: PyraTheme.textSecondary)),
      ),
      data: (decks) {
        return Column(
          children: [
            // Create button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PulsarButton(
                text: '+ Créer un deck',
                gradient: PyraTheme.cyanGradient,
                onPressed: () => _showCreateDeckSheet(context, ref, user),
              ),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 16),

            // My decks list
            Expanded(
              child: decks.isEmpty
                  ? Center(
                      child: const Text(
                        'Tu n\'as pas encore créé de deck',
                        style: TextStyle(
                            color: PyraTheme.textSecondary, fontSize: 14),
                      ).animate().fadeIn(),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: decks.length,
                      itemBuilder: (context, index) {
                        final deck = decks[index];
                        return _DeckCard(deck: deck, showCreator: false)
                            .animate()
                            .fadeIn(
                                delay:
                                    Duration(milliseconds: 100 * index))
                            .slideX(begin: 0.1);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _showCreateDeckSheet(
      BuildContext context, WidgetRef ref, User user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateDeckSheet(user: user),
    );
  }
}

// ─── Deck Card Widget ────────────────────────────────────────────────────────
class _DeckCard extends ConsumerWidget {
  final CustomDeck deck;
  final bool showCreator;

  const _DeckCard({required this.deck, required this.showCreator});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalQuestions =
        deck.truths.length + deck.dares.length + deck.challenges.length;

    return GestureDetector(
      onTap: () => _showDeckPreview(context, ref),
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            // Emoji
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: PyraTheme.purplePinkGradient,
              ),
              child: Center(
                child: Text(deck.emoji,
                    style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deck.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (showCreator)
                    Text(
                      'par ${deck.creatorName}',
                      style: const TextStyle(
                          color: PyraTheme.textSecondary, fontSize: 12),
                    ),
                  Text(
                    '$totalQuestions questions',
                    style: const TextStyle(
                        color: PyraTheme.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),

            // Stats
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.download_rounded,
                        color: PyraTheme.primaryCyan, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${deck.downloads}',
                      style: const TextStyle(
                          color: PyraTheme.primaryCyan, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (i) {
                    return Icon(
                      i < deck.rating.round()
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: PyraTheme.primaryYellow,
                      size: 14,
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeckPreview(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: PyraTheme.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(deck.emoji, style: const TextStyle(fontSize: 36)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(deck.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900)),
                        Text('par ${deck.creatorName}',
                            style: const TextStyle(
                                color: PyraTheme.textSecondary,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    TabBar(
                      labelColor: PyraTheme.primaryCyan,
                      unselectedLabelColor: PyraTheme.textMuted,
                      indicatorColor: PyraTheme.primaryCyan,
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(
                            text:
                                'Vérités (${deck.truths.length})'),
                        Tab(text: 'Défis (${deck.dares.length})'),
                        Tab(
                            text:
                                'Challenges (${deck.challenges.length})'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _QuestionList(questions: deck.truths),
                          _QuestionList(questions: deck.dares),
                          _QuestionList(questions: deck.challenges),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Download button
            Padding(
              padding: const EdgeInsets.all(20),
              child: PulsarButton(
                text: 'Télécharger ce deck',
                gradient: PyraTheme.purplePinkGradient,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  ref
                      .read(customDeckServiceProvider)
                      .downloadDeck(deck.id);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Deck téléchargé !'),
                      backgroundColor: PyraTheme.primaryGreen,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Question List ───────────────────────────────────────────────────────────
class _QuestionList extends StatelessWidget {
  final List<String> questions;

  const _QuestionList({required this.questions});

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const Center(
        child: Text('Aucune question',
            style: TextStyle(color: PyraTheme.textMuted)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Text(
            questions[index],
            style:
                const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        );
      },
    );
  }
}

// ─── Create Deck Sheet ───────────────────────────────────────────────────────
class _CreateDeckSheet extends ConsumerStatefulWidget {
  final User user;

  const _CreateDeckSheet({required this.user});

  @override
  ConsumerState<_CreateDeckSheet> createState() => _CreateDeckSheetState();
}

class _CreateDeckSheetState extends ConsumerState<_CreateDeckSheet> {
  final _nameController = TextEditingController();
  final _truthController = TextEditingController();
  final _dareController = TextEditingController();
  final _challengeController = TextEditingController();

  String _selectedEmoji = '';
  final List<String> _truths = [];
  final List<String> _dares = [];
  final List<String> _challenges = [];
  bool _isSubmitting = false;

  static const _emojiOptions = [
    '🃏', '🎲', '🔥', '💀', '🎭', '🧠', '👑', '⚡',
    '🎯', '🍀', '🌶️', '🦁', '🐉', '🎪', '💎', '🚀',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _truthController.dispose();
    _dareController.dispose();
    _challengeController.dispose();
    super.dispose();
  }

  void _addQuestion(List<String> list, TextEditingController controller) {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    setState(() => list.add(text));
    controller.clear();
    HapticFeedback.lightImpact();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    if (_truths.isEmpty && _dares.isEmpty && _challenges.isEmpty) return;

    setState(() => _isSubmitting = true);

    final deck = CustomDeck(
      id: '',
      name: name,
      emoji: _selectedEmoji,
      creatorId: widget.user.uid,
      creatorName: widget.user.displayName ?? 'Anonyme',
      truths: _truths,
      dares: _dares,
      challenges: _challenges,
      createdAt: DateTime.now(),
    );

    await ref.read(customDeckServiceProvider).createDeck(deck);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deck créé avec succès !'),
          backgroundColor: PyraTheme.primaryGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: PyraTheme.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Créer un nouveau deck',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Deck name
                  _buildTextField(
                    controller: _nameController,
                    hint: 'Nom du deck',
                    icon: Icons.edit,
                  ),
                  const SizedBox(height: 16),

                  // Emoji picker
                  const Text('Emoji du deck',
                      style: TextStyle(
                          color: PyraTheme.textSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _emojiOptions.map((emoji) {
                      final isSelected = _selectedEmoji == emoji;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedEmoji = emoji),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: isSelected
                                ? PyraTheme.primaryPurple.withOpacity(0.3)
                                : Colors.white.withOpacity(0.05),
                            border: Border.all(
                              color: isSelected
                                  ? PyraTheme.primaryPurple
                                  : Colors.white.withOpacity(0.1),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(emoji,
                                style: const TextStyle(fontSize: 22)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Truths section
                  _buildQuestionSection(
                    title: 'Vérités',
                    color: PyraTheme.primaryCyan,
                    controller: _truthController,
                    questions: _truths,
                    onAdd: () =>
                        _addQuestion(_truths, _truthController),
                  ),
                  const SizedBox(height: 20),

                  // Dares section
                  _buildQuestionSection(
                    title: 'Défis',
                    color: PyraTheme.primaryOrange,
                    controller: _dareController,
                    questions: _dares,
                    onAdd: () => _addQuestion(_dares, _dareController),
                  ),
                  const SizedBox(height: 20),

                  // Challenges section
                  _buildQuestionSection(
                    title: 'Challenges',
                    color: PyraTheme.primaryPink,
                    controller: _challengeController,
                    questions: _challenges,
                    onAdd: () =>
                        _addQuestion(_challenges, _challengeController),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Submit button
          Padding(
            padding: const EdgeInsets.all(20),
            child: PulsarButton(
              text: _isSubmitting ? 'Création...' : 'Publier le deck',
              gradient: PyraTheme.purplePinkGradient,
              onPressed: _isSubmitting ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: PyraTheme.textMuted),
          prefixIcon: Icon(icon, color: PyraTheme.textSecondary),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildQuestionSection({
    required String title,
    required Color color,
    required TextEditingController controller,
    required List<String> questions,
    required VoidCallback onAdd,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(title,
                style: TextStyle(
                    color: color, fontSize: 16, fontWeight: FontWeight.w800)),
            const Spacer(),
            Text('${questions.length}',
                style: TextStyle(color: color, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Ajouter une question...',
                    hintStyle:
                        const TextStyle(color: PyraTheme.textMuted, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  onSubmitted: (_) => onAdd(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.add_rounded, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
        if (questions.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...questions.asMap().entries.map((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        setState(() => questions.removeAt(entry.key)),
                    child: Icon(Icons.close_rounded,
                        color: color.withOpacity(0.7), size: 18),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}
