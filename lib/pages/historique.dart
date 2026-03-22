import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:attendance/composants/colors.dart';
import '../models/historique_model.dart';
import '../providers/user_provider.dart';
import 'package:attendance/providers/role_provider.dart';
import 'detail_historique.dart';

/// -------------------- Repository --------------------
class HistoriqueRepository {
  final SupabaseClient client;

  HistoriqueRepository(this.client);

  Future<List<HistoriqueModel>> fetch({
    required bool isAdmin,
    int? selectedSurveillantId,
    int? ecueId,
    int? filiereId,
    DateTime? date,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await client.rpc(
      'get_historique',
      params: {
        'p_surveillant_id': selectedSurveillantId,
        'p_ecue_id': ecueId ?? null,
        'p_filiere_id': filiereId ?? null,
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

/// -------------------- Providers --------------------
final supabaseProvider = Provider((ref) => Supabase.instance.client);

final historiqueRepositoryProvider = Provider(
  (ref) => HistoriqueRepository(ref.read(supabaseProvider)),
);

final historiqueProvider =
    StateNotifierProvider<
      HistoriqueNotifier,
      AsyncValue<List<HistoriqueModel>>
    >((ref) => HistoriqueNotifier(ref.read(historiqueRepositoryProvider), ref));

/// -------------------- Notifier --------------------
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
  int? selectedFiliereId;
  DateTime? selectedDate;
  String? selectedNiveauLabel;

  /// Chargement initial
  Future<void> loadInitial() async {
    state = const AsyncValue.loading();
    _items.clear();
    _offset = 0;
    _hasMore = true;

    await loadMore();

    if (_subscription == null) _setupRealtime();
  }

  /// Pagination
  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;
    _isLoading = true;

    try {
      final isAdmin = ref.read(isAdminProvider);
      final user = ref.read(userProvider);

      final newData = await repository.fetch(
        isAdmin: isAdmin,
        selectedSurveillantId: isAdmin
            ? selectedSurveillantId // admin peut filtrer ou non
            : (user?.idSurveillant), // surveillant voit seulement lui-même
        ecueId: selectedEcueId,
        filiereId: selectedFiliereId,
        date: selectedDate,
        limit: _limit,
        offset: _offset,
      );

      if (newData.length < _limit) _hasMore = false;

      for (var item in newData) {
        if (!_items.any((e) => e.idSeance == item.idSeance)) _items.add(item);
      }

      _offset = _items.length;
      state = AsyncValue.data(List.from(_items));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }

    _isLoading = false;
  }

  /// Setters pour filtres
  Future<void> setSurveillant(int? id) async {
    selectedSurveillantId = id;
    await loadInitial();
  }

  Future<void> setDate(DateTime? date) async {
    selectedDate = date;
    await loadInitial();
  }

  Future<void> setFiliere(int filiereId) async {
    selectedFiliereId = filiereId;
    await loadInitial();
  }

  Future<void> setEcue(int? ecueId) async {
    selectedEcueId = ecueId;
    await loadInitial();
  }

  Future<void> resetFilters() async {
    selectedSurveillantId = null;
    selectedEcueId = null;
    selectedFiliereId = null;
    selectedDate = null;
    await loadInitial();
  }

  void _setupRealtime() {
    final client = ref.read(supabaseProvider);
    _subscription = client
        .from('seance')
        .stream(primaryKey: ['id_seance'])
        .listen((_) => loadInitial());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// -------------------- Page --------------------
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

  /// -------------------- FILTRES --------------------

  // Surveillants
  void _showSurveillants() async {
    final data = await Supabase.instance.client
        .from('surveillant')
        .select('id_surveillant, nom');

    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        children: [
          ListTile(
            title: const Text("Tous"),
            onTap: () {
              ref.read(historiqueProvider.notifier).setSurveillant(null);
              Navigator.pop(context);
            },
          ),
          ...data.map<Widget>(
            (s) => ListTile(
              title: Text(s['nom']),
              onTap: () {
                ref
                    .read(historiqueProvider.notifier)
                    .setSurveillant(s['id_surveillant']);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Date
  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      ref.read(historiqueProvider.notifier).setDate(picked);
    }
  }

  void _showEcues() async {
    final data = await Supabase.instance.client
        .from('ecue')
        .select('id_ecue, intitule_ecue')
        .order('intitule_ecue');

    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        children: [
          ListTile(
            title: const Text("Toutes les matières"),
            onTap: () {
              ref.read(historiqueProvider.notifier).setEcue(null);
              Navigator.pop(context);
            },
          ),
          ...data.map<Widget>((e) {
            return ListTile(
              title: Text(e['intitule_ecue']),
              onTap: () {
                ref.read(historiqueProvider.notifier).setEcue(e['id_ecue']);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  // Widget filtre
  Widget _filterItem(String title) {
    return InkWell(
      onTap: () {
        if (title == "Surveillants") {
          _showSurveillants();
        } else if (title == "Dates") {
          _pickDate();
        } else if (title == "ECUE") {
          _showEcues();
        }
      },
      child: Row(
        children: [
          Text(title),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, size: 18),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historiqueProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _filterItem("Surveillants"),
                const SizedBox(width: 20),
                _filterItem("Dates"),
                const SizedBox(width: 20),
                _filterItem("ECUE"),
              ],
            ),
            TextButton(
              onPressed: () =>
                  ref.read(historiqueProvider.notifier).resetFilters(),
              child: const Text("Réinitialiser"),
            ),
            Expanded(
              child: state.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text("Erreur : $e")),
                data: (historiques) => RefreshIndicator(
                  onRefresh: () =>
                      ref.read(historiqueProvider.notifier).loadInitial(),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: historiques.length,
                    itemBuilder: (_, i) =>
                        _HistoriqueCard(item: historiques[i]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// -------------------- Carte --------------------
class _HistoriqueCard extends StatelessWidget {
  final HistoriqueModel item;

  const _HistoriqueCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.nomSurveillant,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              Text(DateFormat('dd/MM/yyyy').format(item.dateSeance)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item.ecue),
              Text("${item.heureDebut} - ${item.heureFin}"),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Classe : ${item.classe}"),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailHistorique(item: item),
                    ),
                  );
                },
                child: const Text("Voir plus"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
