import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/composants/nav_item.dart';
import 'package:app/departements/accounting.dart';
import 'package:app/departements/software.dart';
import 'package:app/departements/trading.dart';
import 'package:app/pages/login.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> navItems = [
      {'imagePath': 'assets/img/login.png', 'title': 'Login', 'destination': const LoginPage()},
      {'imagePath': 'assets/img/accounting.png', 'title': 'Accounting', 'destination': const Accounting()},
      {'imagePath': 'assets/img/trading.png', 'title': 'Trading', 'destination': const Trading()},
      {'imagePath': 'assets/img/software.png', 'title': 'Software', 'destination': const Software()},
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.light,
      ),

      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Attendance's App",
            style: TextStyle(
              fontSize: 28,
              fontFamily: 'Squid',
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          centerTitle: true,

          leading: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Image.asset("assets/img/arrow.png", width: 25, height: 25),
          ),
          
          actions: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Image.asset("assets/img/settings.png", width: 40, height: 40),
            ),
          ],

          backgroundColor: const Color.fromARGB(140, 20, 6, 211),
        ),

        body: Container(
          color: const Color.fromARGB(60, 20, 6, 211),
          child: LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount;
              if (constraints.maxWidth > 1200) {
                crossAxisCount = 5;
              } else if (constraints.maxWidth > 800) {
                crossAxisCount = 4;
              } else if (constraints.maxWidth > 600) {
                crossAxisCount = 3;
              } else {
                crossAxisCount = 2;
              }

              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1, 
                ),
                padding: const EdgeInsets.all(20),
                itemCount: navItems.length,
                itemBuilder: (context, index) {
                  final item = navItems[index];
                  return NavItem(
                    imagePath: item['imagePath'],
                    title: item['title'],
                    destination: item['destination'],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
