import 'package:flutter/material.dart';

class Software extends StatelessWidget {
  const Software({super.key});

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Département Software",
                    style: TextStyle(
                        fontSize: 18,
                         fontWeight: FontWeight.bold,
                         fontFamily: 'Squid',
                        color: Colors.black
                        ),
                   ),

        backgroundColor:  Color.fromRGBO(232, 118, 118, 1),
      ),
      
    );
  }
}