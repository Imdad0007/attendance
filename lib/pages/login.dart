import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/composants/text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark,
      ),
      
      child: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SafeArea(
                child: SingleChildScrollView(
                  // pour éviter les problèmes de clavier
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60), // Espacement depuis le haut

                      Center(
                        child: Image.asset(
                          // Meilleure approche pour les images
                          'assets/img/university.png',
                          height: 100,
                          width: 100,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.school,
                                size: 100, color: Colors.grey);
                          },
                        ),
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        'Connexion',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 40),

                      const Textfield(
                        hintText: "Nom d'utilisateur",
                        obscureText: false,
                        icon: Icons.person_outline,
                      ),

                      const SizedBox(height: 20),

                      const Textfield(
                        hintText: "Mot de passe",
                        obscureText: true,
                        icon: Icons.lock_outline,
                      ),

                      const SizedBox(height: 15),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                //print('Forgot password pressed');
                              },
                              child: const Text(
                                'Mot de passe oublié ?',
                                style: TextStyle(
                                  color: Color(
                                      0xFF8E2DE2), // Utilisez votre couleur violette
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 10,
                          shadowColor: const Color(0xFF8E2DE2).withAlpha(76),
                        ),
                        child: RepaintBoundary(
                          child: Ink(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF8E2DE2),
                                  Color(0xFF4A00E0),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              child: const Center(
                                child: Text(
                                  'Se connecter',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 50), // Espacement en bas
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}