import 'package:flutter/material.dart';
import 'package:attendance/pages/home.dart';
import 'package:attendance/pages/presence.dart';
import 'package:attendance/pages/historique.dart';
import 'package:attendance/pages/profil.dart';
import 'package:attendance/composants/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendance/providers/role_provider.dart';
import 'package:attendance/pages/utilisateurs.dart';

class MainNavigationBar extends ConsumerStatefulWidget {
  const MainNavigationBar({super.key});

  @override
  ConsumerState<MainNavigationBar> createState() => _MainNavigationBarState();
}

class _MainNavigationBarState extends ConsumerState<MainNavigationBar> {
  int _selectedIndex = 0;
  final List<int> _history = [0];

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    if (index == 2) {
      final isAdmin = ref.read(isAdminProvider);

      if (isAdmin) {}
    }

    setState(() {
      _selectedIndex = index;
      _history.remove(index);
      _history.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    final isAdjoint = ref.watch(isAdjointProvider);

    // Pages dynamiques selon rôle
    final pages = [
      HomePage(
        onStartCall: () => _onItemTapped(1),
      ),
      if (isAdjoint) Presence(),
      const Historique(),
      if (isAdmin) const Creation(), // 👈 page supplémentaire
      const Profil(),
    ];

    final navItems = [
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),

      if (isAdjoint)
        const BottomNavigationBarItem(
          icon: Icon(Icons.check_circle),
          label: 'Presence',
        ),

      const BottomNavigationBarItem(
        icon: Icon(Icons.history),
        label: 'Historique',
      ),

      if (isAdmin)
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_add_alt_1_outlined),
          label: 'Utilisateurs',
        ),

      const BottomNavigationBarItem(
        icon: Icon(Icons.account_circle),
        label: 'Profil',
      ),
    ];

    return PopScope(
      canPop: _history.length <= 1,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_history.length > 1) {
          setState(() {
            _history.removeLast();
            _selectedIndex = _history.last;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          toolbarHeight: 70,
          elevation: 0,
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
          title: const Text(
            "Attendance",
            style: TextStyle(
              color: AppColors.white,
              fontFamily: 'JetBrainsMono',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 5.0,
            ),
          ),
        ),
        body: IndexedStack(index: _selectedIndex, children: pages),
        bottomNavigationBar: BottomNavigationBar(
          items: navItems,
          currentIndex: _selectedIndex,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.black,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}
