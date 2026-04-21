import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendance/pages/login.dart';
import 'package:attendance/pages/main_navigation_bar.dart';
import 'package:attendance/pages/class_list.dart';
import 'package:attendance/pages/presence.dart';
import 'package:attendance/pages/onglet_seance/creer_seance.dart';
import 'package:attendance/pages/success_registration.dart';
import 'package:attendance/pages/detail_historique.dart';
import 'package:attendance/models/historique_model.dart';
import 'package:attendance/providers/user_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Presence;

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
        path: '/presence',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const Presence(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),

      GoRoute(
        path: '/class_list',
        pageBuilder: (context, state) {
          final data = state.extra as Map<String, dynamic>;

          return CustomTransitionPage(
            child: ClassList(
              students: data['students'],
              idSeance: data['id_seance'],
              heureDebut: data['heureDebut'],
              heureFin: data['heureFin'],
              niveauLabel: data['niveauLabel'],
              filiereLabel: data['filiereLabel'],
              ecueLabel: data['ecueLabel'],
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;
                  var tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));
                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
          );
        },
      ),
      GoRoute(
        path: '/success',
        pageBuilder: (context, state) {
          final failed = state.extra as int? ?? 0;
          return CustomTransitionPage(
            child: SuccessRegistration(failedNotifications: failed),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
          );
        },
      ),
      GoRoute(
        path: '/detail-historique',
        pageBuilder: (context, state) {
          final item = state.extra as HistoriqueModel;
          return CustomTransitionPage(
            child: DetailHistorique(item: item),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const begin = Offset(0.0, 1.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;
                  var tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));
                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
          );
        },
      ),

      GoRoute(
        path: '/creer-seance',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;

          return CustomTransitionPage(
            child: CreerSeance(
              mode: extra?['mode'] ?? 'create',
              seance: extra?['seance'],
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ],
  );
});
