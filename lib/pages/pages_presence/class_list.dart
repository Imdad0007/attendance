import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:attendance/composants/button.dart';
import 'package:attendance/composants/colors.dart';
import 'package:attendance/composants/notification_ui.dart';
import 'package:attendance/config/adaptive_layout.dart';
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

  // Multi-step signature state
  int _signatureStep = 1; // 1: Surveillant, 2: Délégué, 3: Professeur
  Uint8List? _signatureSurveillant;
  Uint8List? _signatureDelegue;
  Uint8List? _signatureProf;

  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
  );

  final ScrollController _scrollController = ScrollController();

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
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSignatureNext() async {
    if (_isSaving) return;

    final bool isRequired = _signatureStep == 1 || _signatureStep == 2;

    if (isRequired && _signatureController.isEmpty) {
      String role = _signatureStep == 1 ? "surveillant" : "délégué";
      AppNotification.warning("La signature du $role est requise");
      return;
    }

    final bytes = await _signatureController.toPngBytes();

    setState(() {
      if (_signatureStep == 1) {
        _signatureSurveillant = bytes;
        _signatureStep = 2;
        _signatureController.clear();
      } else if (_signatureStep == 2) {
        _signatureDelegue = bytes;
        _signatureStep = 3;
        _signatureController.clear();
      } else {
        _signatureProf = bytes;
        _handleSave();
      }
    });
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final user = ref.read(userProvider);

      if (user == null) {
        throw Exception("Utilisateur non trouvé");
      }

      // Vérifier si la présence existe déjà pour cette séance (idempotence)
      final existing = await supabase
          .from('presence')
          .select('id_presence')
          .eq('id_seance', widget.idSeance)
          .maybeSingle();

      if (existing != null) {
        AppNotification.warning(
          "La présence pour cette séance a déjà été enregistrée.",
        );
        _redirectToSuccess(0);
        return;
      }

      final presenceResponse = await supabase
          .from('presence')
          .insert({
            'id_seance': widget.idSeance,
            'id_surveillant': user.idSurveillant,
            'signature_surveillant': _signatureSurveillant,
            'signature_delegue': _signatureDelegue,
            'signature_prof': _signatureProf,
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

      final sessionDate = DateFormat('dd / MM / yyyy').format(DateTime.now());

      String formatHour(String t) {
        final p = t.split(':');
        return '${p[0]}h${p[1]}';
      }

      final courseHour =
          '${formatHour(widget.heureDebut)} - ${formatHour(widget.heureFin)}';

      final absentStudents = students
          .where((s) => s['isAbsent'] && (s['parentPhoneNumbers'] as List).isNotEmpty)
          .toList();

      final List<Future<bool>> tasks = [];
      for (final s in absentStudents) {
        final List<String> phoneNumbers = List<String>.from(s['parentPhoneNumbers']);
        for (final phone in phoneNumbers) {
          tasks.add(
            WhatsAppService.sendAbsenceTemplate(
              phone: phone,
              studentName: '${s['nom']} ${s['prenom']}',
              dateAbsence: sessionDate,
              courseName: widget.ecueLabel,
              coursehour: courseHour,
            ),
          );
        }
      }

      final results = await Future.wait(tasks);
      final failed = results.where((e) => e == false).length;

      if (!mounted) return;
      _redirectToSuccess(failed);
    } catch (e) {
      AppNotification.error("Erreur lors de l'enregistrement");
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _redirectToSuccess(int failed) {
    if (!mounted) return;

    // Fermer les dialogues avant la redirection
    setState(() {
      showConfirmDialog = false;
      showSignatureDialog = false;
    });

    if (useMainLayoutRail(context)) {
      ref
          .read(adaptiveNavigationProvider.notifier)
          .state = AdaptiveNavigationState(
        page: AdaptivePage.successRegistration,
        extra: failed,
      );
    } else {
      context.go('/success', extra: failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final useAdaptiveNavigation = useMainLayoutRail(context);

    return Scaffold(
      backgroundColor: AppColors.bg,

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
                    ref.read(adaptiveNavigationProvider.notifier).state =
                        const AdaptiveNavigationState.none();

                    if (!useAdaptiveNavigation) {
                      context.go('/');
                    }
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
    return SizedBox.expand(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          color: AppColors.black.withAlpha(51),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white.withAlpha(76),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.white.withAlpha(51)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        onPressed: toggleDialog,
                        icon: const Icon(Icons.cancel_outlined, size: 30),
                      ),
                    ),
                    Text(
                      !students.any((s) => s['isAbsent'] == true)
                          ? "AUCUNE ABSENCE"
                          : "LES ABSENTS :",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Flexible(
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          scrollbarTheme: ScrollbarThemeData(
                            thumbColor: WidgetStateProperty.all(Colors.black),
                          ),
                        ),
                        child: Scrollbar(
                          controller: _scrollController,
                          thumbVisibility: true,
                          child: ListView(
                            controller: _scrollController,
                            shrinkWrap: true,
                            padding: const EdgeInsets.only(right: 15),
                            children: students
                                .where((s) => s['isAbsent'])
                                .map(
                                  (s) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Text(
                                      "- ${s['nom']}  ${s['prenom']}",
                                      style: const TextStyle(
                                        fontSize: 17,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _dialogButton("Confirmer", Icons.check, () {
                          setState(() {
                            showConfirmDialog = false;
                            showSignatureDialog = true;
                            _signatureStep = 1; // Reset to first step
                            _signatureController.clear();
                          });
                        }),
                        _dialogButton("Annuler", Icons.cancel, toggleDialog),
                      ],
                    ),
                  ],
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
    String title = "";
    String subTitle = "";
    String buttonLabel = "";

    if (_signatureStep == 1) {
      title = "Signature du Surveillant";
      subTitle = "La signature du surveillant est requise";
      buttonLabel = "CONTINUER";
    } else if (_signatureStep == 2) {
      title = "Signature du Délégué";
      subTitle = "La signature du délégué de classe est requise";
      buttonLabel = "CONTINUER";
    } else {
      title = "Signature du Professeur";
      subTitle = "La signature du professeur est optionnelle";
      buttonLabel = _isSaving ? "Enregistrement..." : "ENREGISTRER";
    }

    return SizedBox.expand(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          color: AppColors.black.withAlpha(51),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              textAlign: TextAlign.left,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                setState(() => showSignatureDialog = false),
                            icon: const Icon(Icons.cancel_outlined, size: 30),
                          ),
                        ],
                      ),
                      Text(
                        subTitle,
                        style: const TextStyle(color: Colors.grey),
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        height: 250,
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
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
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
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: Button(
                          label: buttonLabel,
                          onPressed: _isSaving ? null : _handleSignatureNext,
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
