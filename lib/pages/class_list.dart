import 'dart:ui' as ui;
import 'package:attendance/composants/button.dart';
import 'package:attendance/composants/colors.dart';
import 'package:attendance/composants/notification_ui.dart';
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
  final int idEcue;
  final int idProf;
  final int idSalle;
  final TimeOfDay heureDebut;
  final TimeOfDay heureFin;
  final String niveauLabel;
  final String filiereLabel;
  final String ecueLabel;

  const ClassList({
    super.key,
    required this.students,
    required this.idEcue,
    required this.idProf,
    required this.idSalle,
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
      AppNotification.warning("La signature du professeur est requise pour valider");
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
      if (signatureBytes == null) {
        throw Exception("Erreur signature");
      }

      final heureDebutStr =
          '${widget.heureDebut.hour.toString().padLeft(2, '0')}:${widget.heureDebut.minute.toString().padLeft(2, '0')}';
      final heureFinStr =
          '${widget.heureFin.hour.toString().padLeft(2, '0')}:${widget.heureFin.minute.toString().padLeft(2, '0')}';
      final now = DateTime.now();

      final seanceResponse = await supabase
          .from('seance')
          .insert({
            'id_ecue': widget.idEcue,
            'id_prof': widget.idProf,
            'id_salle': widget.idSalle,
            'heure_debut': heureDebutStr,
            'heure_fin': heureFinStr,
            'date_seance': now.toIso8601String().split('T')[0],
          })
          .select('id_seance')
          .single();

      final idSeance = seanceResponse['id_seance'];

      final presenceResponse = await supabase
          .from('presence')
          .insert({
            'id_seance': idSeance,
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

      final sessionDate = DateFormat('dd/MM/yyyy').format(now);
      final courseHour =
          '${widget.heureDebut.hour.toString().padLeft(2, '0')}h${widget.heureDebut.minute.toString().padLeft(2, '0')}-${widget.heureFin.hour.toString().padLeft(2, '0')}h${widget.heureFin.minute.toString().padLeft(2, '0')}';

      final notificationTasks = <Future<bool>>[];
      for (final s in students) {
        if (s['isAbsent'] && s['parentPhoneNumber'] != 'N/A') {
          notificationTasks.add(
            WhatsAppService.sendAbsenceTemplate(
              phone: s['parentPhoneNumber'],
              studentName: '${s['nom']} ${s['prenom']}',
              dateAbsence: sessionDate,
              courseName: widget.ecueLabel,
              coursehour: courseHour,
            ),
          );
        }
      }

      final notificationResults = notificationTasks.isEmpty
          ? const <bool>[]
          : await Future.wait(notificationTasks);
      final failedNotifications =
          notificationResults.where((sent) => !sent).length;

      if (mounted) {
        context.go('/success', extra: failedNotifications);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppNotification.error("Erreur lors de l'enregistrement de la présence", error: e);
      }
    }
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
                    child: students.isEmpty
                        ? _emptyState()
                        : ListView.separated(
                            itemCount: students.length + 1,
                            separatorBuilder: (c, i) =>
                                const Divider(height: 1),
                            itemBuilder: (c, i) =>
                                i < students.length ? _studentRow(i) : _registerButton(),
                          ),
                  ),
                ),
              ],
            ),
            if (showConfirmDialog) _confirmDialog(),
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
        border: const Border(
          bottom: BorderSide(color: AppColors.grey, width: 1.5),
        ),
      ),
      child: Row(
        children: [
          _headerChip(widget.niveauLabel),
          const Icon(Icons.chevron_right, size: 20, color: AppColors.white),
          _headerChip(widget.filiereLabel),
          const Icon(Icons.chevron_right, size: 20, color: AppColors.white),
          _headerChip(widget.ecueLabel),
        ],
      ),
    );
  }

  Widget _headerChip(String text) => Flexible(
        child: Text(
          text,
          style: const TextStyle(color: AppColors.white, fontSize: 16),
          overflow: TextOverflow.ellipsis,
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
                  value: students[index]['isAbsent'] as bool,
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
            color: AppColors.grey.withValues(alpha: 0.3),
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

  Widget _confirmDialog() {
    return SizedBox.expand(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          color: Colors.black.withValues(alpha: 0.4),
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
                        onPressed: toggleDialog,
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
    );
  }
}
