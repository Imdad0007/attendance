import 'package:attendance/pages/utilisateurs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendance/composants/colors.dart';
import 'package:attendance/providers/role_provider.dart';
import 'package:attendance/providers/navigation_provider.dart';

// Pages
import 'package:attendance/pages/home.dart';
import 'package:attendance/pages/presence.dart';
import 'package:attendance/pages/historique.dart';
import 'package:attendance/pages/profil.dart';
import 'package:attendance/pages/dashboard.dart';
import 'package:attendance/pages/seance.dart';

class MainNavigationBar extends ConsumerWidget {
  const MainNavigationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. On surveille le rôle (via vos providers isAdmin/isSurveillant)
    final isAdmin = ref.watch(isAdminProvider);
    final isSurveillant = ref.watch(isSurveillantProvider);
    final role = ref.watch(roleProvider);

    // 2. On surveille l'onglet sélectionné
    final currentTab = ref.watch(navigationTabProvider);

    // --- 3. LOGIQUE DE FILTRAGE DES ONGLETS SELON LE RÔLE ---
    // L'ordre dans cette liste définit l'ordre dans la barre de navigation
    final List<AppTab> authorizedTabs = [
      if (isAdmin) AppTab.dashboard, // Premier pour l'admin
      if (isSurveillant) AppTab.home, // Premier pour le surveillant
      if (isAdmin) AppTab.seance,
      if (isSurveillant) AppTab.presence,
      AppTab.historique,
      if (isAdmin) AppTab.utilisateurs,
      AppTab.profil,
    ];

    // --- 4. SÉCURITÉ DE DÉMARRAGE ET REDIRECTION ---

    // Si le rôle n'est pas encore chargé, on affiche un écran blanc ou un loader
    if (role == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // On bascule immédiatement sur le premier onglet autorisé (Dashboard pour l'admin)
    if (!authorizedTabs.contains(currentTab)) {
      Future.microtask(() {
        ref.read(navigationTabProvider.notifier).state = authorizedTabs.first;
      });
      // On retourne un container vide pendant la fraction de seconde de la transition
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        title: const Text(
          "ATTENDANCE",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
            fontFamily: 'JetBrainsMono',
          ),
        ),
      ),
      // --- 5. CORPS DE LA PAGE (INDEXEDSTACK) ---
      body: IndexedStack(
        index: authorizedTabs.indexOf(currentTab),
        children: authorizedTabs.map((tab) => _buildPage(tab, ref)).toList(),
      ),
      // --- 6. BARRE DE NAVIGATION ---
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: authorizedTabs.indexOf(currentTab),
        onTap: (index) {
          // Navigue vers l'onglet correspondant dans la liste filtrée
          ref.read(navigationTabProvider.notifier).state =
              authorizedTabs[index];
        },
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: authorizedTabs.map((tab) => _buildNavItem(tab)).toList(),
      ),
    );
  }

  // --- MAPPING DES PAGES ---
  Widget _buildPage(AppTab tab, WidgetRef ref) {
    switch (tab) {
      case AppTab.dashboard:
        return const Dashboard();
      case AppTab.home:
        return HomePage(
          onStartCall: () {
            ref.read(navigationTabProvider.notifier).state = AppTab.presence;
          },
        );
      case AppTab.seance:
        return const Seance();
      case AppTab.presence:
        return const Presence();
      case AppTab.historique:
        return const Historique();
      case AppTab.utilisateurs:
        return const Utilisateur();
      case AppTab.profil:
        return const Profil();
    }
  }

  // --- MAPPING DES ICONES ---
  BottomNavigationBarItem _buildNavItem(AppTab tab) {
    switch (tab) {
      case AppTab.dashboard:
        return const BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_rounded),
          label: 'Dashboard',
        );
      case AppTab.home:
        return const BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: 'Accueil',
        );
      case AppTab.seance:
        return const BottomNavigationBarItem(
          icon: Icon(Icons.assignment_rounded),
          label: 'Séances',
        );
      case AppTab.presence:
        return const BottomNavigationBarItem(
          icon: Icon(Icons.how_to_reg_outlined),
          label: 'Présence',
        );
      case AppTab.historique:
        return const BottomNavigationBarItem(
          icon: Icon(Icons.history_rounded),
          label: 'Historique',
        );
      case AppTab.utilisateurs:
        return const BottomNavigationBarItem(
          icon: Icon(Icons.group_add_rounded),
          label: 'Utilisateurs',
        );
      case AppTab.profil:
        return const BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: 'Profil',
        );
    }
  }
}
