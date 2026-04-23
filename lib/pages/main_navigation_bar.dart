import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:attendance/pages/pages_utilisateurs/onglet_utilisateurs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendance/composants/colors.dart';
import 'package:attendance/providers/role_provider.dart';
import 'package:attendance/providers/navigation_provider.dart';
import 'package:responsive_framework/responsive_framework.dart';

// Pages
import 'package:attendance/pages/home.dart';
import 'package:attendance/pages/pages_presence/onglet_presence.dart';
import 'package:attendance/pages/pages_historique/onglet_historique.dart';
import 'package:attendance/pages/profil.dart';
import 'package:attendance/pages/dashboard.dart';
import 'package:attendance/pages/pages_seance/onglet_seance.dart';

class MainNavigationBar extends ConsumerWidget {
  const MainNavigationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    final isSurveillant = ref.watch(isSurveillantProvider);
    final role = ref.watch(roleProvider);
    final currentTab = ref.watch(navigationTabProvider);
    final isRailExtended = ref.watch(railExtendedProvider);

    final List<AppTab> authorizedTabs = [
      if (isAdmin) AppTab.dashboard,
      if (isSurveillant) AppTab.home,
      if (isAdmin) AppTab.seance,
      if (isSurveillant) AppTab.presence,
      AppTab.historique,
      if (isAdmin) AppTab.utilisateurs,
      AppTab.profil,
    ];

