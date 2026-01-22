import 'package:flutter/material.dart';

class Accounting extends StatelessWidget {
  const Accounting({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Département Accounting",
                    style: TextStyle(
                        fontSize: 18,
                         fontWeight: FontWeight.bold,
                         fontFamily: 'Squid',
                        color: Colors.black
                        ),
                   ),

        backgroundColor:  Color.fromRGBO(139, 6, 211, 1),
      ),
      
    );
  }
}