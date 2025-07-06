// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/server_test_screen.dart'; // 🆕 Добавьте эту строку
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(UndeDataRecorderApp());
}

class UndeDataRecorderApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UNDE Data Recorder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ServerTestScreen(), // 🆕 Начинаем с тестового экрана
      routes: {
        '/home': (context) => HomeScreen(), // 🆕 Добавьте маршрут
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
