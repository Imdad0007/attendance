import 'package:flutter/material.dart';

class Textfield extends StatelessWidget {
  const Textfield({
    super.key,
    required this.hintText,
    required this.obscureText,
    required this.icon,
  });

  final String hintText;
  final bool obscureText;
  final IconData icon;

  

    @override

    Widget build(BuildContext context) {

      return Container(

        margin: const EdgeInsets.symmetric(vertical: 10),

        decoration: BoxDecoration(

          color:  const Color.fromARGB(255, 172, 172, 172),

          borderRadius: BorderRadius.circular(25),

        ),

        child: TextField(

          obscureText: obscureText,

          style: const TextStyle(fontSize: 16),

          decoration: InputDecoration(

            hintText: hintText,

            hintStyle: TextStyle(color: Colors.black),

            border: InputBorder.none,

            contentPadding: const EdgeInsets.symmetric(

              vertical: 18,

              horizontal: 20,

            ),

            prefixIcon: RepaintBoundary(

              child: Padding(

                padding: const EdgeInsets.only(left: 10, right: 15),

                child: Container(

                  width: 40,

                  height: 40,

                  decoration: const BoxDecoration(

                    shape: BoxShape.circle,

                    gradient: LinearGradient(

                      colors: [

                        Color(0xFF8E2DE2),

                        Color(0xFF4A00E0),

                      ],

                      begin: Alignment.topLeft,

                      end: Alignment.bottomRight,

                    ),

                  ),

                  child: Icon(

                    icon,

                    color: Colors.white,

                    size: 22,

                  ),

                ),

              ),

            ),

            // Optionnel : ajouter un effet de focus

            focusedBorder: OutlineInputBorder(

              borderRadius: BorderRadius.circular(25),

              borderSide: const BorderSide(

                color: Color(0xFF8E2DE2),

                width: 2,

              ),

            ),

          ),

        ),

      );

    }

  }

  