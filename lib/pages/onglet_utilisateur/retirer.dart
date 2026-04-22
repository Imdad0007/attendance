import 'package:flutter/material.dart';
import 'package:attendance/composants/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:attendance/composants/notification_ui.dart';

class Retirer extends StatefulWidget {
  const Retirer({super.key});

  @override
  State<Retirer> createState() => _RetirerState();
}

class _RetirerState extends State<Retirer> {
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
          .eq('role', 'surveillant')
          .order('nom', ascending: true);

      if (!mounted) return;

      setState(() {
        _surveillants = List<Map<String, dynamic>>.from(response);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppNotification.error("Erreur de chargement");
    }
  }

  Future<void> _handleRetrait(int id, String nomComplet) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text('Voulez-vous vraiment Retirer $nomComplet ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Retirer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);

    try {
      await _client
          .from('surveillant')
          .update({'delete_at': DateTime.now().toIso8601String()})
          .eq('id_surveillant', id);

      if (!mounted) return;

      AppNotification.success("Surveillant retiré avec succès !");

      _fetchSurveillants();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppNotification.error("Erreur lors du retrait");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
        title: const Text(
          'Retirer un surveillant',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFC62828),
      ),
      body: _loading && _surveillants.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchSurveillants,
              child: _surveillants.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_off_outlined,
                            size: 80,
                            color: AppColors.grey.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Aucun surveillant trouvé",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
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
                            style: const TextStyle(
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
                            onPressed: () => _handleRetrait(
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
