import 'dart:async';

import 'package:attendance/composants/button.dart';
import 'package:attendance/composants/colors.dart';
import 'package:attendance/composants/text_field.dart';
import 'package:attendance/services/auth_service.dart';
import 'package:attendance/composants/notification_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:attendance/providers/navigation_provider.dart';
import 'package:attendance/providers/user_provider.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  StreamSubscription<AuthState>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange
        .listen((data) {
          if (data.event == AuthChangeEvent.passwordRecovery) {
            _showResetPasswordDialog();
          }
        });
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validation simple
    if (email.isEmpty || password.isEmpty) {
      AppNotification.error("Veuillez remplir tous les champs.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Note : On passe .text car votre AuthService attend probablement des String
      // et non les contrôleurs directement.
      final authResult = await _authService.signIn(email, password);

      if (!mounted) return;

      if (authResult.status == AuthStatus.onlineSuccess &&
          authResult.user != null) {
        // ... (le code de succès reste identique)
        ref.read(userProvider.notifier).state = authResult.user;
        final String role = authResult.user!.role.toLowerCase();
        if (role == 'admin') {
          ref.read(navigationTabProvider.notifier).state = AppTab.dashboard;
        } else {
          ref.read(navigationTabProvider.notifier).state = AppTab.home;
        }
        context.go('/');
      } else {
        // Gestion précise des messages d'erreurs
        switch (authResult.status) {
          case AuthStatus.invalidCredentials:
            AppNotification.error("Email ou mot de passe incorrect.");
            break;
          case AuthStatus.noInternet:
            AppNotification.error(
              authResult.message ?? "Pas de connexion internet.",
            );
            break;
          case AuthStatus.accountDeactivated:
            AppNotification.warning(
              authResult.message ?? "Votre compte a été désactivé.",
            );
            break;
          case AuthStatus.emailNotConfirmed:
            AppNotification.warning("Veuillez confirmer votre adresse email.");
            break;
          default:
            AppNotification.error(
              authResult.message ?? "Erreur de connexion inconnue.",
            );
        }
      }
    } catch (e) {
      AppNotification.error("Une erreur technique est survenue.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Réinitialisation"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Entrez votre email pour recevoir un lien de réinitialisation.",
            ),
            const SizedBox(height: 15),
            Textfield(
              controller: resetEmailController,
              hintText: "Email",
              obscureText: false,
              icon: Icons.email_outlined,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isEmpty) return;

              final success = await _authService.sendPasswordResetEmail(email);
              if (!mounted) return;
              if (!dialogContext.mounted) return;

              Navigator.pop(dialogContext);
              if (success) {
                AppNotification.success("Email de réinitialisation envoyé !");
              } else {
                AppNotification.error("Erreur lors de l'envoi de l'email.");
              }
            },
            child: const Text("Envoyer"),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog() {
    final newPasswordController = TextEditingController();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Nouveau mot de passe"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Veuillez définir votre nouveau mot de passe."),
            const SizedBox(height: 15),
            Textfield(
              controller: newPasswordController,
              hintText: "Nouveau mot de passe",
              obscureText: true,
              icon: Icons.lock_outline,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              final newPassword = newPasswordController.text.trim();
              if (newPassword.isEmpty) return;

              try {
                await Supabase.instance.client.auth.updateUser(
                  UserAttributes(password: newPassword),
                );
                if (!mounted) return;
                if (!dialogContext.mounted) return;

                Navigator.pop(dialogContext);
                AppNotification.success(
                  "Mot de passe mis à jour. Connectez-vous.",
                );
              } catch (e) {
                if (!mounted) return;
                AppNotification.error(
                  "Erreur lors de la mise à jour.",
                  error: e,
                );
              }
            },
            child: const Text("Enregistrer"),
          ),
        ],
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
                  Textfield(
                    controller: _emailController,
                    hintText: "Email",
                    obscureText: false,
                    icon: Icons.email_outlined,
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
                      onPressed: _showForgotPasswordDialog,
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
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    Button(label: "SE CONNECTER", onPressed: _handleLogin),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
