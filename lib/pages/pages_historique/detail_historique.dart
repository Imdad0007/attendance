import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/historique_model.dart';
import '../../composants/colors.dart';
import 'package:attendance/config/adaptive_layout.dart';
import 'package:attendance/providers/navigation_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DetailHistorique extends ConsumerStatefulWidget {
  final HistoriqueModel item;

  const DetailHistorique({super.key, required this.item});

  @override
  ConsumerState<DetailHistorique> createState() => _DetailHistoriqueState();
}

class _DetailHistoriqueState extends ConsumerState<DetailHistorique> {
  List<Map<String, dynamic>> absents = [];
  Uint8List? signatureBytes;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final supabase = Supabase.instance.client;

      final presenceData = await supabase
          .from('presence')
          .select('id_presence, signature_prof')
          .eq('id_seance', widget.item.idSeance)
          .single();

      final idPresence = presenceData['id_presence'];
      final rawSignature = presenceData['signature_prof'];

      if (rawSignature != null) {
        setState(() {
          signatureBytes = _robustDecode(rawSignature);
        });
      }

      final detailsResponse = await supabase
          .from('details_presence')
          .select('etudiant(nom, prenom)')
          .eq('id_presence', idPresence)
          .eq('statut', 'absent');

      if (mounted) {
        setState(() {
          absents = (detailsResponse as List).map((e) {
            final etudiant = e['etudiant'] as Map<String, dynamic>;
            return {'nom': etudiant['nom'], 'prenom': etudiant['prenom']};
          }).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Uint8List? _robustDecode(dynamic raw) {
    if (raw == null) return null;
    try {
      Uint8List? firstPass;
      if (raw is String) {
        if (raw.startsWith('\\x')) {
          firstPass = _hexToBytes(raw.substring(2));
        } else {
          try {
            firstPass = base64Decode(raw);
          } catch (_) {
            firstPass = _hexToBytes(raw);
          }
        }
      } else if (raw is List) {
        firstPass = Uint8List.fromList(raw.cast<int>());
      }

      if (firstPass == null || firstPass.isEmpty) return null;

      if (firstPass[0] == 91) {
        final content = utf8.decode(firstPass);
        final List<dynamic> jsonList = jsonDecode(content);
        return Uint8List.fromList(jsonList.cast<int>());
      }
      return firstPass;
    } catch (e) {
      return null;
    }
  }

  Uint8List _hexToBytes(String hex) {
    try {
      final result = Uint8List(hex.length ~/ 2);
      for (int i = 0; i < hex.length; i += 2) {
        result[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
      }
      return result;
    } catch (e) {
      return Uint8List(0);
    }
  }

  String _formatTime(String time) =>
      time.length >= 5 ? time.substring(0, 5) : time;

  @override
  Widget build(BuildContext context) {
    final useAdaptiveNavigation = useMainLayoutRail(context);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text(
          "Détails de l'historique",
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.black),
          onPressed: () {
            if (useAdaptiveNavigation) {
              ref.read(adaptiveNavigationProvider.notifier).state =
                  const AdaptiveNavigationState.none();
              return;
            }
            Navigator.pop(context);
          },
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SESSION CARD
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                                      _dateChip(widget.item.dateSeance),
                                    ],
                                  ),

                                  const SizedBox(height: 10),
                                  _infoRow(
                                    Icons.school_outlined,
                                    "Classe : ${widget.item.classe}",
                                  ),

                                  const SizedBox(height: 16),
                                  _infoRow(
                                    Icons.book_outlined,
                                    "Ecue : ${widget.item.ecue}",
                                  ),

                                  const SizedBox(height: 10),
                                  _infoRow(
                                    Icons.person_outline,
                                    "Professeur : ${widget.item.nomProf} ${widget.item.prenomProf}",
                                  ),

                                  const SizedBox(height: 10),
                                  _infoRow(
                                    Icons.room_outlined,
                                    "Salle : ${widget.item.nomSalle}",
                                  ),

                                  const SizedBox(height: 10),
                                  _infoRow(
                                    Icons.access_time,
                                    "Durée : ${_formatTime(widget.item.heureDebut)} - ${_formatTime(widget.item.heureFin)}",
                                  ),
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

                // SIGNATURE PROFESSEUR
                const Text(
                  "Signature du Professeur",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(
                    minHeight: 150,
                    maxHeight: 200,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: signatureBytes != null && signatureBytes!.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(10),
                          child: Image.memory(
                            signatureBytes!,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                          ),
                        )
                      : Center(
                          child: isLoading
                              ? const CircularProgressIndicator()
                              : const Text(
                                  "Pas de signature disponible",
                                  style: TextStyle(color: Colors.grey),
                                ),
                        ),
                ),

                const SizedBox(height: 30),

                // STATS
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

                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Text(
                      "Effectif total de la classe : ${widget.item.effectif}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.blue,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // ABSENTS LIST
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
                  _noAbsents()
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: absents.length,
                    itemBuilder: (c, i) => _absentItem(absents[i]),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dateChip(DateTime date) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.blue.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      DateFormat('dd MMM yyyy', 'fr_FR').format(date),
      style: const TextStyle(
        color: AppColors.blue,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    ),
  );

  Widget _infoRow(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 20, color: AppColors.grey),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(color: AppColors.black, fontSize: 15),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );

  Widget _statCard(String label, String value, Color color, IconData icon) =>
      Expanded(
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

  Widget _noAbsents() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(30),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.grey.withOpacity(0.2)),
    ),
    child: Column(
      children: [
        const Icon(
          Icons.sentiment_very_satisfied,
          size: 60,
          color: AppColors.green,
        ),
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
  );

  Widget _absentItem(Map<String, dynamic> s) => Container(
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
          child: const Icon(
            Icons.person_off_outlined,
            size: 20,
            color: AppColors.red,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            "${s['nom']} ${s['prenom']}",
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
}
