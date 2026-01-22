import 'package:flutter/material.dart';

class Trading extends StatelessWidget {
  const Trading({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(" Département Trading",
                    style: TextStyle(
                        fontSize: 18,
                         fontWeight: FontWeight.bold,
                         fontFamily: 'Squid',
                        color: Colors.black
                        ),
                   ),

        backgroundColor: const Color.fromARGB(139, 6, 211, 201),
      ),
      
    );
  }
}