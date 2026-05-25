import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../shared/widgets/animated_background.dart';
import '../../shared/widgets/gradient_button.dart';
import 'auth_service.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Écoute l'état d'authentification
    final authState = ref.watch(authStateChangesProvider);

    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          
          SafeArea(
            child: Column(
              children: [
                // Bouton retour
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: authState.when(
                      data: (user) {
                        // Si l'utilisateur est déjà connecté, on affiche un bouton pour continuer
                        // Ou on le redirige automatiquement. Pour l'instant on affiche un état.
                        if (user != null) {
                          // Redirection automatique via un post-frame callback
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (context.mounted) {
                              context.pushReplacementNamed('onlineLobby');
                            }
                          });
                          return const Center(child: CircularProgressIndicator(color: PyraTheme.primaryPink));
                        }
                        
                        // Sinon, on affiche les options de connexion
                        return _buildLoginOptions(context, ref);
                      },
                      loading: () => const Center(child: CircularProgressIndicator(color: PyraTheme.primaryPurple)),
                      error: (err, stack) => Center(
                        child: Text('Erreur: $err', style: const TextStyle(color: Colors.red)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginOptions(BuildContext context, WidgetRef ref) {
    final authService = ref.read(authServiceProvider);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Mode en Ligne',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Connecte-toi pour jouer avec tes amis à distance et sauvegarder tes statistiques.',
          textAlign: TextAlign.center,
          style: TextStyle(color: PyraTheme.textSecondary, fontSize: 16),
        ),
        const SizedBox(height: 48),

        // Bouton Google
        GradientButton(
          label: 'Connexion avec Google',
          gradient: const LinearGradient(
            colors: [Color(0xFF4285F4), Color(0xFF34A853)],
          ),
          glow: [],
          onPressed: () async {
            HapticFeedback.mediumImpact();
            try {
              await authService.signInWithGoogle();
              // La redirection se fera automatiquement via l'écouteur authState
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur : ${e.toString()}')),
                );
              }
            }
          },
        ),
        const SizedBox(height: 16),

        // Bouton Invité
        TextButton(
          onPressed: () => _showGuestDialog(context, authService),
          child: const Text(
            'Jouer en tant qu\'invité',
            style: TextStyle(color: PyraTheme.textMuted, fontSize: 16),
          ),
        ),
      ],
    );
  }

  Future<void> _showGuestDialog(BuildContext context, AuthService authService) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PyraTheme.bgCard,
        title: const Text('Pseudo Invité', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Ton pseudo...',
            hintStyle: TextStyle(color: PyraTheme.textMuted),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: PyraTheme.primaryPurple)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: PyraTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: PyraTheme.primaryPink),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Jouer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      if (!context.mounted) return;
      HapticFeedback.lightImpact();
      try {
        await authService.signInAnonymously(pseudo: result);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur : $e')),
          );
        }
      }
    }
  }
}
