import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:attendance/composants/colors.dart';
import 'package:attendance/composants/button.dart';
import 'package:provider/provider.dart';
import 'package:attendance/providers/user_provider.dart';
import 'package:attendance/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:attendance/services/whatsapp_service.dart';
import 'package:intl/intl.dart';

class ClassList extends StatefulWidget {
  final List<Map<String, dynamic>> students;
  final int idEcue;
  final TimeOfDay heureDebut;
  final TimeOfDay heureFin;
  final String niveauLabel;
  final String filiereLabel;
  final String coursLabel;

  const ClassList({
    super.key,
    required this.students,
    required this.idEcue,
    required this.heureDebut,
    required this.heureFin,
    required this.niveauLabel,
    required this.filiereLabel,
    required this.coursLabel,
  });

  @override
  State<ClassList> createState() => _ClassListState();
}

class _ClassListState extends State<ClassList> {
  late List<Map<String, dynamic>> students;

  final TextEditingController _passwordController = TextEditingController();
  bool showConfirmDialog = false;

  @override
  void initState() {
    super.initState();
    // Initialize the local 'students' state with the passed data and add the 'isAbsent' flag.
    students = widget.students.map((s) => {...s, 'isAbsent': false}).toList();
  }

  void toggleDialog() {
    setState(() {
      showConfirmDialog = !showConfirmDialog;
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  // Fonction pour afficher le dialogue de confirmation de mot de passe
  void _showPasswordVerification(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final authService = AuthService();
      final supabase = Supabase.instance.client;

      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),

        // ================= TITLE =================
        title: Row(
          children: const [

            SizedBox(width: 10),
            Text(
              "Vérification requise",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        // ================= CONTENT =================
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Veuillez confirmer votre mot de passe pour valider l'enregistrement.",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: "Mot de passe",
                prefixIcon: const Icon(Icons.lock),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),

        // ================= ACTIONS =================
        actions: [
          SizedBox(
            height: 42,
            child: TextButton(
              onPressed: () {
                _passwordController.clear();
                Navigator.pop(dialogContext);
              },
              style: TextButton.styleFrom(           
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text("Annuler", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.black),),
            ),
          ),

          SizedBox(
            height: 42,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              // ================= LOGIQUE METIER =================
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                final dialogNavigator = Navigator.of(dialogContext);

                final String? username =
                    userProvider.user?.username;

                if (username == null) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text("Utilisateur non trouvé"),
                      backgroundColor: AppColors.red,
                    ),
                  );
                  dialogNavigator.pop();
                  return;
                }

                final AuthResult result = await authService.signIn(
                  username,
                  _passwordController.text,
                );

                if (!mounted) return;

                if (result.status == AuthStatus.onlineSuccess) {
                  try {
                    // ====== PREPARATION ======
                    final idSurveillant =
                        userProvider.user!.idSurveillant;

                    final heureDebutStr =
                        '${widget.heureDebut.hour.toString().padLeft(2, '0')}:${widget.heureDebut.minute.toString().padLeft(2, '0')}';

                    final heureFinStr =
                        '${widget.heureFin.hour.toString().padLeft(2, '0')}:${widget.heureFin.minute.toString().padLeft(2, '0')}';

                    final now = DateTime.now();
                    final dateSeanceStr =
                        now.toIso8601String();

                    // ====== INSERT SEANCE ======
                    final seanceResponse = await supabase
                        .from('seance')
                        .insert({
                          'id_ecue': widget.idEcue,
                          'id_surveillant': idSurveillant,
                          'heure_debut': heureDebutStr,
                          'heure_fin': heureFinStr,
                          'date_seance': dateSeanceStr,
                        })
                        .select('id_seance')
                        .single();

                    final idSeance =
                        seanceResponse['id_seance'];

                    // ====== INSERT PRESENCE ======
                    final presenceData =
                        students.map((student) {
                      return {
                        'id_seance': idSeance,
                        'matricule': student['matricule'],
                        'statut': student['isAbsent']
                            ? 'absent'
                            : 'present',
                      };
                    }).toList();

                    await supabase
                        .from('presence')
                        .insert(presenceData);

                    // ====== WHATSAPP ======
                    final sessionDate =
                        DateFormat('dd/MM/yyyy')
                            .format(now);

                    final coursehour =
                        '${widget.heureDebut.hour.toString().padLeft(2, '0')}h${widget.heureDebut.minute.toString().padLeft(2, '0')}'
                        '-${widget.heureFin.hour.toString().padLeft(2, '0')}h${widget.heureFin.minute.toString().padLeft(2, '0')}';

                    for (final student in students) {
                      if (student['isAbsent'] &&
                          student['parentPhoneNumber'] !=
                              'N/A') {
                        WhatsAppService
                            .sendAbsenceTemplate(
                          phone: student['parentPhoneNumber'],
                          studentName:
                              '${student['nom']} ${student['prenom']}',
                          dateAbsence: sessionDate,
                          courseName: widget.coursLabel,
                          coursehour: coursehour,
                        );
                      }
                    }

                    // ====== UI FEEDBACK ======
                    dialogNavigator.pop();
                    toggleDialog();
                    _passwordController.clear();

                    messenger
                        .showSnackBar(
                          const SnackBar(
                            content: Text(
                                "Enregistrement validé !",
                                style: TextStyle(
                                    color: AppColors.black,
                                    fontSize: 16,)),
                            backgroundColor: AppColors.green,
                          ),
                        )
                        .closed
                        .then((_) {
                      navigator.pop();
                    });
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(
                        content:
                            Text("Erreur d'enregistrement", style: TextStyle(fontSize: 16),),
                        backgroundColor: AppColors.red,
                      ),
                    );
                  }
                } else if (result.status ==
                    AuthStatus.invalidCredentials) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text("Mot de passe incorrect", style: TextStyle(fontSize: 16),),
                      backgroundColor: AppColors.red,
                    ),
                  );
                } else {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text("Erreur de connexion", style: TextStyle(fontSize: 16),),
                      backgroundColor: AppColors.red,
                    ),
                  );
                }
              },

              child: const Text(
                "Valider",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.white),
              ),
            ),
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,

      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _header(),
                _tableHead(),
                Expanded(
                  child: Container(
                    color: AppColors.white,
                    child: ListView.separated(
                      itemCount: students.length + 1,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        if (index < students.length) {
                          return _studentRow(index);
                        } else {
                          return _registerButton();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),

            if (showConfirmDialog) _confirm(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        border: Border(bottom: BorderSide(color: AppColors.grey, width: 1.5)),
      ),
      child: Row(
        children: [
          Flexible(
            child: Text(
              widget.niveauLabel,
              style: const TextStyle(color: AppColors.white, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.chevron_right, size: 20, color: AppColors.white),
          Flexible(
            child: Text(
              widget.filiereLabel,
              style: const TextStyle(color: AppColors.white, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.chevron_right, size: 20, color: AppColors.white),
          Flexible(
            child: Text(
              widget.coursLabel,
              style: const TextStyle(color: AppColors.white, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHead() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      decoration: BoxDecoration(gradient: AppColors.primaryGradient),

      child: Row(
        children: const [
          Expanded(
            flex: 3,
            child: Text(
              "NOM",
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              "PRÉNOMS",
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "STATUT",
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentRow(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              students[index]['nom'],
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              students[index]['prenom'],
              style: TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Transform.scale(
                scale: 1.5,
                child: Checkbox(
                  value: students[index]['isAbsent'],
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() => students[index]['isAbsent'] = val);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _registerButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 300,
          ), // Empêche le bouton d'être trop large
          child: SizedBox(
            width: double.infinity,
            child: Button(label: "Enregistrer", onPressed: toggleDialog),
          ),
        ),
      ),
    );
  }

  // --- WIDGET DU DIALOGUE FLOTTANT  ---

  Widget _confirm() {
    return SizedBox.expand(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), // L'effet de flou
        child: Container(
          color: AppColors.black.withAlpha(51), // Teinte sombre légère
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white.withAlpha(76), // Fond semi-transparent
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.white.withAlpha(51)),
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: toggleDialog,
                      child: const Icon(
                        Icons.cancel_outlined,
                        color: AppColors.black,
                        size: 35,
                      ),
                    ),
                  ),

                  if (!students.any((student) => student['isAbsent'] == true))
                    const Center(
                      child: Text(
                        "AUCUNE ABSENCE",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    )
                  else
                    const Center(
                      child: Text(
                        "LES ABSENTS :",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),

                  Expanded(
                    child: ListView(
                      children: students
                          .where((s) => s['isAbsent'])
                          .map(
                            (s) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                "- ${s['nom']}  ${s['prenom']}",
                                style: const TextStyle(
                                  color: AppColors.black,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _dialogButton("Confirmer", Icons.check, () {
                        // ACTION CONFIRMER
                        _showPasswordVerification(
                          context,
                        ); // Appelle le dialogue de vérification
                      }),
                      _dialogButton("Annuler", Icons.cancel, () {
                        toggleDialog(); // ACTION ANNULER
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialogButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: const BoxDecoration(
          color: AppColors.blue,
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: AppColors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
