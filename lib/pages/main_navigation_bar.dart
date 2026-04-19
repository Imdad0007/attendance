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

    setState(() {
      _selectedIndex = index;
      _history.remove(index);
      _history.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    final isSurveillant = ref.watch(isSurveillantProvider);

    // Construction dynamique de la liste des pages et des items
    final List<Widget> pages = [];
    final List<BottomNavigationBarItem> navItems = [];

    // 1. ACCUEIL (Commun)
    pages.add(HomePage(onStartCall: () => _onItemTapped(1)));
    navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'));

    // 2. PRESENCE (Uniquement Surveillant)
    if (isSurveillant) {
      pages.add(Presence());
      navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: 'Presence'));
    }

    // 3. HISTORIQUE (Commun)
    pages.add(const Historique());
    navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historique'));

    // 4. UTILISATEURS (Uniquement Admin)
    if (isAdmin) {
      pages.add(const Creation());
      navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.people_alt_outlined), label: 'Utilisateurs'));
    }

    // 5. PROFIL (Commun)
    pages.add(const Profil());
    navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Profil'));

    final safeIndex = navItems.isEmpty
        ? 0
        : _selectedIndex.clamp(0, navItems.length - 1);

    if (safeIndex != _selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedIndex = safeIndex;
          _history.removeWhere((index) => index >= navItems.length);
          if (_history.isEmpty) {
            _history.add(_selectedIndex);
          }
        });
      });
    }

    return PopScope(
      canPop: _history.length <= 1,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_history.length > 1) {
          setState(() {
            _history.removeLast();
            // On s'assure que l'index existe toujours dans la nouvelle liste
            _selectedIndex = _history.last < navItems.length ? _history.last : 0;
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
        body: IndexedStack(index: safeIndex, children: pages),
        bottomNavigationBar: BottomNavigationBar(
          items: navItems,
          currentIndex: safeIndex,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.black,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}
