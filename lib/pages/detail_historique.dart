import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/historique_model.dart';
import '../composants/colors.dart';

class DetailHistorique extends StatefulWidget {
  final HistoriqueModel item;

  const DetailHistorique({super.key, required this.item});

  @override
  State<DetailHistorique> createState() => _DetailHistoriqueState();
}

class _DetailHistoriqueState extends State<DetailHistorique> {
  List<Map<String, dynamic>> absents = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAbsents();
  }

  Future<void> _fetchAbsents() async {
    try {
      final response = await Supabase.instance.client
          .from('presence')
          .select('etudiant(nom, prenom)')
          .eq('id_seance', widget.item.idSeance)
          .eq('statut', 'absent');

      if (response is List) {
        setState(() {
          absents = (response as List).map((e) {
            final etudiant = e['etudiant'] as Map<String, dynamic>;
            return {
              'nom': etudiant['nom'],
              'prenom': etudiant['prenom'],
            };
          }).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String _formatTime(String time) {
    if (time.length >= 5) {
      return time.substring(0, 5);
    }
    return time;
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.item.totalPresents + widget.item.totalAbsents;
    final percentAbsents = total > 0 ? (widget.item.totalAbsents / total) : 0.0;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Détails de la séance",
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SESSION CARD (Replicating HistoriqueCard style) ---
            Container(
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
                                      "${widget.item.nomSurveillant} ${widget.item.prenomSurveillant}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: AppColors.black,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      DateFormat('dd MMM yyyy', 'fr_FR')
                                          .format(widget.item.dateSeance),
                                      style: const TextStyle(
                                        color: AppColors.blue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _infoRow(Icons.book_outlined, widget.item.ecue),
                              const SizedBox(height: 10),
                              _infoRow(Icons.school_outlined, "Classe : ${widget.item.classe}"),
                              const SizedBox(height: 10),
                              _infoRow(Icons.access_time, "${_formatTime(widget.item.heureDebut)} - ${_formatTime(widget.item.heureFin)}"),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // --- STATS SECTION ---
            Row(
              children: [
                _statCard(
                  "Présents",
                  widget.item.totalPresents.toString(),
                  AppColors.green,
                  Icons.check_circle_outline,
                ),
                const SizedBox(width: 15),
                _statCard(
                  "Absents",
                  widget.item.totalAbsents.toString(),
                  AppColors.red,
                  Icons.remove_circle_outline,
                ),
              ],
            ),

            const SizedBox(height: 30),

            // --- ABSENTS LIST SECTION ---
            const Text(
              "Liste des absents",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 15),

            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (absents.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.grey.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.sentiment_very_satisfied,
                        size: 60, color: AppColors.green),
                    const SizedBox(height: 16),
                    const Text(
                      "Aucun absent !",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Tous les étudiants étaient présents lors de cette séance.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.grey.shade600),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: absents.length,
                itemBuilder: (context, index) {
                  final student = absents[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: AppColors.red.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.red.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_off_outlined,
                              size: 20, color: AppColors.red),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            "${student['nom']} ${student['prenom']}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 15,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
