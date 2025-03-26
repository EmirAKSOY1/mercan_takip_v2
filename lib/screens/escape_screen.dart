import 'package:flutter/material.dart';

class EscapeScreen extends StatelessWidget {
  const EscapeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Ekranı'),
      ),
      body: const Center(
        child: Text(
          'Merhaba',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}


  

  



