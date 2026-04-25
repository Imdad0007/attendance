import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendance/providers/user_provider.dart';
import 'package:attendance/providers/navigation_provider.dart';
import 'package:attendance/pages/pages_historique/onglet_historique.dart';
import 'package:attendance/services/auth_service.dart';

class InactivityNotifier extends StateNotifier<void> {
  final Ref ref;
  Timer? _timer;
  static const inactivityDuration = Duration(minutes: 20);

  InactivityNotifier(this.ref) : super(null) {
    // On ne démarre le timer que si un utilisateur est connecté
    ref.listen(userProvider, (previous, next) {
      if (next != null) {
        resetTimer();
      } else {
        _timer?.cancel();
      }
    });
  }

  void resetTimer() {
    _timer?.cancel();
    if (ref.read(userProvider) != null) {
      _timer = Timer(inactivityDuration, _handleInactivity);
    }
  }

  void _handleInactivity() async {
    debugPrint("Inactivité détectée. Déconnexion automatique...");
    final authService = AuthService();
    await authService.signOut();

    // Reset de tous les états
    ref.invalidate(userProvider);
    ref.invalidate(navigationTabProvider);
    ref.invalidate(historiqueProvider);

    // Le routeur s'occupera de rediriger vers /login grâce au refreshListenable
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final inactivityProvider = StateNotifierProvider<InactivityNotifier, void>((
  ref,
) {
  return InactivityNotifier(ref);
});
