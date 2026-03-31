import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendance/composants/colors.dart';
import 'package:attendance/composants/text_field.dart';
import 'package:attendance/pages/main_navigation_bar.dart';
import 'package:attendance/composants/button.dart';
import 'package:attendance/providers/user_provider.dart';
import 'package:attendance/services/auth_service.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar("Veuillez remplir tous les champs.", AppColors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Appel au service d'authentification
      final authResult = await _authService.signIn(username, password);

      if (!mounted) return;

      if (authResult.user != null) {
        // Sauvegarde de l'utilisateur dans le provider Riverpod
        ref.read(userProvider.notifier).state = authResult.user;

        // Navigation vers l'écran principal
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationBar()),
        );
      } else {
        // Gestion des erreurs de connexion
        String message = "Erreur de connexion.";
        Color color = AppColors.red;

        if (authResult.status == AuthStatus.invalidCredentials) {
          message = "Nom d'utilisateur ou mot de passe incorrect.";
        } else if (authResult.status == AuthStatus.noInternet) {
          message = "Vérifiez votre connexion internet.";
          color = AppColors.orange;
        }

        _showSnackBar(message, color);
      }
    } catch (e) {
      _showSnackBar("Une erreur technique est survenue.", AppColors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 16)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset('assets/img/attendance.png', height: 120),
                  const SizedBox(height: 40),
                  const Text(
                    'Connexion',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Utilise exactement le nom de ton composant (Textfield ou MyTextField)
                  Textfield(
                    controller: _usernameController,
                    hintText: "Nom d'utilisateur",
                    obscureText: false,
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 20),
                  Textfield(
                    controller: _passwordController,
                    hintText: "Mot de passe",
                    obscureText: true,
                    icon: Icons.lock_outline,
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Mot de passe oublié ?',
                        style: TextStyle(
                          color: AppColors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Button(label: "Se connecter", onPressed: _handleLogin),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
