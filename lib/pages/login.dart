import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:attendance/composants/colors.dart';
import 'package:attendance/composants/text_field.dart';
import 'package:attendance/pages/main_navigation_bar.dart';
import 'package:attendance/composants/button.dart';
import 'package:attendance/providers/user_provider.dart';
import 'package:attendance/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir tous les champs."),
          backgroundColor: AppColors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authResult = await _authService.signIn(username, password);

      if (!mounted) return;

      // Cas de succes
      if (authResult.user != null) {
        // Set the user in the provider
        Provider.of<UserProvider>(context, listen: false).setUser(authResult.user!);
        
        // Naviguer vers l'ecran principale
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationBar()),
        );
        return;
      }

      // Error case
      String? errorMessage;
      Color errorColor = AppColors.red;

      switch (authResult.status) {
        case AuthStatus.invalidCredentials:
          errorMessage = "Nom d'utilisateur ou mot de passe incorrect.";
          break;
        case AuthStatus.noInternet:
          errorMessage = "Connexion impossible. Vérifiez votre réseau.";
          errorColor = AppColors.orange;
          break;
        default: 
          errorMessage = "Une erreur inattendue est survenue.";
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: errorColor,
        ),
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Une erreur technique est survenue."),
          backgroundColor: AppColors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.white,
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
                  // Logo
                  Image.asset('assets/img/attendance.png', height: 120),

                  const SizedBox(height: 40),

                  // Titre
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

                  // Champs de saisie
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

                  // Mot de passe oublié
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Mot de passe oublié ?',
                        style: TextStyle(
                          color: AppColors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Bouton de connexion
                  _isLoading
                      ? Button(label: "Connexion...", onPressed: null)
                      : Button(label: "Se connecter", onPressed: _handleLogin),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
