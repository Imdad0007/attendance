import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:attendance/composants/colors.dart';
import 'package:attendance/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class Presence extends ConsumerStatefulWidget {
  const Presence({super.key});

  @override
  ConsumerState<Presence> createState() => _Presence();
}

class _Presence extends ConsumerState<Presence> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> seances = [];
  Set<int> seancesFaites = {};

  bool isLoading = true;
  int? _loadingSeanceId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    try {
      await Future.wait([_fetchPresences(), _fetchSeances()]);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchPresences() async {
    try {
      final response = await _supabase.from('presence').select('id_seance');

      final data = response as List;

      setState(() {
        seancesFaites = data.map((e) => e['id_seance'] as int).toSet();
      });
    } catch (e) {
      debugPrint("Erreur presence: $e");
    }
  }

  Future<void> _fetchSeances() async {
    try {
      final user = ref.read(userProvider);

      if (user == null || user.idSurveillant == null) {
        throw Exception("Surveillant non connecté");
      }

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final response = await _supabase
          .from('seance')
          .select('''
        id_seance,
        date_seance,
        heure_debut,
        heure_fin,

        ecue (
          intitule_ecue,
          ue (
            classe (
              id_classe,
              filiere (nom_filiere),
              niveau (libelle)
            )
          )
        ),

        surveillant (nom, prenom),
        professeur (nom, prenom),
        salle (nom)
      ''')
          .eq('id_surveillant', user.idSurveillant!)
          .eq('date_seance', today)
          .order('date_seance', ascending: false)
          .order('id_seance', ascending: false);

      setState(() {
        seances = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint("Erreur seance: $e");
    }
  }

  bool _isDone(int id) => seancesFaites.contains(id);

  String _formatTime(String time) =>
      time.length >= 5 ? time.substring(0, 5) : time;

  String _formatDate(String date) {
    return DateFormat('dd MMM yyyy', 'fr_FR').format(DateTime.parse(date));
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Center(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 10,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HEADER
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
                        const SizedBox(height: 5),
                        const Center(
                          child: Text(
                            "Liste des appels de présence assignés aujourd'hui",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        // CONTENT LIST
                        if (seances.isEmpty)
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 100),
                                Icon(
                                  Icons.event_busy_outlined,
                                  size: 80,
                                  color: Colors.grey.withOpacity(0.5),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  "Vous n'êtes assigné à aucune classe pour la présence aujourd'hui.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: seances.length,
                            itemBuilder: (context, index) {
                              final s = seances[index];
                              return _buildCard(s);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildCard(Map<String, dynamic> s) {
    final ecue = s['ecue'] ?? {};
    final ue = ecue['ue'] ?? {};
    final classe = ue['classe'] ?? {};
    final filiere = classe['filiere'] ?? {};
    final niveau = classe['niveau'] ?? {};

    final surveillant = s['surveillant'] ?? {};
    final prof = s['professeur'] ?? {};
    final salle = s['salle'] ?? {};

    final isDone = _isDone(s['id_seance']);
    final isLoading = _loadingSeanceId == s['id_seance'];

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 6,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "${surveillant['nom'] ?? ''} ${surveillant['prenom'] ?? ''}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: AppColors.black,
                              ),
                            ),
                          ),

                          _statusChip(isDone),
                        ],
                      ),

                      const SizedBox(height: 10),

                      _dateChip(_formatDate(s['date_seance'])),

                      const SizedBox(height: 10),

                      _infoRow(
                        Icons.school_outlined,
                        "Classe : ${filiere['nom_filiere'] ?? ''} - ${niveau['libelle'] ?? ''}",
                      ),

                      const SizedBox(height: 16),

                      _infoRow(
                        Icons.book_outlined,
                        "Ecue : ${ecue['intitule_ecue'] ?? ''}",
                      ),

                      const SizedBox(height: 10),

                      _infoRow(
                        Icons.person_outline,
                        "Professeur : ${prof['nom'] ?? ''} ${prof['prenom'] ?? ''}",
                      ),

                      const SizedBox(height: 10),

                      _infoRow(
                        Icons.room_outlined,
                        "Salle : ${salle['nom'] ?? ''}",
                      ),

                      const SizedBox(height: 10),

                      _infoRow(
                        Icons.access_time,
                        "Durée : ${_formatTime(s['heure_debut'])} - ${_formatTime(s['heure_fin'])}",
                      ),

                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (!isDone)
                            InkWell(
                              onTap: isLoading ? null : () => _startPresence(s),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isLoading
                                      ? Colors.blue.withOpacity(0.5)
                                      : AppColors.blue,
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(20),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isLoading)
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    else
                                      const Icon(
                                        Icons.play_circle_outline,
                                        size: 18,
                                        color: AppColors.white,
                                      ),
                                    const SizedBox(width: 6),

                                    Text(
                                      isLoading
                                          ? "Chargement..."
                                          : "Démarrer l'appel",
                                      style: const TextStyle(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(bool isDone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDone
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isDone ? "EFFECTUÉ" : "EN ATTENTE",
        style: TextStyle(
          color: isDone ? Colors.green : Colors.orange,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _dateChip(String date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        date,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.grey),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: AppColors.black),
          ),
        ),
      ],
    );
  }

  Future<void> _startPresence(Map<String, dynamic> s) async {
    final int idSeance = s['id_seance'];

    setState(() => _loadingSeanceId = idSeance);

    try {
      final classe = s['ecue']['ue']['classe'];
      final int idClasse = classe['id_classe'];

      final response = await _supabase
          .from('etudiant')
          .select('matricule, nom, prenom')
          .eq('id_classe', idClasse)
          .order('nom', ascending: true)
          .order('prenom', ascending: true);

      final students = (response as List)
          .map(
            (e) => {
              'nom': e['nom'],
              'prenom': e['prenom'],
              'matricule': e['matricule'],
            },
          )
          .toList();

      final matricules = students.map((s) => s['matricule'] as String).toList();

      final parentResponse = await _supabase
          .from('etudiant_parent')
          .select('matricule, parent(telephone)')
          .inFilter('matricule', matricules);

      final Map<String, String> phones = {};

      for (final r in parentResponse) {
        phones[r['matricule']] = r['parent']['telephone'];
      }

      final studentsWithParents = students
          .map(
            (s) => {...s, 'parentPhoneNumber': phones[s['matricule']] ?? 'N/A'},
          )
          .toList();

      if (!mounted) return;

      context.go(
        '/class_list',
        extra: {
          'students': studentsWithParents,
          'id_seance': s['id_seance'],
          'heureDebut': s['heure_debut'],
          'heureFin': s['heure_fin'],
          'niveauLabel': classe['niveau']['libelle'],
          'filiereLabel': classe['filiere']['nom_filiere'],
          'ecueLabel': s['ecue']['intitule_ecue'],
        },
      );
    } catch (e) {
      debugPrint("Erreur start presence: $e");
    } finally {
      if (mounted) {
        setState(() => _loadingSeanceId = null);
      }
    }
  }
}
