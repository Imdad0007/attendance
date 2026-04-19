import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendance/pages/login.dart';
import 'package:attendance/pages/main_navigation_bar.dart';
import 'package:attendance/pages/class_list.dart';
import 'package:attendance/pages/success_registration.dart';
import 'package:attendance/pages/detail_historique.dart';
import 'package:attendance/models/historique_model.dart';
import 'package:attendance/providers/user_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  RouterNotifier(this._ref) {
    _ref.listen(userProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final user = ref.read(userProvider);
      final loggingIn = state.matchedLocation == '/login';
      final session = Supabase.instance.client.auth.currentSession;
      
      if (session == null && !loggingIn) return '/login';
      if (session != null && user != null && loggingIn) return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const LoginPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) => 
            FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const MainNavigationBar(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) => 
            FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: '/class-list',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ClassList(
            students: extra['students'],
            idEcue: extra['idEcue'],
            idProf: extra['idProf'],
            idSalle: extra['idSalle'],
            heureDebut: extra['heureDebut'],
            heureFin: extra['heureFin'],
            niveauLabel: extra['niveauLabel'],
            filiereLabel: extra['filiereLabel'],
            ecueLabel: extra['ecueLabel'],
          );
        },
      ),
      GoRoute(
        path: '/success',
        builder: (context, state) {
          final failed = state.extra as int? ?? 0;
          return SuccessRegistration(failedNotifications: failed);
        },
      ),
      GoRoute(
        path: '/detail-historique',
        builder: (context, state) {
          final item = state.extra as HistoriqueModel;
          return DetailHistorique(item: item);
        },
      ),
    ],
  );
});
