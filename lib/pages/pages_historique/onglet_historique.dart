import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:attendance/composants/colors.dart';
import '../../models/historique_model.dart';
import '../../providers/user_provider.dart';
import 'package:attendance/providers/role_provider.dart';
import 'package:go_router/go_router.dart';

/// ===================== REPOSITORY =====================
class HistoriqueRepository {
  final SupabaseClient client;

  HistoriqueRepository(this.client);

  Future<List<HistoriqueModel>> fetch({
    required bool isAdmin,
    int? selectedSurveillantId,
    int? ecueId,
    int? classeId, // On garde classeId dans Flutter pour la logique
    DateTime? date,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await client.rpc(
      'get_historique',
      params: {
        'p_surveillant_id': selectedSurveillantId,
        'p_ecue_id': ecueId,
        'p_classe_id': classeId, // On envoie l'ID de la classe
        'p_date': date != null ? DateFormat('yyyy-MM-dd').format(date) : null,
        'p_limit': limit,
        'p_offset': offset,
      },
    );

    if (response is List) {
      return response.map((e) => HistoriqueModel.fromMap(e)).toList();
    }
    return [];
  }
}

/// ===================== PROVIDERS =====================
final supabaseProvider = Provider((ref) => Supabase.instance.client);

final historiqueRepositoryProvider = Provider(
  (ref) => HistoriqueRepository(ref.read(supabaseProvider)),
);

final historiqueProvider =
    StateNotifierProvider<
      HistoriqueNotifier,
      AsyncValue<List<HistoriqueModel>>
    >((ref) => HistoriqueNotifier(ref.read(historiqueRepositoryProvider), ref));

/// ===================== NOTIFIER =====================
class HistoriqueNotifier
    extends StateNotifier<AsyncValue<List<HistoriqueModel>>> {
  final HistoriqueRepository repository;
  final Ref ref;

  StreamSubscription? _subscription;

  HistoriqueNotifier(this.repository, this.ref)
    : super(const AsyncValue.loading());

  final List<HistoriqueModel> _items = [];
  int _offset = 0;
  final int _limit = 20;
  bool _hasMore = true;
  bool _isLoading = false;

  int? selectedSurveillantId;
  int? selectedEcueId;
  int? selectedClasseId;
  DateTime? selectedDate;

  Future<void> loadInitial() async {
    state = const AsyncValue.loading();
    _items.clear();
    _offset = 0;
    _hasMore = true;

    await loadMore();

    _subscription ??= _setupRealtime();
  }

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;
    _isLoading = true;

    try {
      final isAdmin = ref.read(isAdminProvider);
      final user = ref.read(userProvider);

      final newData = await repository.fetch(
        isAdmin: isAdmin,
        selectedSurveillantId: isAdmin
            ? selectedSurveillantId
            : user?.idSurveillant,
        ecueId: selectedEcueId,
        classeId: selectedClasseId,
        date: selectedDate,
        limit: _limit,
        offset: _offset,
      );

      if (newData.length < _limit) _hasMore = false;

      for (final item in newData) {
        if (!_items.any((e) => e.idSeance == item.idSeance)) {
          _items.add(item);
        }
      }

      _offset = _items.length;
      state = AsyncValue.data(List.from(_items));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }

    _isLoading = false;
  }

  Future<void> setSurveillant(int? id) async {
    selectedSurveillantId = id;
    await loadInitial();
  }

  Future<void> setDate(DateTime? date) async {
    selectedDate = date;
    await loadInitial();
  }

  Future<void> setEcue(int? ecueId) async {
    selectedEcueId = ecueId;
    await loadInitial();
  }

  Future<void> setClasse(int? id) async {
    selectedClasseId = id;
    await loadInitial();
  }

  Future<void> resetFilters() async {
    selectedSurveillantId = null;
    selectedEcueId = null;
    selectedClasseId = null;
    selectedDate = null;
    await loadInitial();
  }

