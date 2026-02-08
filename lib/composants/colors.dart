import 'package:flutter/material.dart';

class AppColors {
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFF002B5B),
      Color(0xFF003E7D),
      Color(0xFF0052A5),
      Color(0xFF0074D9),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.3, 0.7, 1.0],
  );

  static const LinearGradient secondaryGradient = LinearGradient(   
    colors: [
      Color.fromARGB(255, 74, 138, 202),   
      Color.fromARGB(255, 54, 118, 182),   
      Color.fromARGB(255, 34, 98, 162),    
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const primary = Color(0xFF003e7d);
  static const white = Colors.white;
  static const black = Colors.black; 
  static const grey = Colors.grey;
  static const clearGrey = Color(0xFFE0E0E0);
  static const deepGrey = Color.fromARGB(255, 172, 172, 172);
  static const green = Colors.greenAccent;
  static const red = Color.fromARGB(255, 238, 98, 98);
  static const orange = Colors.orange;
  static const blue = Color.fromARGB(255, 74, 138, 202);
}
