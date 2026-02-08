import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:attendance/composants/dropdown_field.dart';
import 'package:attendance/pages/class_list.dart';
import 'package:attendance/composants/colors.dart';
import 'package:attendance/composants/button.dart';


class Presence extends StatefulWidget {
  const Presence({super.key});

  @override
  State<Presence> createState() => _PresenceState();
}

class _PresenceState extends State<Presence> {
  // State for selected values
  int? selectedNiveau;
  int? selectedFiliere;
  int? selectedClasse;
  int? selectedCours;
  TimeOfDay? heureDebut;
  TimeOfDay? heureFin;

  // State for dropdown items
  List<Map<String, dynamic>> niveaux = [];
  List<Map<String, dynamic>> filieres = [];
  List<Map<String, dynamic>> cours = [];

  // State for loading indicators
  bool isLoadingNiveaux = true;
  bool isLoadingFilieres = false;
  bool isLoadingCours = false;
  bool isNavigating = false;

  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchNiveaux();
  }

  Future<void> _fetchNiveaux() async {
    try {
      final response = await _supabase.from('niveau').select('id_niveau, libelle');
      setState(() {
        niveaux = (response as List).map((item) => {
          'id_niveau': item['id_niveau'],
          'libelle': item['libelle']
        }).toList();
        isLoadingNiveaux = false;
      });
    } catch (e) {
      // Handle error
      setState(() {
        isLoadingNiveaux = false;
      });
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Erreur de chargement des niveaux"), // content: Text("Erreur de chargement des niveaux: $e"),
          backgroundColor: AppColors.red,
        ));
      }
    }
  }
  

  Future<void> _fetchFilieres(int idNiveau) async {
    try {
      // Using a view or RPC would be better, but for now, we do a distinct query on ecue.
      final response = await _supabase
          .from('classe')
          .select('id_filiere, filiere(nom_filiere)')
          .eq('id_niveau', idNiveau);

      // Dans _fetchFilieres
      final data = (response as List).map((item) => {
        'id_filiere': item['id_filiere'],
        'nom_filiere': item['filiere']['nom_filiere'],
      }).toList();

      setState(() {
        filieres = data; // Assigner ici
        isLoadingFilieres = false;
      });
    } catch (e) {
      // Handle error
      setState(() {
        isLoadingFilieres = false;
      });
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Erreur de chargement des filières"),
          backgroundColor: AppColors.red,
        ));
      }
    }
  }

  Future<void> _fetchClasse(int idNiveau, int idFiliere) async {
  try {
    final response = await _supabase
        .from('classe')
        .select('id_classe')
        .eq('id_niveau', idNiveau)
        .eq('id_filiere', idFiliere)
        .maybeSingle(); // maybeSingle évite une exception si rien n'est trouvé

    if (response != null) {
      setState(() {
        selectedClasse = response['id_classe'];
      });
    }
  } catch (e) {
    debugPrint("Erreur fetchClasse: $e");
  }
}


  Future<void> _fetchCours(int idClasse) async {
    try {
      final response = await _supabase
          .from('ecue')
          .select('id_ecue, intitule_ecue')
          .eq('id_classe', idClasse);

      setState(() {
        cours = (response as List)
            .map((item) =>
                {'id_ecue': item['id_ecue'], 'intitule_ecue': item['intitule_ecue']})
            .toList();
        isLoadingCours = false;
      });
    } catch (e) {
      // Handle error
      setState(() {
        isLoadingCours = false;
      });
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Erreur de chargement des cours"),
          backgroundColor: AppColors.red,
        ));
      }
    }
  }