  StreamSubscription _setupRealtime() {
    final client = ref.read(supabaseProvider);

    return client
        .from('presence')
        .stream(primaryKey: ['id_presence'])
        .listen((_) => loadInitial());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// ===================== PAGE =====================
class Historique extends ConsumerStatefulWidget {
  const Historique({super.key});

  @override
  ConsumerState<Historique> createState() => _HistoriqueState();
}

class _HistoriqueState extends ConsumerState<Historique> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(historiqueProvider.notifier).loadInitial();
    });

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(historiqueProvider.notifier).loadMore();
    }
  }

  void _showSurveillants() async {
    final data = await Supabase.instance.client
        .from('surveillant')
        .select('id_surveillant, nom, prenom')
        .filter('delete_at', 'is', null)
        .eq('role', 'surveillant');

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF0F2F5),

      builder: (sheetContext) => ListView(
        children: [
          ListTile(
            title: const Text("Tous les Surveillants"),
            onTap: () {
              ref.read(historiqueProvider.notifier).setSurveillant(null);
              Navigator.pop(sheetContext);
            },
          ),
          ...data.map<Widget>(
            (s) => ListTile(
              title: Text("${s['nom']} ${s['prenom']}"),
              onTap: () {
                ref
                    .read(historiqueProvider.notifier)
                    .setSurveillant(s['id_surveillant']);
                Navigator.pop(sheetContext);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
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
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(historiqueProvider.notifier).setDate(picked);
    }
  }

  void _showEcues() async {
    final notifier = ref.read(historiqueProvider.notifier);

    // Si une classe est sélectionnée, on ne récupère que les ECUEs de cette classe
    PostgrestFilterBuilder query = Supabase.instance.client
        .from('ecue')
        .select('id_ecue, intitule_ecue, ue!inner(id_classe)');

    if (notifier.selectedClasseId != null) {
      query = query.eq('ue.id_classe', notifier.selectedClasseId!);
    }

    final data = await query.order('intitule_ecue');

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF0F2F5),
      builder: (sheetContext) => ListView(
        children: [
          ListTile(
            title: const Text("Tout les Ecues"),
            onTap: () {
              ref.read(historiqueProvider.notifier).setEcue(null);
              Navigator.pop(sheetContext);
            },
          ),
          ...data.map<Widget>((e) {
            return ListTile(
              title: Text(e['intitule_ecue']),
              onTap: () {
                ref.read(historiqueProvider.notifier).setEcue(e['id_ecue']);
                Navigator.pop(sheetContext);
              },
            );
          }),
        ],
      ),
    );
  }

  void _showClasses() async {
    final data = await Supabase.instance.client
        .from('classe')
        .select('id_classe, filiere(nom_filiere), niveau(libelle)')
        .order('niveau(libelle)', ascending: true)
        .order('filiere(nom_filiere)', ascending: true);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF0F2F5),

      builder: (sheetContext) => ListView(
        children: [
          ListTile(
            title: const Text("Toutes les Classes"),
            onTap: () {
              ref.read(historiqueProvider.notifier).setClasse(null);
              Navigator.pop(sheetContext);
            },
          ),
          ...data.map<Widget>((c) {
            final label =
                "${c['filiere']['nom_filiere']} - ${c['niveau']['libelle']}";
            return ListTile(
              title: Text(label),
              onTap: () {
                ref.read(historiqueProvider.notifier).setClasse(c['id_classe']);
                Navigator.pop(sheetContext);
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _filterItem(
    String title,
    IconData icon,
    bool isActive,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isActive
                  ? AppColors.primary
                  : AppColors.grey.withOpacity(0.3),
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? AppColors.white : AppColors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isActive ? AppColors.white : AppColors.black,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: isActive ? AppColors.white : AppColors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historiqueProvider);
    final notifier = ref.read(historiqueProvider.notifier);
    final isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Historique",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Consultez les sessions passées",
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.grey.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _resetFilterIcon(notifier),
                        if (isAdmin)
                          _filterItem(
                            "Surveillants",
                            Icons.person_search_outlined,
                            notifier.selectedSurveillantId != null,
                            _showSurveillants,
                          ),
                        _filterItem(
                          "Classes",
                          Icons.school_outlined,
                          notifier.selectedClasseId != null,
                          _showClasses,
                        ),
                        _filterItem(
                          "Ecues",
                          Icons.book_outlined,
                          notifier.selectedEcueId != null,
                          _showEcues,
                        ),
                        _filterItem(
                          "Dates",
                          Icons.calendar_month_outlined,
                          notifier.selectedDate != null,
                          _pickDate,
                        ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: state.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                    error: (e, _) => _errorState(),
                    data: (historiques) {
                      if (historiques.isEmpty) return _emptyState();
                      return RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () => notifier.loadInitial(),
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount:
                              historiques.length + (notifier._hasMore ? 1 : 0),
                          itemBuilder: (_, i) => i == historiques.length
                              ? _loadingMoreIndicator()
                              : _HistoriqueCard(item: historiques[i]),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _resetFilterIcon(HistoriqueNotifier notifier) {
    final hasActiveFilter =
        notifier.selectedSurveillantId != null ||
        notifier.selectedDate != null ||
        notifier.selectedEcueId != null ||
        notifier.selectedClasseId != null;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: () => notifier.resetFilters(),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: hasActiveFilter
                ? AppColors.red.withOpacity(0.1)
                : AppColors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            Icons.refresh,
            size: 22,
            color: hasActiveFilter ? AppColors.red : AppColors.grey,
          ),
        ),
      ),
    );
  }

  Widget _errorState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 48, color: AppColors.red),
        const SizedBox(height: 16),
        Text(
          "Oups ! Une erreur est survenue.",
          style: TextStyle(color: AppColors.grey.shade700),
        ),
      ],
    ),
  );

  Widget _emptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.history_toggle_off_rounded,
          size: 80,
          color: AppColors.grey.withOpacity(0.3),
        ),
        const SizedBox(height: 16),
        const Text(
          "Aucun historique trouvé",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.grey,
          ),
        ),
      ],
    ),
  );

  Widget _loadingMoreIndicator() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 20),
    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
  );
}

