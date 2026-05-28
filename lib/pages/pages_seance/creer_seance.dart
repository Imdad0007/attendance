import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:attendance/composants/dropdown_field.dart';
import 'package:attendance/composants/colors.dart';
import 'package:attendance/composants/button2.dart';
import 'package:attendance/composants/notification_ui.dart';
import 'package:attendance/config/adaptive_layout.dart';
import 'package:attendance/providers/navigation_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreerSeance extends ConsumerStatefulWidget {
  final String mode; // create | edit
  final Map<String, dynamic>? seance;

  const CreerSeance({super.key, required this.mode, this.seance});

  @override
  ConsumerState<CreerSeance> createState() => _CreerSeanceState();
}

class _CreerSeanceState extends ConsumerState<CreerSeance> {
  int? selectedNiveau;
  int? selectedFiliere;
  int? selectedClasse;
  int? selectedEcue;
  int? selectedProf;
  int? selectedSalle;
  TimeOfDay? heureDebut;
  TimeOfDay? heureFin;
  DateTime? dateSeance;

  List<Map<String, dynamic>> niveaux = [];
  List<Map<String, dynamic>> filieres = [];
  List<Map<String, dynamic>> ecue = [];
  List<Map<String, dynamic>> professeurs = [];
  List<Map<String, dynamic>> salles = [];

  bool isLoadingNiveaux = false;
  bool isLoadingFilieres = false;
  bool isLoadingEcue = false;
  bool isLoadingProfs = false;
  bool isLoadingSalles = false;
  bool isNavigating = false;
  bool _isEditInitialized = false;

  bool get _isFormValid =>
      selectedNiveau != null &&
      selectedFiliere != null &&
      selectedEcue != null &&
      selectedProf != null &&
      selectedSalle != null &&
      dateSeance != null &&
      heureDebut != null &&
      heureFin != null &&
      (heureDebut!.hour < heureFin!.hour ||
          (heureDebut!.hour == heureFin!.hour &&
              heureDebut!.minute < heureFin!.minute));

