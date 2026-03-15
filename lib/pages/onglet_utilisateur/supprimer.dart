import 'package:flutter/material.dart';
import 'package:attendance/composants/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Supprimer extends StatefulWidget {
  const Supprimer({super.key});

  @override
  State<Supprimer> createState() => _SupprimerState();
}

class _SupprimerState extends State<Supprimer> {
  final SupabaseClient _client = Supabase.instance.client;
  bool _loading = false;
  List<Map<String, dynamic>> _surveillants = [];

  @override
  void initState() {
    super.initState();
    _fetchSurveillants();
  }

  Future<void> _fetchSurveillants() async {
    setState(() => _loading = true);

    try {
      final List<dynamic> response = await _client
          .from('surveillant')
          .select('id_surveillant, nom, prenom')
          .filter('delete_at', 'is', null)
          .order('nom, prenom');

      if (!mounted) return;

      setState(() {
        _surveillants = List<Map<String, dynamic>>.from(response);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      debugPrint("Erreur de chargement: $e");
    }
  }

  Future<void> _deleteSurveillant(int id, String nomComplet) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text('Voulez-vous vraiment supprimer $nomComplet ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);

    try {
      // Dans les nouvelles versions, update() ne renvoie pas d'objet .error
      // Si ça échoue, une exception est levée.
      await _client
          .from('surveillant')
          .update({'delete_at': DateTime.now().toIso8601String()})
          .eq('id_surveillant', id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Surveillant supprimé avec succès !')),
      );

      // Recharge la liste après suppression
      _fetchSurveillants();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      debugPrint("Erreur lors de la suppression: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Supprimer un surveillant',
        ),
        backgroundColor: AppColors.red,
      ),
      body: _loading && _surveillants.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchSurveillants,
              child: _surveillants.isEmpty
                  ? const Center(child: Text("Aucun surveillant disponible"))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _surveillants.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final surveillant = _surveillants[index];
                        final nomComplet =
                            '${surveillant['nom']} ${surveillant['prenom']}';
                        return ListTile(
                          title: Text(
                            nomComplet,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 40.0,
                            ),
                            onPressed: () => _deleteSurveillant(
                              surveillant['id_surveillant'],
                              nomComplet,
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
