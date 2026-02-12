import 'package:flutter/material.dart';
import 'package:attendance/pages/home.dart';
import 'package:attendance/pages/presence.dart';
import 'package:attendance/pages/historique.dart';
import 'package:attendance/pages/profil.dart';
import 'package:attendance/composants/colors.dart';

class MainNavigationBar extends StatefulWidget {
  const MainNavigationBar({super.key});

  @override
  State<MainNavigationBar> createState() => _MainNavigationBarState();
}

class _MainNavigationBarState extends State<MainNavigationBar> {
  int _selectedIndex = 0;
  final List<int> _history = [0];
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // On passe la fonction _onItemTapped à HomePage
    _pages = [
      HomePage(onStartCall: () => _onItemTapped(1)),
      const Presence(),
      const Historique(),
      const Profil(),
    ];
  }

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

        body: IndexedStack(index: _selectedIndex, children: _pages),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
            BottomNavigationBarItem(
              icon: Icon(Icons.check_circle),
              label: 'Presence',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'Historique',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          ],

          currentIndex: _selectedIndex,
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          selectedIconTheme: const IconThemeData(size: 30),
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.black,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}