  void _resetFields() {
    setState(() {
      selectedNiveau = null;
      selectedFiliere = null;
      selectedEcue = null;
      selectedProf = null;
      selectedSalle = null;
      heureDebut = null;
      heureFin = null;
      dateSeance = DateTime.now();
      filieres = [];
      ecue = [];
    });
  }

  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    dateSeance = DateTime.now();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      isLoadingNiveaux = false;
      isLoadingProfs = false;
      isLoadingSalles = false;
    });

    await Future.wait([
      _fetchNiveaux(),
      _fetchProfesseurs(),
      _fetchSalles(),
    ]);

    if (widget.mode == 'edit') {
      await _initEditMode();
    }
  }

  Future<void> _initEditMode() async {
    if (widget.mode != 'edit' || widget.seance == null) return;

    final s = widget.seance!;
    final idNiveau = s['id_niveau'];
    final idFiliere = s['id_filiere'];
    final idClasse = s['id_classe'];

    // Charger les listes dépendantes AVANT d'assigner les valeurs
    await _fetchFilieres(idNiveau);

    // On surcharge _fetchClasse pour ne pas reset l'UI pendant l'init
    try {
      final ecueResponse = await _supabase
          .from('ue')
          .select('id_ue')
          .eq('id_classe', idClasse);

      final ueIds = (ecueResponse as List)
          .map((e) => e['id_ue'] as int)
          .toList();

      if (ueIds.isNotEmpty) {
        final resEcue = await _supabase
            .from('ecue')
            .select('id_ecue, intitule_ecue')
            .inFilter('id_ue', ueIds);

        if (mounted) {
          setState(() {
            ecue = List<Map<String, dynamic>>.from(resEcue);
          });
        }
      }
    } catch (e) {
      debugPrint("Erreur init ecue: $e");
    }

    if (!mounted) return;

    setState(() {
      selectedNiveau = idNiveau;
      selectedFiliere = idFiliere;
      selectedClasse = idClasse;
      selectedEcue = s['id_ecue'];
      selectedProf = s['id_prof'];
      selectedSalle = s['id_salle'];

      // Parsing de la date
      try {
        if (s['date_seance'] != null) {
          dateSeance = DateTime.parse(s['date_seance']);
        }
      } catch (e) {
        debugPrint("Erreur format date: $e");
      }

      // Parsing du temps
      try {
        final debut = s['heure_debut'].split(':');
        final fin = s['heure_fin'].split(':');
        heureDebut = TimeOfDay(
          hour: int.parse(debut[0]),
          minute: int.parse(debut[1]),
        );
        heureFin = TimeOfDay(
          hour: int.parse(fin[0]),
          minute: int.parse(fin[1]),
        );
      } catch (e) {
        debugPrint("Erreur format heure: $e");
      }

      _isEditInitialized = true;
    });
  }

  Future<void> _fetchNiveaux() async {
    try {
      final response = await _supabase
          .from('niveau')
          .select('id_niveau, libelle');
      setState(() {
        niveaux = (response as List)
            .map(
              (item) => {
                'id_niveau': item['id_niveau'],
                'libelle': item['libelle'],
              },
            )
            .toList();
        isLoadingNiveaux = false;
      });
    } catch (e) {
      setState(() => isLoadingNiveaux = false);
    }
  }

  Future<void> _fetchProfesseurs() async {
    try {
      final response = await _supabase
          .from('professeur')
          .select('id_prof, nom, prenom')
          .order('nom', ascending: true);
      setState(() {
        professeurs = (response as List)
            .map(
              (item) => {
                'id_prof': item['id_prof'],
                'nom': item['nom'],
                'prenom': item['prenom'],
              },
            )
            .toList();
        isLoadingProfs = false;
      });
    } catch (e) {
      setState(() => isLoadingProfs = false);
    }
  }

  Future<void> _fetchSalles() async {
    try {
      final response = await _supabase
          .from('salle')
          .select('id_salle, nom')
          .order('nom', ascending: true);
      setState(() {
        salles = (response as List)
            .map((item) => {'id_salle': item['id_salle'], 'nom': item['nom']})
            .toList();
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

      final Map<int, String> uniqueFilieres = {};
      for (var item in (response as List)) {
        final f = item['filiere'];
        if (f != null) {
          uniqueFilieres[item['id_filiere']] = f['nom_filiere'];
        }
      }

      final data = uniqueFilieres.entries
          .map((e) => {'id_filiere': e.key, 'nom_filiere': e.value})
          .toList()
        ..sort((a, b) => (a['nom_filiere'] as String).compareTo(b['nom_filiere'] as String));

      setState(() {
        filieres = data;
        isLoadingFilieres = false;
      });
    } catch (e) {
      debugPrint("Erreur fetchFilieres: $e");
      setState(() => isLoadingFilieres = false);
    }
  }

  Future<void> _fetchClasse(int idNiveau, int idFiliere) async {
    try {
      final response = await _supabase
          .from('classe')
          .select('id_classe')
          .eq('id_niveau', idNiveau)
          .eq('id_filiere', idFiliere);

      final List<int> classIds = (response as List).map((c) => c['id_classe'] as int).toList();

      if (classIds.isEmpty) {
        setState(() {
          ecue = [];
          isLoadingEcue = false;
        });
        return;
      }

      // On récupère les ECUE de toutes les classes correspondantes
      await _fetchEcue(classIds);
    } catch (e) {
      debugPrint("Erreur fetchClasse: $e");
      if (mounted) setState(() => isLoadingEcue = false);
    }
  }

  Future<void> _fetchEcue(List<int> classIds) async {
    try {
      final response = await _supabase
          .from('ecue')
          .select('id_ecue, intitule_ecue, ue!inner(id_classe)')
          .inFilter('ue.id_classe', classIds)
          .order('intitule_ecue', ascending: true);

      if (mounted) {
        setState(() {
          ecue = (response as List)
              .map(
                (item) => {
                  'id_ecue': item['id_ecue'],
                  'intitule_ecue': item['intitule_ecue'],
                },
              )
              .toList();
          isLoadingEcue = false;
        });
      }
    } catch (e) {
      debugPrint("Erreur fetchEcue: $e");
      if (mounted) setState(() => isLoadingEcue = false);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Choisir une date";
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return "00:00";
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dateSeance ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2E7D32),
              onPrimary: Colors.white,
              surface: Color(0xFFF0F2F5),
            ),
            dialogBackgroundColor: const Color(0xFFF0F2F5),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != dateSeance) {
      setState(() {
        dateSeance = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isDebut) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isDebut
          ? const TimeOfDay(hour: 7, minute: 0)
          : const TimeOfDay(hour: 12, minute: 0),
      initialEntryMode: TimePickerEntryMode.inputOnly,
      helpText: isDebut ? 'HEURE DE DÉBUT' : 'HEURE DE FIN',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1976D2),
              onPrimary: Colors.white,
              surface: Color(0xFFF0F2F5),
            ),
            dialogBackgroundColor: const Color(0xFFF0F2F5),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isDebut) {
          heureDebut = picked;
        } else {
          heureFin = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final useAdaptiveNavigation = useMainLayoutRail(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            if (useAdaptiveNavigation) {
              ref
                  .read(adaptiveNavigationProvider.notifier)
                  .state = widget.mode == 'edit'
                  ? const AdaptiveNavigationState(
                      page: AdaptivePage.consulterSeance,
                    )
                  : const AdaptiveNavigationState.none();
              return;
            }
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
        title: Text(
          widget.mode == 'edit' ? "Modifier une séance" : "Créer une séance",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'PRÉSENCE',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (isLoadingNiveaux)
                    const Center(child: CircularProgressIndicator())
                  else
                    DropdownField<int>(
                      label: "NIVEAU",
                      value: selectedNiveau,
                      items: niveaux
                          .map(
                            (n) => DropdownMenuItem<int>(
                              value: n['id_niveau'],
                              child: Text(n['libelle']),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedNiveau = val;
                          selectedFiliere = null;
                          selectedEcue = null;
                          filieres = [];
                          ecue = [];
                          if (val != null) {
                            isLoadingFilieres = true;
                            _fetchFilieres(val);
                          }
                        });
                      },
                    ),
                  const SizedBox(height: 20),
                  if (isLoadingFilieres)
                    const Center(child: CircularProgressIndicator())
                  else
                    DropdownField<int>(
                      label: "FILIÈRE",
                      value: selectedFiliere,
                      disabled: selectedNiveau == null,
                      items: filieres
                          .map(
                            (f) => DropdownMenuItem<int>(
                              value: f['id_filiere'],
                              child: Text(f['nom_filiere']),
                            ),
                          )
                          .toList(),
                      onChanged: (val) async {
                        if (val == null) return;
                        setState(() {
                          selectedFiliere = val;
                          selectedEcue = null;
                          ecue = [];
                          isLoadingEcue = true;
                        });
                        await _fetchClasse(selectedNiveau!, val);
                        if (mounted) setState(() => isLoadingEcue = false);
                      },
                    ),
                  const SizedBox(height: 20),
                  if (isLoadingEcue)
                    const Center(child: CircularProgressIndicator())
                  else
                    DropdownField<int>(
                      label: "ECUE",
                      value: selectedEcue,
                      disabled: selectedFiliere == null,
                      items: ecue
                          .map(
                            (c) => DropdownMenuItem<int>(
                              value: c['id_ecue'],
                              child: Text(c['intitule_ecue']),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => selectedEcue = val),
                    ),
                  const SizedBox(height: 20),
                  if (isLoadingProfs)
                    const Center(child: CircularProgressIndicator())
                  else
                    DropdownField<int>(
                      label: "PROFESSEUR",
                      value: selectedProf,
                      items: professeurs
                          .map(
                            (p) => DropdownMenuItem<int>(
                              value: p['id_prof'],
                              child: Text("${p['nom']} ${p['prenom']}"),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => selectedProf = val),
                    ),

                  const SizedBox(height: 20),

                  if (isLoadingSalles)
                    const Center(child: CircularProgressIndicator())
                  else
                    DropdownField<int>(
                      label: "SALLE",
                      value: selectedSalle,
                      items: salles
                          .map(
                            (s) => DropdownMenuItem<int>(
                              value: s['id_salle'],
                              child: Text(s['nom']),
                            ),
                          )
                          .toList(),

                      onChanged: (val) => setState(() => selectedSalle = val),
                    ),

                  

                  if (selectedEcue != null) ...[
                    const SizedBox(height: 20),
                    _buildDateSection(),
                    const SizedBox(height: 20),
                    _buildTimeSection(),
                  ],
                  const SizedBox(height: 40),
                  Button2(
                    label: isNavigating
                        ? "Traitement..."
                        : widget.mode == 'edit'
                        ? "MODIFIER"
                        : "ENREGISTRER",
                    gradient: AppColors.greenGradient,
                    onPressed: (_isFormValid && !isNavigating)
                        ? _onEnregistrerPressed
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onEnregistrerPressed() async {
    setState(() => isNavigating = true);

    try {
      final dateSeanceStr = dateSeance?.toIso8601String().split('T')[0];
      final heureDebutStr = _formatTime(heureDebut);
      final heureFinStr = _formatTime(heureFin);

      if (widget.mode == 'edit') {
        await _supabase
            .from('seance')
            .update({
              'id_ecue': selectedEcue,
              'id_prof': selectedProf,
              'id_salle': selectedSalle,
              'date_seance': dateSeanceStr,
              'heure_debut': heureDebutStr,
              'heure_fin': heureFinStr,
            })
            .eq('id_seance', widget.seance!['id_seance']);

        if (mounted) {
          AppNotification.success("Séance modifiée avec succès");
          if (useMainLayoutRail(context)) {
            ref
                .read(adaptiveNavigationProvider.notifier)
                .state = const AdaptiveNavigationState(
              page: AdaptivePage.consulterSeance,
            );
          } else {
            Navigator.pop(context, true); // retour suivi
          }
        }
      } else {
        await _supabase.from('seance').insert({
          'id_ecue': selectedEcue,
          'id_prof': selectedProf,
          'id_salle': selectedSalle,
          'date_seance': dateSeanceStr,
          'heure_debut': heureDebutStr,
          'heure_fin': heureFinStr,
        });

        if (mounted) {
          AppNotification.success("Séance créée avec succès");
          _resetFields(); // reste sur page create
        }
      }
    } catch (e) {
      if (mounted) {
        AppNotification.error("Erreur lors de l'enregistrement");
      }
    } finally {
      if (mounted) setState(() => isNavigating = false);
    }
  }

  Widget _buildDateSection() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.grey, width: 3)),
      ),
      padding: const EdgeInsets.only(left: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Date de la séance",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _selectDate(context),
            borderRadius: BorderRadius.circular(35),
            child: Ink(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.clearGrey,
                borderRadius: BorderRadius.circular(35),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(dateSeance),
                    style: const TextStyle(fontSize: 16, color: AppColors.black),
                  ),
                  const Icon(Icons.calendar_today, color: AppColors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSection() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.grey, width: 3)),
      ),
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
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.grey,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectTime(context, isDebut),
          borderRadius: BorderRadius.circular(35),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.clearGrey,
              borderRadius: BorderRadius.circular(35),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time != null ? _formatTime(time) : "Heure",
                  style: const TextStyle(fontSize: 16, color: AppColors.black),
                ),
                const Icon(Icons.access_time, color: AppColors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
