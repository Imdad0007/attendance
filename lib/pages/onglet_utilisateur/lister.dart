import 'package:flutter/material.dart';
import 'package:attendance/composants/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Lister extends StatefulWidget {
  const Lister({super.key});

  @override
  State<Lister> createState() => _ListerState();
}

class _ListerState extends State<Lister> {
  final SupabaseClient client = Supabase.instance.client;

  List<Map<String, dynamic>> surveillants = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchSurveillants();
  }

  Future<void> fetchSurveillants() async {
    // Chargement des données
    final response = await client
        .from('surveillant')
        .select('nom, prenom, telephone')
        //.filter('delete_at', 'is', null)  // C'est plus vraiement important puisque avec la sécurité RLS configurée au niveau de la table surveillant de la base de donnée, le select ne renvoyera que les surveillants dont les comptes sont actif (dont la colonne delete_at est NULL)
        .order('nom, prenom');

    if (!mounted) return;

    setState(() {
      surveillants = List<Map<String, dynamic>>.from(response);
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.blue,
        title: const Text("Lister les surveillants"),
      ),
      body:
          loading // Si loading est à true,
          ? const Center(
              child: CircularProgressIndicator(),
            ) // affiche un indicateur de chargement
          : surveillants
                .isEmpty // Sinon, si la liste surveillants est vide
          ? const Center(
              // affiche un message
              child: Text(
                "Aucun surveillant actif",
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              // Sinon, affiche la liste des surveillants
              padding: const EdgeInsets.all(16),
              itemCount: surveillants.length,
              itemBuilder: (context, index) {
                final s = surveillants[index]; // Recupere les surveillants

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.person, size: 32),
                    title: Text("${s['nom']} ${s['prenom']}"),
                    subtitle: Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: "Téléphone : ",
                            style: TextStyle(
                              fontWeight: FontWeight
                                  .bold, // Style uniquement pour le libellé
                              color: Colors.black87,
                            ),
                          ),
                          TextSpan(
                            text: "${s['telephone']}",
                            style: const TextStyle(color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
