import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendance/providers/user_provider.dart';
import 'package:attendance/services/auth_service.dart';
import 'package:attendance/pages/login.dart';

class Profil extends ConsumerStatefulWidget {
  const Profil({super.key});
  @override
  ConsumerState<Profil> createState() => _ProfilState();
}

class _ProfilState extends ConsumerState<Profil> {
  final AuthService _authService = AuthService();

  // Couleur du fond synchronisée avec le footer (0xFFFDF7FF)
  final Color footerBgColor = const Color(0xFFFDF7FF);

  Future<void> _updateData(Map<String, dynamic> data) async {
    final user = ref.read(userProvider);
    if (user == null) return;

    // CORRECTION ICI : idSurveillant (vérifie ton modèle si c'est bien idSurveillant)
    final success = await _authService.updateUserField(
      user.idSurveillant!,
      data,
    );

    if (success) {
      ref.read(userProvider.notifier).state = user.copyWith(
        nom: data['nom'] ?? user.nom,
        prenom: data['prenom'] ?? user.prenom,
        telephone: data['telephone'] ?? user.telephone,
        mdp: data['mdp'] ?? user.mdp,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Modifié avec succès !"),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: footerBgColor, // Fond identique au footer
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 60),

            // --- CARTE GRISE ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 25),
              padding: const EdgeInsets.only(bottom: 25),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(35),
              ),
              child: Column(
                children: [
                  Transform.translate(
                    offset: const Offset(0, -35),
                    child: const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 75,
                        color: Color(0xFF003366),
                      ),
                    ),
                  ),
                  Text(
                    user?.prenom ?? "Utilisateur",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user?.role == 'general' ? "Admin" : "Surveillant",
                    style: TextStyle(color: Colors.grey[700], fontSize: 16),
                  ),
                  const Text(
                    "PIGIER-BENIN",
                    style: TextStyle(
                      color: Color(0xFF003366),
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // --- INPUT TÉLÉPHONE STYLE ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: InkWell(
                      onTap: () => _editPhoneDialog(user?.telephone),
                      child: Container(
                        height: 55,
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              color: Color(0xFF003366),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                user?.telephone ?? "Aucun numéro",
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            const Icon(
                              Icons.edit,
                              color: Colors.grey,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            _buildTile(
              Icons.person_outline,
              "Modifier mon nom",
              () => _editField("prenom", user?.prenom),
            ),
            _buildTile(
              Icons.lock_outline,
              "Changer le mot de passe",
              _editPasswordDialog,
            ),

            const SizedBox(height: 40),
            _logoutButton(),
          ],
        ),
      ),
    );
  }

  // --- LOGIQUE DES DIALOGUES ---

  void _editField(String key, String? currentValue) {
    TextEditingController controller = TextEditingController(
      text: currentValue,
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Modifier le $key"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "Votre $key"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () {
              _updateData({key: controller.text.trim()});
              Navigator.pop(ctx);
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  void _editPhoneDialog(String? initial) {
    TextEditingController controller = TextEditingController(text: initial);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Modifier le numéro"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: "Chiffres uniquement",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () {
              _updateData({'telephone': controller.text.trim()});
              Navigator.pop(ctx);
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  void _editPasswordDialog() {
    TextEditingController nPass = TextEditingController();
    TextEditingController cPass = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Changer le mot de passe"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nPass,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Nouveau mot de passe",
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: cPass,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Confirmer le mot de passe",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () {
              if (nPass.text == cPass.text && nPass.text.isNotEmpty) {
                _updateData({'mdp': nPass.text});
                Navigator.pop(ctx);
              } else if (nPass.text != cPass.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Les mots de passe diffèrent"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(IconData i, String t, VoidCallback o) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFE0E0E0),
      borderRadius: BorderRadius.circular(15),
    ),
    child: ListTile(
      leading: Icon(i, color: const Color(0xFF003366)),
      title: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: o,
    ),
  );

  Widget _logoutButton() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 25),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF003366),
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      onPressed: () {
        ref.read(userProvider.notifier).state = null;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (c) => const LoginPage()),
        );
      },
      child: const Text(
        "Déconnexion",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    ),
  );
}
