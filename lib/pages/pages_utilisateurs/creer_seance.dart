import 'package:flutter/material.dart';
import 'package:attendance/composants/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:attendance/composants/button2.dart';
import 'package:attendance/composants/notification_ui.dart';

class Creer extends StatefulWidget {
  const Creer({super.key});

  @override
  State<Creer> createState() => _CreerState();
}

class _CreerState extends State<Creer> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController(text: '22901');
  final _mdpController = TextEditingController();
  String _selectedRole = 'surveillant'; // Rôle par défaut

  bool _loading = false;

  void _clearFields() {
    _formKey.currentState?.reset();

    _emailController.clear();
    _nomController.clear();
    _prenomController.clear();
    _telephoneController.text = '22901';
    _mdpController.clear();

    setState(() {
      _selectedRole = 'surveillant';
    });
  }

  Future<void> _creerSurveillant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final supabase = Supabase.instance.client;

    try {
      final email = _emailController.text.trim();
      final password = _mdpController.text.trim();
      final nom = _nomController.text.trim();
      final prenom = _prenomController.text.trim();
      final telephone = _telephoneController.text.trim();

      /// 1️⃣ Sauvegarder la session ADMIN
      final currentSession = supabase.auth.currentSession;

      if (currentSession == null) {
        throw Exception("Session admin introuvable");
      }

      final adminRefreshToken = currentSession.refreshToken;

      ///  Création du nouvel utilisateur

      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'nom': nom,
          'prenom': prenom,
          'telephone': telephone,
          'role': _selectedRole,
        },
      );

      if (authResponse.user == null) {
        throw Exception("Création utilisateur échouée");
      }

      ///  RESTAURER SESSION ADMIN
      await supabase.auth.setSession(adminRefreshToken!);

      /// 4️Feedback UI

      if (mounted) {
        AppNotification.success("Compte $_selectedRole créé avec succès !");
        _clearFields();
      }
    } catch (e) {
      String errorMsg = "Impossible de créer l'utilisateur";

      if (e is AuthException) {
        errorMsg = e.message;
      }

      if (mounted) {
        AppNotification.error(errorMsg, error: e);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
        title: const Text(
          "Créer un compte",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return "Email requis";
                      if (!value.contains('@')) return "Email invalide";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nomController,
                    decoration: const InputDecoration(
                      labelText: "Nom",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? "Nom requis" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _prenomController,
                    decoration: const InputDecoration(
                      labelText: "Prénoms",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? "Prénom requis" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _telephoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "Téléphone (22901XXXXXXXX)",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return "Téléphone requis";
                      final regExp = RegExp(r'^22901\d{8}$');
                      if (!regExp.hasMatch(value)) return "Format invalide";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _mdpController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Mot de passe",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? "Mot de passe requis"
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // --- SÉLECTEUR DE RÔLE ---
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    dropdownColor: const Color(0xFFF0F2F5),

                    decoration: const InputDecoration(
                      labelText: "Rôle",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'surveillant',
                        child: Text("Surveillant"),
                      ),
                      DropdownMenuItem(
                        value: 'admin',
                        child: Text("Administrateur"),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRole = val);
                    },
                  ),

                  const SizedBox(height: 24),

                  Button2(
                    label: "CRÉE",
                    gradient: AppColors.greenGradient,
                    onPressed: _loading ? null : _creerSurveillant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _mdpController.dispose();
    super.dispose();
  }
}