class _HistoriqueCard extends StatelessWidget {
  final HistoriqueModel item;
  const _HistoriqueCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "${item.nomSurveillant} ${item.prenomSurveillant}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: AppColors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _dateChip(item.dateSeance),
                        ],
                      ),

                      const SizedBox(height: 6),
                      _infoRow(
                        Icons.school_outlined,
                        "Classe : ${item.classe}",
                      ),

                      const SizedBox(height: 12),
                      _infoRow(Icons.book_outlined, "Ecue : ${item.ecue}"),

                      const SizedBox(height: 12),
                      _infoRow(
                        Icons.access_time,
                        "Durée : ${_formatTime(item.heureDebut)} - ${_formatTime(item.heureFin)}",
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _detailsButton(context),
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

  Widget _dateChip(DateTime date) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.blue.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      DateFormat('dd MMM yyyy', 'fr_FR').format(date),
      style: const TextStyle(
        color: AppColors.blue,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    ),
  );

  Widget _infoRow(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 18, color: AppColors.grey),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(color: AppColors.black, fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );

  Widget _detailsButton(BuildContext context) => TextButton(
    style: TextButton.styleFrom(
      backgroundColor: AppColors.primary.withOpacity(0.1),
      foregroundColor: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    onPressed: () => context.push('/detail-historique', extra: item),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Text("Détails", style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(width: 8),
        Icon(Icons.arrow_forward_rounded, size: 18),
      ],
    ),
  );

  String _formatTime(String t) => t.length >= 5 ? t.substring(0, 5) : t;
}
