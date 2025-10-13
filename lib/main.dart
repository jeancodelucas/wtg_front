// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wtg_front/screens/auth_screen.dart'; // Garanta que este import está correto

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'La Rua',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter', // Opcional: para um visual mais próximo ao design
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      home: const AuthScreen(), // A tela inicial DEVE ser a AuthScreen
    );
  }
}