import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:attendance/composants/colors.dart';
import 'package:attendance/pages/pages_seance/creer_seance.dart';
import 'package:attendance/composants/notification_ui.dart';

class SuivreSeance extends StatefulWidget {
  const SuivreSeance({super.key});

  @override
  State<SuivreSeance> createState() => _SuivreSeanceState();
}

class _SuivreSeanceState extends State<SuivreSeance> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> seances = [];
  Set<int> seancesFaites = {};

  bool isLoading = true;

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
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final response = await _supabase
          .from('seance')
          .select('''
        id_seance,
        date_seance,
        heure_debut,
        heure_fin,
        id_ecue,
        id_prof,
        id_salle,
        id_surveillant,
        ecue (
          id_ecue,
          intitule_ecue,
          ue (
            classe (
              id_classe,
              id_niveau,
              id_filiere,
              filiere (nom_filiere),
              niveau (libelle)
            )
          )
        ),
        surveillant (id_surveillant, nom, prenom),
        professeur (id_prof, nom, prenom),
        salle (id_salle, nom)
      ''')
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
        title: const Text(
          "Suivi des séances",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: seances.length,
                    itemBuilder: (context, index) {
                      final s = seances[index];
                      return _buildCard(s);
                    },
                  ),
                ),
        ),
      ),
    );
  }

  // 🎴 CARD (TON DESIGN + STATUS)
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

                      const SizedBox(height: 15),

                      if (!isDone)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _actionButton(
                              icon: Icons.edit,
                              label: "Modifier",
                              color: Colors.blue,
                              onTap: () => _editSeance(s),
                            ),
                            const SizedBox(width: 10),
                            _actionButton(
                              icon: Icons.delete,
                              label: "Supprimer",
                              color: Colors.red,
                              onTap: () => _deleteSeance(s['id_seance']),
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

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSeance(int idSeance) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Suppression"),
        content: const Text("Voulez-vous supprimer cette séance ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _supabase.from('seance').delete().eq('id_seance', idSeance);

      setState(() {
        seances.removeWhere((s) => s['id_seance'] == idSeance);
      });

      if (mounted) {
        AppNotification.success("Séance supprimée avec succès");
      }
    } catch (e) {
      debugPrint("Erreur delete: $e");
    }
  }

  void _editSeance(Map<String, dynamic> s) async {
    final classe = s['ecue']['ue']['classe'];

    final normalizedSeance = {
      'id_seance': s['id_seance'],
      'heure_debut': s['heure_debut'],
      'heure_fin': s['heure_fin'],
      'id_ecue': s['id_ecue'], // Récupéré directement
      'id_prof': s['id_prof'],
      'id_salle': s['id_salle'],
      'id_surveillant': s['id_surveillant'],
      'id_niveau': classe['id_niveau'],
      'id_filiere': classe['id_filiere'],
      'id_classe': classe['id_classe'],
    };

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreerSeance(mode: 'edit', seance: normalizedSeance),
      ),
    );

    if (result == true) {
      _loadData();
    }
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
        color: Colors.blue.withOpacity(0.1),
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
}


