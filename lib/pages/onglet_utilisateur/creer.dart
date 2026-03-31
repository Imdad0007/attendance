import 'package:flutter/material.dart';
import 'package:attendance/composants/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:attendance/composants/button2.dart';

class Creer extends StatefulWidget {
  const Creer({super.key});

  @override
  State<Creer> createState() => _CreerState();
}

class _CreerState extends State<Creer> {
  final _formKey = GlobalKey<FormState>();

  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController(text: '22901');
  final _usernameController = TextEditingController();
  final _mdpController = TextEditingController();

  bool _loading = false;

  Future<void> _creerSurveillant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final password = _mdpController.text.trim();

      await Supabase.instance.client.from('surveillant').insert({
        'nom': _nomController.text.trim(),
        'prenom': _prenomController.text.trim(),
        'telephone': _telephoneController.text.trim(),
        'username': _usernameController.text.trim(),
        'mdp': password,
        'role': 'adjoint', // Forcer le rôle adjoint par défaut
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Surveillant créé avec succès !',
              style: TextStyle(color: AppColors.black, fontSize: 16),
            ),
            backgroundColor: AppColors.green,
            duration: Duration(seconds: 2),
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      String errorMsg = "Erreur lors de la création";
      if (e.toString().contains("duplicate key")) {
        errorMsg = "Ce nom d'utilisateur est déjà pris";
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
        title: const Text("Créer un compte",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
        backgroundColor: Color(0xFF2E7D32),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
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
                  if (value == null || value.isEmpty) return "Téléphone requis";
                  final regExp = RegExp(r'^22901\d{8}$');
                  if (!regExp.hasMatch(value)) return "Format invalide";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: "Nom d'utilisateur",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? "Nom d'utilisateur requis" : null,
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
              const SizedBox(height: 24),

              Button2(
                label: "Créer",
                gradient: AppColors.greenGradient,
                onPressed: _loading ? null : _creerSurveillant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _usernameController.dispose();
    _mdpController.dispose();
    super.dispose();
  }
}
