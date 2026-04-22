import 'package:attendance/composants/colors.dart';
import 'package:flutter/material.dart';
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
    setState(() => loading = true);
    try {
      final response = await client
          .from('surveillant')
          .select('nom, prenom, telephone, email, role')
          .filter('delete_at', 'is', null)
          .eq('role', 'surveillant')
          .order('nom, prenom');

      if (!mounted) return;

      setState(() {
        surveillants = List<Map<String, dynamic>>.from(response);
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  String _formatPhone(String? phone) {
    if (phone == null || phone.isEmpty) return "Aucun numéro";
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length == 13) {
      return "+${cleaned.substring(0, 3)} ${cleaned.substring(3, 5)} ${cleaned.substring(5, 7)} ${cleaned.substring(7, 9)} ${cleaned.substring(9, 11)} ${cleaned.substring(11, 13)}";
    }
    return cleaned.startsWith('+') ? cleaned : "+$cleaned";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
        title: const Text(
          "Lister les surveillants",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: fetchSurveillants,
                      child: surveillants.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_off_outlined,
                                    size: 80,
                                    color: AppColors.grey.withValues(
                                      alpha: 0.3,
                                    ),
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
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: surveillants.length,
                              itemBuilder: (context, index) {
                                final s = surveillants[index];

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 8,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.blue
                                          .withValues(alpha: 0.1),
                                      child: const Icon(
                                        Icons.person,
                                        color: AppColors.blue,
                                      ),
                                    ),
                                    title: Text(
                                      "${s['nom']} ${s['prenom']}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.black,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text.rich(
                                        TextSpan(
                                          children: [
                                            const TextSpan(
                                              text: "Téléphone : ",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black54,
                                              ),
                                            ),
                                            TextSpan(
                                              text: _formatPhone(
                                                s['telephone'],
                                              ),
                                              style: const TextStyle(
                                                color: AppColors.blue,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