    if (role == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (authorizedTabs.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("Erreur : Aucun onglet autorisé")),
      );
    }

    if (!authorizedTabs.contains(currentTab)) {
      Future.microtask(() {
        if (authorizedTabs.isNotEmpty) {
          ref.read(navigationTabProvider.notifier).state = authorizedTabs.first;
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final int currentIndex = authorizedTabs.indexOf(currentTab);

    // Sécurité supplémentaire avant de passer à IndexedStack
    if (currentIndex < 0 || currentIndex >= authorizedTabs.length) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final responsive = ResponsiveBreakpoints.of(context);

    // DÉTECTION BREAKPOINTS
    final bool isDesktop =
        responsive.largerThan(TABLET) ||
        MediaQuery.of(context).size.width > 1100;
    final bool showHamburger = !isDesktop && (kIsWeb || responsive.isTablet);

    // --- SHARED APPBAR RESPONSIVE ---
    PreferredSizeWidget buildAppBar({required bool hamburgerEnabled}) {
      return AppBar(
        backgroundColor: AppColors.primary,
        elevation: 2,
        centerTitle: true,
        leading: hamburgerEnabled
            ? Builder(
                builder: (innerContext) => IconButton(
                  icon: Icon(
                    Icons.menu,
                    color: Colors.white,
                    size: responsive.isMobile ? 28 : 35,
                  ),
                  onPressed: () => Scaffold.of(innerContext).openDrawer(),
                ),
              )
            : null,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 15),
            Text(
              "ATTENDANCE",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: responsive.largerThan(MOBILE) ? 4.0 : 1.5,
                fontFamily: 'JetBrainsMono',
                fontSize: ResponsiveValue<double>(
                  context,
                  defaultValue: 22.0,
                  conditionalValues: [
                    const Condition.equals(name: MOBILE, value: 22.0),
                    const Condition.equals(name: TABLET, value: 28.0),
                    const Condition.largerThan(name: TABLET, value: 38.0),
                  ],
                ).value!,
              ),
            ),
          ],
        ),
      );
    }

    // --- LE DRAWER ---
    Widget buildDrawer() {
      return Drawer(
        child: Column(
          children: [
            Container(
              height: 120,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/img/attendance.png',
                    height: 60,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "ATTENDANCE",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: authorizedTabs.map((tab) {
                  final item = _getTabDetails(tab);
                  return ListTile(
                    leading: Icon(
                      item.icon,
                      color: currentTab == tab
                          ? AppColors.primary
                          : Colors.grey,
                      size: 28,
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        fontWeight: currentTab == tab
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 16,
                      ),
                    ),
                    selected: currentTab == tab,
                    onTap: () {
                      ref.read(navigationTabProvider.notifier).state = tab;
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );
    }

    // 1. MODE DESKTOP  (Avec Toggle pour le Rail)
    if (isDesktop) {
      return Scaffold(
        appBar: buildAppBar(hamburgerEnabled: false),
        body: Row(
          children: [
            NavigationRail(
              extended: isRailExtended, // État contrôlé par l'utilisateur
              minExtendedWidth: 250,
              minWidth: 80,
              backgroundColor: AppColors.bg,
              elevation: 5,
              selectedIconTheme: const IconThemeData(
                color: AppColors.primary,
                size: 36,
              ),
              unselectedIconTheme: const IconThemeData(
                color: Colors.grey,
                size: 30,
              ),
              selectedLabelTextStyle: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              unselectedLabelTextStyle: const TextStyle(
                color: Colors.grey,
                fontSize: 18,
              ),
              onDestinationSelected: (index) =>
                  ref.read(navigationTabProvider.notifier).state =
                      authorizedTabs[index],

              // BOUTON DE BASSCULEMENT (Toggle)
              leading: Column(
                children: [
                  const SizedBox(height: 10),
                  IconButton(
                    icon: Icon(
                      isRailExtended ? Icons.menu_open : Icons.menu,
                      color: AppColors.primary,
                      size: 35,
                    ),
                    onPressed: () =>
                        ref.read(railExtendedProvider.notifier).state =
                            !isRailExtended,
                  ),
                  const SizedBox(height: 20),
                ],
              ),

              destinations: authorizedTabs.map((tab) {
                final item = _getTabDetails(tab);
                return NavigationRailDestination(
                  icon: Icon(item.icon),
                  label: Text(item.label),
                );
              }).toList(),
              selectedIndex: currentIndex,
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: IndexedStack(
                index: currentIndex,
                children: authorizedTabs
                    .map((tab) => _buildPage(tab, ref))
                    .toList(),
              ),
            ),
          ],
        ),
      );
    }

    // 2. SI MODE HAMBURGER (Tablette ou Web petit écran)
    if (showHamburger) {
      return Scaffold(
        appBar: buildAppBar(hamburgerEnabled: true),
        drawer: buildDrawer(),
        body: IndexedStack(
          index: currentIndex,
          children: authorizedTabs.map((tab) => _buildPage(tab, ref)).toList(),
        ),
      );
    }

    // 3. SINON (Mobile Natif) -> Bottom Navigation
    return Scaffold(
      appBar: buildAppBar(hamburgerEnabled: false),
      body: IndexedStack(
        index: currentIndex,
        children: authorizedTabs.map((tab) => _buildPage(tab, ref)).toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.bg,
        currentIndex: currentIndex,
        onTap: (index) => ref.read(navigationTabProvider.notifier).state =
            authorizedTabs[index],
        selectedItemColor: AppColors.primary,
        type: BottomNavigationBarType.fixed,
        items: authorizedTabs.map((tab) {
          final item = _getTabDetails(tab);
          return BottomNavigationBarItem(
            icon: Icon(item.icon, size: 26),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }

  ({IconData icon, String label}) _getTabDetails(AppTab tab) {
    switch (tab) {
      case AppTab.dashboard:
        return (icon: Icons.dashboard_rounded, label: 'Dashboard');
      case AppTab.home:
        return (icon: Icons.home_rounded, label: 'Accueil');
      case AppTab.seance:
        return (icon: Icons.assignment_rounded, label: 'Séances');
      case AppTab.presence:
        return (icon: Icons.how_to_reg_outlined, label: 'Présence');
      case AppTab.historique:
        return (icon: Icons.history_rounded, label: 'Historique');
      case AppTab.utilisateurs:
        return (icon: Icons.group_add_rounded, label: 'Utilisateurs');
      case AppTab.profil:
        return (icon: Icons.person_rounded, label: 'Profil');
    }
  }

  Widget _buildPage(AppTab tab, WidgetRef ref) {
    switch (tab) {
      case AppTab.dashboard:
        return const Dashboard();
      case AppTab.home:
        return HomePage(
          onStartCall: () =>
              ref.read(navigationTabProvider.notifier).state = AppTab.presence,
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
}
