import 'package:flutter/material.dart';

class AddDevicePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Device'),
        backgroundColor: Color(0xFF0D7377),
      ),
      body: Center(
        child: Text(
          'Add Device Screen',
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
      ),
    );
  }
}
