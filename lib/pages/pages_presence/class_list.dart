import 'dart:ui' as ui;
import 'package:attendance/composants/button.dart';
import 'package:attendance/composants/colors.dart';
import 'package:attendance/composants/notification_ui.dart';
import 'package:attendance/providers/navigation_provider.dart';
import 'package:attendance/providers/navigation_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:attendance/providers/user_provider.dart';
import 'package:attendance/services/whatsapp_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:signature/signature.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClassList extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> students;
  final int idSeance;
  final String heureDebut;
  final String heureFin;
  final String niveauLabel;
  final String filiereLabel;
  final String ecueLabel;

  const ClassList({
    super.key,
    required this.students,
    required this.idSeance,
    required this.heureDebut,
    required this.heureFin,
    required this.niveauLabel,
    required this.filiereLabel,
    required this.ecueLabel,
  });

  @override
  ConsumerState<ClassList> createState() => _ClassListState();
}

class _ClassListState extends ConsumerState<ClassList> {
  late List<Map<String, dynamic>> students;
  bool showConfirmDialog = false;
  bool showSignatureDialog = false;
  bool _isSaving = false;
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
  );

  @override
  void initState() {
    super.initState();
    students = widget.students.map((s) => {...s, 'isAbsent': false}).toList();
  }

  void toggleDialog() {
    setState(() {
      showConfirmDialog = !showConfirmDialog;
    });
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_signatureController.isEmpty) {
      AppNotification.warning(
        "La signature du professeur est requise pour valider",
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final user = ref.read(userProvider);

      if (user == null) {
        throw Exception("Utilisateur non trouvé");
      }

      final signatureBytes = await _signatureController.toPngBytes();

      final presenceResponse = await supabase
          .from('presence')
          .insert({
            'id_seance': widget.idSeance,
            'id_surveillant': user.idSurveillant,
            'signature_prof': signatureBytes,
          })
          .select('id_presence')
          .single();

      final idPresence = presenceResponse['id_presence'];

      final detailsData = students
          .map(
            (s) => {
              'id_presence': idPresence,
              'matricule': s['matricule'],
              'statut': s['isAbsent'] ? 'absent' : 'present',
            },
          )
          .toList();

      await supabase.from('details_presence').insert(detailsData);

      final sessionDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

      String formatHour(String t) {
        final p = t.split(':');
        return '${p[0]}h${p[1]}';
      }

      final courseHour =
          '${formatHour(widget.heureDebut)}-${formatHour(widget.heureFin)}';

      final absentStudents = students
          .where((s) => s['isAbsent'] && s['parentPhoneNumber'] != 'N/A')
          .toList();

      debugPrint(
        "DEBUG: Nombre d'absents détectés avec numéro : ${absentStudents.length}",
      );

      final tasks = absentStudents.map((s) {
        // debugPrint("DEBUG: Tentative d'envoi pour ${s['nom']} au ${s['parentPhoneNumber']}");
        return WhatsAppService.sendAbsenceTemplate(
          phone: s['parentPhoneNumber'],
          studentName: '${s['nom']} ${s['prenom']}',
          dateAbsence: sessionDate,
          courseName: widget.ecueLabel,
          coursehour: courseHour,
        );
      });

      final results = await Future.wait(tasks);
      final failed = results.where((e) => e == false).length;

      if (!mounted) return;

      context.go('/success', extra: failed);
    } catch (e) {
      AppNotification.error("Erreur lors de l'enregistrement", error: e);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 50,
        elevation: 0,
        backgroundColor: Colors.transparent,

        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
            border: Border(
              bottom: BorderSide(color: AppColors.grey, width: 1.5),
            ),
          ),
        ),

        /// IMPORTANT
        titleSpacing: 0,

        title: SizedBox(
          width: double.infinity,
          height: 70,
          child: Row(
            children: [
              const SizedBox(width: 8),

              /// BOUTON RETOUR
              SizedBox(
                width: 38,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.white,
                    size: 28,
                  ),
                  onPressed: () {
                    ref.read(navigationTabProvider.notifier).state =
                        AppTab.presence;

                    context.go('/');
                  },
                ),
              ),

              const SizedBox(width: 8),

              /// TEXTE QUI PREND TOUT L’ESPACE
              Expanded(
                child: Row(
                  children: [
                    _headerChip(widget.niveauLabel),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: AppColors.white,
                      ),
                    ),

                    _headerChip(widget.filiereLabel),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: AppColors.white,
                      ),
                    ),

                    _headerChip(widget.ecueLabel),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _tableHead(),
                    Expanded(
                      child: Container(
                        color: AppColors.white,
                        child: students.isEmpty
                            ? _emptyState()
                            : ListView.separated(
                                itemCount: students.length + 1,
                                separatorBuilder: (c, i) =>
                                    const Divider(height: 1),
                                itemBuilder: (c, i) => i < students.length
                                    ? _studentRow(i)
                                    : _registerButton(),
                              ),
                      ),
                    ),
                  ],
                ),
                if (showConfirmDialog) _confirm(),
                if (showSignatureDialog) _signatureDialog(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerChip(String text) => Flexible(
    child: Text(
      text,
      style: const TextStyle(color: AppColors.white, fontSize: 16),
    ),
  );

  Widget _tableHead() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: const Row(
        children: [
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
              "ABSENT",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentRow(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              students[index]['nom'],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              students[index]['prenom'],
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Transform.scale(
                scale: 1.5,
                child: Checkbox(
                  value: students[index]['isAbsent'] ?? false,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(
                    () => students[index]['isAbsent'] = val ?? false,
                  ),
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
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: SizedBox(
            width: double.infinity,
            child: Button(label: "CONTINUER", onPressed: toggleDialog),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: AppColors.grey.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            "Aucun étudiant trouvé",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET DU DIALOGUE POUR LA CONFIRMATION  ---

  Widget _confirm() {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SizedBox.expand(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(
              sigmaX: 8,
              sigmaY: 8,
            ), // L'effet de flou
            child: Container(
              color: AppColors.black.withAlpha(51), // Teinte sombre légère
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: MediaQuery.of(context).size.height * 0.8,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white.withAlpha(
                      76,
                    ), // Fond semi-transparent
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

                      if (!students.any(
                        (student) => student['isAbsent'] == true,
                      ))
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
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
                            setState(() {
                              showConfirmDialog = false;
                              showSignatureDialog = true;
                            }); // Appelle le dialogue de signature
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

  Widget _signatureDialog() {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SizedBox.expand(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              color: Colors.black.withOpacity(0.4),
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.85,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Signature du Professeur",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                showSignatureDialog = false;
                              });
                            },
                            icon: const Icon(Icons.close, size: 30),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Émargement numérique requis pour valider la séance",
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Signature(
                              controller: _signatureController,
                              backgroundColor: Colors.grey.shade50,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _signatureController.clear(),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            label: const Text(
                              "Effacer",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: Button(
                          label: _isSaving
                              ? "Enregistrement..."
                              : "ENREGISTRER",
                          onPressed: _isSaving ? null : _handleSave,
                        ),
                      ),
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