// Formate l'heure manuellement pour éviter le "AM/PM"
  String _formatTime(TimeOfDay? time) {
    if (time == null) return "00:00";
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return "$hours:$minutes";
  }


  String getCurrentAcademicYear() {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    // Academic year typically starts in September (month 9)
    if (currentMonth >= 9) { // September to December
        return '$currentYear-${currentYear + 1}';
      } else { // January to July
        return '${currentYear - 1}-$currentYear';
      }
  }

  bool get _isFormValid =>
      selectedNiveau != null &&
      selectedFiliere != null &&
      selectedCours != null &&
      heureDebut != null &&
      heureFin != null;
  
  void _resetFields() {
    setState(() {
      selectedNiveau = null;
      selectedFiliere = null;
      selectedCours = null;
      heureDebut = null;
      heureFin = null;
      filieres = [];
      cours = [];
    });
  }

  Future<void> _selectTime(BuildContext context, bool isDebut) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isDebut
          ? const TimeOfDay(hour: 7, minute: 0)
          : const TimeOfDay(hour: 12, minute: 0),
      initialEntryMode: TimePickerEntryMode.inputOnly,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
      helpText: isDebut ? 'HEURE DE DÉBUT' : 'HEURE DE FIN',
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
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final verticalSpacing = constraints.maxHeight * 0.03;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 30,
                ),
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
                      SizedBox(height: verticalSpacing * 2),

                      // Niveau Dropdown
                      if (isLoadingNiveaux)
                        const Center(child: CircularProgressIndicator())
                      else
                        DropdownField<int>(
                          label: "NIVEAU",
                          value: selectedNiveau,
                          items: niveaux.map((niveau) {
                            return DropdownMenuItem<int>(
                              value: niveau['id_niveau'],
                              child: Text(niveau['libelle']),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedNiveau = val;
                              // Reset subsequent fields
                              selectedFiliere = null;
                              selectedCours = null;
                              filieres = [];
                              cours = [];
                              if (val != null) {
                                isLoadingFilieres = true;
                                _fetchFilieres(val);
                              }
                            });
                          },
                        ),
                      SizedBox(height: verticalSpacing),

                      // Filiere Dropdown
                      if (isLoadingFilieres)
                        const Center(child: CircularProgressIndicator())
                      else
                        DropdownField<int>(
                          label: "FILIÈRE",
                          value: selectedFiliere,
                          disabled: selectedNiveau == null,
                          items: filieres.map((filiere) {
                            return DropdownMenuItem<int>(
                              value: filiere['id_filiere'],
                              child: Text(filiere['nom_filiere']),
                            );
                          }).toList(),
                          onChanged: (val) async { 
                            if (val == null) return;

                            // 1. Mise à jour immédiate de l'UI
                            setState(() {
                              selectedFiliere = val;
                              selectedCours = null;
                              cours = [];
                              isLoadingCours = true; 
                            });

                            // 2. Appels asynchrones en dehors du setState
                            try {
                              await _fetchClasse(selectedNiveau!, val);
                              
                              if (selectedClasse != null) {
                                await _fetchCours(selectedClasse!);
                              }
                            } finally {
                              // 3. Fin du chargement
                              if (mounted) {
                                setState(() {
                                  isLoadingCours = false;
                                });
                              }
                            }
                          },
                        ),
                      SizedBox(height: verticalSpacing),

                      // Cours Dropdown
                      if (isLoadingCours)
                        const Center(child: CircularProgressIndicator())
                      else
                        DropdownField<int>(
                          label: "COURS",
                          value: selectedCours,
                          disabled: selectedFiliere == null,
                          items: cours.map((c) {
                            return DropdownMenuItem<int>(
                              value: c['id_ecue'],
                              child: Text(c['intitule_ecue']),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => selectedCours = val),
                        ),

                      if (selectedCours != null) ...[
                        SizedBox(height: verticalSpacing),
                        _buildTimeSection(),
                      ],

                      SizedBox(height: verticalSpacing * 2),

                      Button(
                        label: isNavigating ? "Chargement..." : "Continuer",
                        onPressed: (_isFormValid && !isNavigating)
                            ? _onContinuerPressed
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _onContinuerPressed() async {
    setState(() {
      isNavigating = true;
    });

    try {
      final response = await _supabase
        .from('inscription')
        .select('id_inscription, matricule, etudiant(nom, prenom)')
        .eq('id_classe', selectedClasse!)
        .eq('annee_acad', getCurrentAcademicYear())
        // On ordonne d'abord par le nom de l'étudiant, puis par son prénom
        .order('etudiant(nom)', ascending: true)
        .order('etudiant(prenom)', ascending: true);

      final studentList = (response as List).map((item) {
        return {
          'id_inscription': item['id_inscription'],
          'nom': item['etudiant']['nom'],
          'prenom': item['etudiant']['prenom'],
          'matricule': item['matricule'], // Corrected access
        };
      }).toList();

      // 1. Extract matricules
      final List<String> studentMatricules = studentList.map((s) => s['matricule'] as String).toList();

      // 2. Query etudiant_parent and parent tables for these matricules
      final parentResponse = await _supabase
          .from('etudiant_parent')
          .select('matricule, parent(telephone)') // Select matricule from etudiant_parent, and telephone from parent via join
          .filter('matricule', 'in', studentMatricules);

      // 3. Create a map from matricule to parentPhoneNumber
      final Map<String, String> parentPhones = {};
      for (final record in (parentResponse as List<Map<String, dynamic>>)) {
        final String matricule = record['matricule'] as String;
        // Access telephone from the nested 'parent' object
        final String telephone = (record['parent'] as Map<String, dynamic>)['telephone'] as String; 
        if (!parentPhones.containsKey(matricule)) {
          parentPhones[matricule] = telephone;
        }
      }

      // 4. Add parentPhoneNumber to studentList
      final List<Map<String, dynamic>> studentsWithParentInfo = studentList.map((student) {
        return {
          ...student,
          'parentPhoneNumber': parentPhones[student['matricule']] ?? 'N/A', // Add parent phone number
        };
      }).toList();

      // Find the labels for the header
      final niveauLabel = niveaux.firstWhere((n) => n['id_niveau'] == selectedNiveau)['libelle'];
      final filiereLabel = filieres.firstWhere((f) => f['id_filiere'] == selectedFiliere)['nom_filiere'];
      final coursLabel = cours.firstWhere((c) => c['id_ecue'] == selectedCours)['intitule_ecue'];

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClassList(  // Appel de ClassList
            students: studentsWithParentInfo,
            idEcue: selectedCours!,
            heureDebut: heureDebut!,
            heureFin: heureFin!,
            niveauLabel: niveauLabel,
            filiereLabel: filiereLabel,
            coursLabel: coursLabel,
          ),
        ),
      );
      _resetFields();

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Erreur lors de la récupération des étudiants"),
        backgroundColor: AppColors.red,
      ));
    } finally {
      if (mounted) {
        setState(() {
          isNavigating = false;
        });
      }
    }
  }

  Widget _buildTimeSection() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Colors.grey, width: 3)),
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
                  time != null ? _formatTime(time) : "Entrer l'heure",
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
