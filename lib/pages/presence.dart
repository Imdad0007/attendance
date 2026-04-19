import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:attendance/composants/dropdown_field.dart';
import 'package:attendance/pages/class_list.dart';
import 'package:attendance/composants/colors.dart';
import 'package:attendance/composants/button.dart';
import 'package:attendance/composants/notification_ui.dart';
import 'package:go_router/go_router.dart';

class Presence extends StatefulWidget {
  const Presence({super.key});

  @override
  State<Presence> createState() => _PresenceState();
}

class _PresenceState extends State<Presence> {
  int? selectedNiveau;
  int? selectedFiliere;
  int? selectedClasse;
  int? selectedEcue;
  int? selectedProf;
  int? selectedSalle;
  TimeOfDay? heureDebut;
  TimeOfDay? heureFin;

  List<Map<String, dynamic>> niveaux = [];
  List<Map<String, dynamic>> filieres = [];
  List<Map<String, dynamic>> ecue = [];
  List<Map<String, dynamic>> professeurs = [];
  List<Map<String, dynamic>> salles = [];

  bool isLoadingNiveaux = true;
  bool isLoadingFilieres = false;
  bool isLoadingEcue = false;
  bool isLoadingProfs = true;
  bool isLoadingSalles = true;
  bool isNavigating = false;

  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    await Future.wait([_fetchNiveaux(), _fetchProfesseurs(), _fetchSalles()]);
  }

  Future<void> _fetchNiveaux() async {
    try {
      final response = await _supabase.from('niveau').select('id_niveau, libelle');
      setState(() {
        niveaux = (response as List).map((item) => {'id_niveau': item['id_niveau'], 'libelle': item['libelle']}).toList();
        isLoadingNiveaux = false;
      });
    } catch (e) {
      setState(() => isLoadingNiveaux = false);
    }
  }

  Future<void> _fetchProfesseurs() async {
    try {
      final response = await _supabase.from('professeur').select('id_prof, nom, prenom').order('nom');
      setState(() {
        professeurs = (response as List).map((item) => {'id_prof': item['id_prof'], 'nom': item['nom'], 'prenom': item['prenom']}).toList();
        isLoadingProfs = false;
      });
    } catch (e) {
      setState(() => isLoadingProfs = false);
    }
  }

  Future<void> _fetchSalles() async {
    try {
      final response = await _supabase.from('salle').select('id_salle, nom').order('nom');
      setState(() {
        salles = (response as List).map((item) => {'id_salle': item['id_salle'], 'nom': item['nom']}).toList();
        isLoadingSalles = false;
      });
    } catch (e) {
      setState(() => isLoadingSalles = false);
    }
  }

  Future<void> _fetchFilieres(int idNiveau) async {
    try {
      final response = await _supabase
          .from('classe')
          .select('id_filiere, filiere(nom_filiere)')
          .eq('id_niveau', idNiveau);

      final data = (response as List).map((item) => {
        'id_filiere': item['id_filiere'],
        'nom_filiere': item['filiere']['nom_filiere'],
      }).toList();

      setState(() {
        filieres = data;
        isLoadingFilieres = false;
      });
    } catch (e) {
      setState(() => isLoadingFilieres = false);
    }
  }

  Future<void> _fetchClasse(int idNiveau, int idFiliere) async {
    try {
      final response = await _supabase
          .from('classe')
          .select('id_classe')
          .eq('id_niveau', idNiveau)
          .eq('id_filiere', idFiliere)
          .maybeSingle();

      if (response != null) {
        setState(() {
          selectedClasse = response['id_classe'];
        });
      }
    } catch (e) {
      debugPrint("Erreur fetchClasse: $e");
    }
  }

  Future<void> _fetchEcue(int idClasse) async {
    try {
      final ueResponse = await _supabase.from('ue').select('id_ue').eq('id_classe', idClasse);
      final ueIds = (ueResponse as List).map((e) => e['id_ue'] as int).toList();

      if (ueIds.isEmpty) {
        setState(() {
          ecue = [];
          isLoadingEcue = false;
        });
        return;
      }

      final ecueResponse = await _supabase.from('ecue').select('id_ecue, intitule_ecue').inFilter('id_ue', ueIds);

      setState(() {
        ecue = (ecueResponse as List).map((item) => {
          'id_ecue': item['id_ecue'],
          'intitule_ecue': item['intitule_ecue'],
        }).toList();
        isLoadingEcue = false;
      });
    } catch (e) {
      setState(() => isLoadingEcue = false);
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return "00:00";
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  bool get _isFormValid =>
      selectedNiveau != null &&
      selectedFiliere != null &&
      selectedEcue != null &&
      selectedProf != null &&
      selectedSalle != null &&
      heureDebut != null &&
      heureFin != null &&
      (heureDebut!.hour < heureFin!.hour || (heureDebut!.hour == heureFin!.hour && heureDebut!.minute < heureFin!.minute));

  void _resetFields() {
    setState(() {
      selectedNiveau = null;
      selectedFiliere = null;
      selectedEcue = null;
      selectedProf = null;
      selectedSalle = null;
      heureDebut = null;
      heureFin = null;
      filieres = [];
      ecue = [];
    });
  }

  Future<void> _selectTime(BuildContext context, bool isDebut) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isDebut ? const TimeOfDay(hour: 7, minute: 0) : const TimeOfDay(hour: 12, minute: 0),
      initialEntryMode: TimePickerEntryMode.inputOnly,
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
      helpText: isDebut ? 'HEURE DE DÉBUT' : 'HEURE DE FIN',
    );
    if (picked != null) setState(() => isDebut ? heureDebut = picked : heureFin = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: Text('PRÉSENCE', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.black))),
                  const SizedBox(height: 40),
                  if (isLoadingNiveaux) const Center(child: CircularProgressIndicator())
                  else DropdownField<int>(
                    label: "NIVEAU",
                    value: selectedNiveau,
                    items: niveaux.map((n) => DropdownMenuItem<int>(value: n['id_niveau'], child: Text(n['libelle']))).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedNiveau = val;
                        selectedFiliere = null; selectedEcue = null; filieres = []; ecue = [];
                        if (val != null) { isLoadingFilieres = true; _fetchFilieres(val); }
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  if (isLoadingFilieres) const Center(child: CircularProgressIndicator())
                  else DropdownField<int>(
                    label: "FILIÈRE",
                    value: selectedFiliere,
                    disabled: selectedNiveau == null,
                    items: filieres.map((f) => DropdownMenuItem<int>(value: f['id_filiere'], child: Text(f['nom_filiere']))).toList(),
                    onChanged: (val) async {
                      if (val == null) return;
                      setState(() { selectedFiliere = val; selectedEcue = null; ecue = []; isLoadingEcue = true; });
                      await _fetchClasse(selectedNiveau!, val);
                      if (selectedClasse != null) await _fetchEcue(selectedClasse!);
                      if (mounted) setState(() => isLoadingEcue = false);
                    },
                  ),
                  const SizedBox(height: 20),
                  if (isLoadingEcue) const Center(child: CircularProgressIndicator())
                  else DropdownField<int>(
                    label: "ECUE",
                    value: selectedEcue,
                    disabled: selectedFiliere == null,
                    items: ecue.map((c) => DropdownMenuItem<int>(value: c['id_ecue'], child: Text(c['intitule_ecue']))).toList(),
                    onChanged: (val) => setState(() => selectedEcue = val),
                  ),
                  const SizedBox(height: 20),
                  if (isLoadingProfs) const Center(child: CircularProgressIndicator())
                  else DropdownField<int>(
                    label: "PROFESSEUR",
                    value: selectedProf,
                    items: professeurs.map((p) => DropdownMenuItem<int>(value: p['id_prof'], child: Text("${p['nom']} ${p['prenom']}"))).toList(),
                    onChanged: (val) => setState(() => selectedProf = val),
                  ),
                  const SizedBox(height: 20),
                  if (isLoadingSalles) const Center(child: CircularProgressIndicator())
                  else DropdownField<int>(
                    label: "SALLE",
                    value: selectedSalle,
                    items: salles.map((s) => DropdownMenuItem<int>(value: s['id_salle'], child: Text(s['nom']))).toList(),
                    onChanged: (val) => setState(() => selectedSalle = val),
                  ),
                  if (selectedEcue != null) ...[
                    const SizedBox(height: 20),
                    _buildTimeSection(),
                  ],
                  const SizedBox(height: 40),
                  Button(
                    label: isNavigating ? "Chargement..." : "CONTINUER",
                    onPressed: (_isFormValid && !isNavigating) ? _onContinuerPressed : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onContinuerPressed() async {
    setState(() => isNavigating = true);
    try {
      final response = await _supabase
          .from('etudiant')
          .select('matricule, nom, prenom')
          .eq('id_classe', selectedClasse!)
          .order('nom', ascending: true);

      final studentList = (response as List).map((s) => {
        'nom': s['nom'],
        'prenom': s['prenom'],
        'matricule': s['matricule'],
      }).toList();

      final List<String> matricules = studentList.map((s) => s['matricule'] as String).toList();
      
      final parentResponse = await _supabase
          .from('etudiant_parent')
          .select('matricule, parent(telephone)')
          .inFilter('matricule', matricules);

      final Map<String, String> parentPhones = {};
      for (final record in parentResponse) {
        parentPhones[record['matricule']] = record['parent']['telephone'];
      }

      final studentsWithParent = studentList.map((s) => {
        ...s,
        'parentPhoneNumber': parentPhones[s['matricule']] ?? 'N/A',
      }).toList();

      final niveauLabel = niveaux.firstWhere((n) => n['id_niveau'] == selectedNiveau)['libelle'];
      final filiereLabel = filieres.firstWhere((f) => f['id_filiere'] == selectedFiliere)['nom_filiere'];
      final ecueLabel = ecue.firstWhere((c) => c['id_ecue'] == selectedEcue)['intitule_ecue'];

      if (!mounted) return;
      context.push('/class-list', extra: {
        'students': studentsWithParent,
        'idEcue': selectedEcue!,
        'idProf': selectedProf!,
        'idSalle': selectedSalle!,
        'heureDebut': heureDebut!,
        'heureFin': heureFin!,
        'niveauLabel': niveauLabel,
        'filiereLabel': filiereLabel,
        'ecueLabel': ecueLabel,
      });
      _resetFields();
    } catch (e) {
      if (mounted) AppNotification.error("Impossible de charger la liste des étudiants", error: e);
    } finally {
      if (mounted) setState(() => isNavigating = false);
    }
  }

  Widget _buildTimeSection() {
    return Container(
      decoration: const BoxDecoration(border: Border(left: BorderSide(color: AppColors.grey, width: 3))),
      padding: const EdgeInsets.only(left: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _timePickerItem('Heure Début', heureDebut, true),
          const SizedBox(height: 15),
          _timePickerItem('Heure Fin', heureFin, false),
        ],
      ),
    );
  }

  Widget _timePickerItem(String label, TimeOfDay? time, bool isDebut) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.grey)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectTime(context, isDebut),
          borderRadius: BorderRadius.circular(35),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            decoration: BoxDecoration(color: AppColors.clearGrey, borderRadius: BorderRadius.circular(35)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(time != null ? _formatTime(time) : "Heure", style: const TextStyle(fontSize: 16, color: AppColors.black)),
                const Icon(Icons.access_time, color: AppColors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
