import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app/theme.dart';
import '../../shared/widgets/glass_container.dart';
import '../../shared/widgets/pulsar_button.dart';
import 'auth_service.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  Future<void> _submit() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;
    if (!_isLogin && _nameController.text.isEmpty) return;

    setState(() => _isLoading = true);
    final authService = ref.read(authServiceProvider);

    try {
      if (_isLogin) {
        await authService.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await authService.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          pseudo: _nameController.text.trim(),
        );
      }
      // authStateChangesProvider handles redirection
    } catch (e) {
      _showErrorSnackBar(_translateAuthError(e));
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    final authService = ref.read(authServiceProvider);
    try {
      await authService.signInWithGoogle();
    } catch (e) {
      _showErrorSnackBar(_translateAuthError(e));
    }
  }

  Future<void> _signInWithApple() async {
    final authService = ref.read(authServiceProvider);
    try {
      await authService.signInWithApple();
    } catch (e) {
      _showErrorSnackBar(_translateAuthError(e));
    }
  }

  String _translateAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found': return 'Aucun utilisateur trouvé avec cet email.';
        case 'wrong-password': return 'Mot de passe incorrect.';
        case 'email-already-in-use': return 'Cet email est déjà utilisé par un autre compte.';
        case 'weak-password': return 'Le mot de passe doit contenir au moins 6 caractères.';
        case 'invalid-email': return 'L\'adresse email n\'est pas valide.';
        default: return 'Une erreur est survenue lors de l\'authentification.';
      }
    }
    return 'Erreur inattendue. Veuillez réessayer.';
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          innerGlow: true,
          padding: const EdgeInsets.all(24),
          border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_rounded, color: Colors.redAccent, size: 48)
                .animate().shake(duration: 400.ms),
              const SizedBox(height: 16),
              const Text('Erreur', style: TextStyle(color: Colors.redAccent, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 24),
              PulsarButton(
                text: 'OK',
                gradient: const LinearGradient(colors: [Colors.red, Colors.redAccent]),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateChangesProvider);

    // Auto-redirect
    ref.listen(authStateChangesProvider, (previous, next) {
      if (next.value != null) {
        context.goNamed('home');
      }
    });

    return Scaffold(
      backgroundColor: PyraTheme.bgDark, // Fond très sombre
      body: Stack(
        children: [
          // 1. Décoration de fond (gradient radial)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: PyraTheme.mainGradient,
              ),
            ),
          ),
          Positioned(
            top: -100,
            left: -50,
            child: _buildGlow(PyraTheme.primaryPink.withOpacity(0.3)),
          ),
          Positioned(
            bottom: 100,
            right: -100,
            child: _buildGlow(PyraTheme.primaryPurple.withOpacity(0.3)),
          ),

          // 2. Image 3D au top -> Remplacé par des éléments du jeu
          Positioned(
            top: 60,
            left: 30,
            child: _buildFloatingIcon('🃏', -0.2),
          ),
          Positioned(
            top: 140,
            right: 40,
            child: _buildFloatingIcon('🍻', 0.15),
          ),
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'La Pyramide',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(color: PyraTheme.primaryPink.withOpacity(0.5), blurRadius: 20),
                    ],
                  ),
                ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.2),
                const SizedBox(height: 8),
                Text(
                  'Prépare-toi à prendre',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
              ],
            ),
          ),

          // 3. Panneau Glassmorphism du bas
          Align(
            alignment: Alignment.bottomCenter,
            child: SingleChildScrollView(
              child: GlassContainer(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(32),
                innerGlow: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                        // Titre
                        Text(
                          _isLogin ? 'Bon retour !' : 'Créer un compte',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isLogin ? 'Heureux de te revoir parmi nous' : 'Crée ton compte et rejoins la partie',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Formulaire
                        if (!_isLogin) ...[
                          _buildInputLabel('Pseudo'),
                          _buildTextField(
                            controller: _nameController,
                            icon: Icons.person_outline,
                            hint: '@tonpseudo',
                          ),
                          const SizedBox(height: 16),
                        ],

                        _buildInputLabel('Email'),
                        _buildTextField(
                          controller: _emailController,
                          icon: Icons.mail_outline,
                          hint: 'tonemail@gmail.com',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        _buildInputLabel('Mot de passe'),
                        _buildTextField(
                          controller: _passwordController,
                          icon: Icons.key_outlined,
                          hint: '••••••••',
                          isPassword: true,
                          obscureText: _obscurePassword,
                          onToggleObscure: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                        
                        if (_isLogin)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: const Text('Mot de passe oublié ?', style: TextStyle(color: PyraTheme.textMuted, fontSize: 12)),
                            ),
                          )
                        else
                          const SizedBox(height: 24),

                        // Bouton principal
                        SizedBox(
                          width: double.infinity,
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator(color: PyraTheme.primaryPink))
                              : PulsarButton(
                                  text: _isLogin ? 'Se connecter' : 'S\'inscrire',
                                  gradient: PyraTheme.purplePinkGradient,
                                  onPressed: _submit,
                                ),
                        ),

                        const SizedBox(height: 24),
                        
                        // Toggle state
                        Center(
                          child: GestureDetector(
                            onTap: _toggleMode,
                            child: RichText(
                              text: TextSpan(
                                text: _isLogin ? 'Pas encore de compte ? ' : 'Déjà un compte ? ',
                                style: TextStyle(color: Colors.white.withOpacity(0.6)),
                                children: [
                                  TextSpan(
                                    text: _isLogin ? 'S\'inscrire' : 'Se connecter',
                                    style: const TextStyle(color: PyraTheme.primaryPink, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Ou continuer avec
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                _isLogin ? 'Ou se connecter avec' : 'Ou s\'inscrire avec',
                                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Boutons sociaux
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildSocialButton('assets/images/google_logo.png', Icons.g_mobiledata, Colors.white, onPressed: _signInWithGoogle),
                            if (Theme.of(context).platform == TargetPlatform.iOS || Theme.of(context).platform == TargetPlatform.macOS) ...[
                              const SizedBox(width: 16),
                              _buildSocialButton('assets/images/apple_logo.png', Icons.apple, Colors.black, backgroundColor: Colors.white, onPressed: _signInWithApple),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ).animate().slideY(begin: 0.2, duration: 600.ms, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }

  Widget _buildGlow(Color color) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 100,
            spreadRadius: 50,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingIcon(String emoji, double rotation) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Text(
          emoji,
          style: TextStyle(fontSize: 32, color: Colors.white.withOpacity(0.9)),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        label,
        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleObscure,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return GlassContainer(
      blur: 8.0,
      opacity: 0.1,
      padding: EdgeInsets.zero,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5)),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.white.withOpacity(0.5)),
                  onPressed: onToggleObscure,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildSocialButton(String assetPath, IconData fallbackIcon, Color iconColor, {Color? backgroundColor, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(20),
        innerGlow: true,
        child: Icon(fallbackIcon, color: iconColor, size: 32),
      ),
    );
  }
}
