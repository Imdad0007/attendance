import 'package:flutter/material.dart';

class Presence extends StatelessWidget {
  const Presence({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Département Presence",
                    style: TextStyle(
                        fontSize: 18,
                         fontWeight: FontWeight.bold,
                         fontFamily: 'Squid',
                        color: Colors.black
                        ),
                   ),

        backgroundColor:  Color.fromRGBO(238, 3, 214, 1),
      ),
      
    );
  }
}