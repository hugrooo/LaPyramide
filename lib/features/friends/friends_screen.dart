import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../shared/widgets/animated_background.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/avatar_with_border.dart';
import 'friend_service.dart';

final friendsProvider = StreamProvider.autoDispose<List<FriendProfile>>((ref) {
  return ref.watch(friendServiceProvider).getFriends();
});

final friendRequestsProvider =
    StreamProvider.autoDispose<List<FriendProfile>>((ref) {
  return ref.watch(friendServiceProvider).getPendingRequests();
});

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final _searchController = TextEditingController();
  List<FriendProfile> _searchResults = [];
  bool _isSearching = false;

  void _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    final results =
        await ref.read(friendServiceProvider).searchUsers(query.trim());
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsProvider);
    final requestsAsync = ref.watch(friendRequestsProvider);

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 20),
                      const Text(
                        'Amis',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Barre de recherche
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Chercher un ami...',
                      hintStyle:
                          TextStyle(color: Colors.white.withOpacity(0.5)),
                      prefixIcon: const Icon(Icons.search, color: Colors.white),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: _searchUsers,
                  ),
                ),
                const SizedBox(height: 16),

                // Contenu
                Expanded(
                  child: _searchController.text.isNotEmpty
                      ? _buildSearchResults()
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          children: [
                            // Requêtes en attente
                            requestsAsync.when(
                              data: (requests) {
                                if (requests.isEmpty)
                                  return const SizedBox.shrink();
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Demandes reçues',
                                      style: TextStyle(
                                          color: PyraTheme.primaryPink,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    ...requests
                                        .map((req) => _buildRequestTile(req)),
                                    const SizedBox(height: 24),
                                  ],
                                );
                              },
                              loading: () => const Center(
                                  child: CircularProgressIndicator()),
                              error: (err, stack) => Text('Erreur: $err'),
                            ),

                            // Liste d'amis
                            const Text(
                              'Mes Amis',
                              style: TextStyle(
                                  color: PyraTheme.primaryCyan,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            friendsAsync.when(
                              data: (friends) {
                                if (friends.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text(
                                      'Aucun ami pour le moment. Recherche des pseudos pour les ajouter !',
                                      style:
                                          TextStyle(color: PyraTheme.textMuted),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                }
                                return Column(
                                  children: friends
                                      .map((f) => _buildFriendTile(f))
                                      .toList(),
                                );
                              },
                              loading: () => const Center(
                                  child: CircularProgressIndicator()),
                              error: (err, stack) => Text('Erreur: $err'),
                            ),
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

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
          child: CircularProgressIndicator(color: PyraTheme.primaryPink));
    }
    if (_searchResults.isEmpty) {
      return const Center(
        child: Text('Aucun résultat trouvé.',
            style: TextStyle(color: PyraTheme.textMuted)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return GestureDetector(
          onTap: () => context.pushNamed('publicProfile', pathParameters: {'uid': user.id}),
          child: GlassCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                AvatarWithBorder(
                  emoji: user.emoji ?? '👤',
                  photoUrl: user.photoUrl,
                  borderType: user.selectedBorder,
                  size: 40,
                  showLevel: false,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(user.name,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.person_add, color: PyraTheme.primaryCyan),
                  onPressed: () {
                    ref.read(friendServiceProvider).sendFriendRequest(user.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Demande envoyée à ${user.name} !')),
                    );
                  },
                ),
              ],
            ),
          ),
        ).animate().fadeIn().slideY(begin: 0.1);
      },
    );
  }

  Widget _buildRequestTile(FriendProfile req) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: GestureDetector(
        onTap: () => context.pushNamed('publicProfile', pathParameters: {'uid': req.id}),
        child: GlassCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              AvatarWithBorder(
                emoji: req.emoji ?? '👤',
                photoUrl: req.photoUrl,
                borderType: req.selectedBorder,
                size: 40,
                showLevel: false,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(req.name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon:
                    const Icon(Icons.check_circle, color: PyraTheme.primaryCyan),
                onPressed: () {
                  ref.read(friendServiceProvider).acceptFriendRequest(req.id);
                },
              ),
              IconButton(
                icon: const Icon(Icons.cancel, color: PyraTheme.primaryPink),
                onPressed: () {
                  ref.read(friendServiceProvider).declineFriendRequest(req.id);
                },
              ),
            ],
          ),
        ),
      ).animate().fadeIn().slideX(),
    );
  }

  Widget _buildFriendTile(FriendProfile friend) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: GestureDetector(
        onTap: () => context.pushNamed('publicProfile', pathParameters: {'uid': friend.id}),
        child: GlassCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              AvatarWithBorder(
                emoji: friend.emoji ?? '👤',
                photoUrl: friend.photoUrl,
                borderType: friend.selectedBorder,
                size: 40,
                showLevel: false,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(friend.name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.person_remove_rounded, color: PyraTheme.primaryPink),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: PyraTheme.bgSurface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('Supprimer cet ami ?', style: TextStyle(color: Colors.white)),
                      content: Text('Voulez-vous vraiment retirer ${friend.name} de votre liste d\'amis ?', style: const TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
                        ),
                        TextButton(
                          onPressed: () {
                            ref.read(friendServiceProvider).removeFriend(friend.id);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${friend.name} a été retiré de vos amis.')),
                            );
                          },
                          child: const Text('Supprimer', style: TextStyle(color: PyraTheme.primaryPink, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ).animate().fadeIn().slideY(begin: 0.1),
    );
  }
}
