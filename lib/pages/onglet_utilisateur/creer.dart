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
  final _telephoneController = TextEditingController(text: '+229 01 ');
  final _usernameController = TextEditingController();
  final _mdpController = TextEditingController();

  bool _loading = false;

  Future<void> _creerSurveillant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
    });

    final password = _mdpController.text.trim();

    final response = await Supabase.instance.client.from('surveillant').insert({
      'nom': _nomController.text.trim(),
      'prenom': _prenomController.text.trim(),
      'telephone': _telephoneController.text.trim(),
      'username': _usernameController.text.trim(),
      'mdp': password,
    });

    setState(() {
      _loading = false;
    });

    if (mounted) {
      // Affiche le SnackBar
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

      // Retourne à la page précédente après un court délai pour voir le SnackBar
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Créer un compte"),
        backgroundColor: AppColors.green,
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
                  labelText: "Téléphone (+229 01 XX XX XX XX)",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Téléphone requis";
                  final regExp = RegExp(r'^\+229 01 \d{2} \d{2} \d{2} \d{2}$');
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
                    value == null || value.isEmpty ? "Username requis" : null,
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
