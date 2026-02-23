import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/historique_model.dart';
import '../providers/user_provider.dart';


/// ------------------------------
/// Repository
/// ------------------------------
class HistoriqueRepository {
  final SupabaseClient client;

  HistoriqueRepository(this.client);

  Future<List<HistoriqueModel>> fetch({
    required int surveillantId,
    int? ecueId,
    int limit = 20,
    int offset = 0,
  }) async {
    // Appel RPC
    final response = await client.rpc(
      'get_historique',
      params: {
        'p_surveillant_id': surveillantId,
        'p_ecue_id': ecueId,
        'p_limit': limit,
        'p_offset': offset,
      },
    );

    // En Supabase Flutter v2+, rpc() retourne directement les données.
    if (response is List) {
      return response
          .map((e) => HistoriqueModel.fromMap(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}

/// ------------------------------
/// Riverpod Providers
/// ------------------------------
final supabaseProvider = Provider((ref) => Supabase.instance.client);

final historiqueRepositoryProvider =
    Provider((ref) => HistoriqueRepository(ref.read(supabaseProvider)));

final historiqueProvider =
    StateNotifierProvider<HistoriqueNotifier, AsyncValue<List<HistoriqueModel>>>(
  (ref) => HistoriqueNotifier(ref.read(historiqueRepositoryProvider), ref),
);

/// ------------------------------
/// Historique Notifier avec Realtime Stream
/// ------------------------------
class HistoriqueNotifier
    extends StateNotifier<AsyncValue<List<HistoriqueModel>>> {
  final HistoriqueRepository repository;
  final Ref ref;
  StreamSubscription? _subscription;

  HistoriqueNotifier(this.repository, this.ref) : super(const AsyncValue.loading());

  final List<HistoriqueModel> _items = [];
  int _offset = 0;
  final int _limit = 20;
  bool _hasMore = true;
  bool _isLoading = false;

  /// Chargement initial
  Future<void> loadInitial({required int surveillantId}) async {
    state = const AsyncValue.loading();
    _items.clear();
    _offset = 0;
    _hasMore = true;

    await loadMore(surveillantId: surveillantId);

    // Setup Realtime Stream
    if (_subscription == null) {
      _setupRealtime(surveillantId);
    }
  }

  /// Chargement avec pagination
  Future<void> loadMore({required int surveillantId}) async {
    if (_isLoading || !_hasMore) return;
    _isLoading = true;

    try {
      final newData = await repository.fetch(
        surveillantId: surveillantId,
        limit: _limit,
        offset: _offset,
      );

      if (newData.length < _limit) _hasMore = false;

      for (var item in newData) {
        if (!_items.any((existing) => existing.idSeance == item.idSeance)) {
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

  /// Configuration Realtime Supabase via Stream
  void _setupRealtime(int surveillantId) {
    final client = ref.read(supabaseProvider);
    
    _subscription = client
        .from('seance')
        .stream(primaryKey: ['id_seance'])
        .eq('id_surveillant', surveillantId)
        .listen((data) {
          debugPrint('Realtime change detected via stream');
          _refreshQuietly(surveillantId);
        });
  }

  Future<void> _refreshQuietly(int surveillantId) async {
    if (_isLoading) return;
    _items.clear();
    _offset = 0;
    _hasMore = true;
    await loadMore(surveillantId: surveillantId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// ------------------------------
/// Page Historique
/// ------------------------------
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
      final surveillantId = p.Provider.of<UserProvider>(context, listen: false).user?.idSurveillant;
      if (surveillantId != null) {
        ref.read(historiqueProvider.notifier).loadInitial(surveillantId: surveillantId);
      }
    });

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final surveillantId = p.Provider.of<UserProvider>(context, listen: false).user?.idSurveillant;
    if (surveillantId == null) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(historiqueProvider.notifier).loadMore(surveillantId: surveillantId);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historiqueProvider);

    return Scaffold(
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Erreur : $e")),
        data: (historiques) {
          if (historiques.isEmpty) {
            return const Center(child: Text("Aucun historique"));
          }

          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  'HISTORIQUE',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    final surveillantId = p.Provider.of<UserProvider>(context, listen: false).user?.idSurveillant;
                    if (surveillantId != null) {
                      await ref.read(historiqueProvider.notifier).loadInitial(
                            surveillantId: surveillantId,
                          );
                    }
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: historiques.length,
                    itemBuilder: (context, index) {
                      return _HistoriqueCard(item: historiques[index]);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// ------------------------------
/// Widget Card
/// ------------------------------
class _HistoriqueCard extends StatelessWidget {
  final HistoriqueModel item;

  const _HistoriqueCard({required this.item});

  @override
  Widget build(BuildContext context) {
    String formatTime(String timeStr) {
      try {
        final dt = DateTime.parse("2000-01-01 $timeStr");
        return DateFormat.Hm().format(dt);
      } catch (_) {
        return timeStr.substring(0, 5);
      }
    }

    final hDebut = formatTime(item.heureDebut);
    final hFin = formatTime(item.heureFin);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 8,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${item.nomSurveillant} ${item.prenomSurveillant}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Text(DateFormat('dd/MM/yyyy').format(item.dateSeance)),
            ],
          ),
          const SizedBox(height: 8),
          Text(item.ecue),
          const SizedBox(height: 4),
          Text("Classe : ${item.classe}"),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("$hDebut - $hFin"),
              const Text("Voir plus >", style: TextStyle(color: Colors.blue)),
            ],
          ),
        ],
      ),
    );
  }
}