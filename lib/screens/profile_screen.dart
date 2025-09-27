import 'dart:convert';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  // Recebe os dados do usuário da tela de login
  final Map<String, dynamic> userData;

  const ProfileScreen({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    // Pega o objeto 'user' de dentro do JSON de resposta
    final user = userData['user'];
    
    // Codificador para formatar o JSON de forma legível
    const jsonEncoder = JsonEncoder.withIndent('  ');
    final prettyJson = jsonEncoder.convert(userData);

    return Scaffold(
      appBar: AppBar(
        title: Text('Bem-vindo, ${user['firstName']}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        // Mostra o JSON completo formatado
        child: SingleChildScrollView(
          child: Text(prettyJson),
        ),
      ),
    );
  }
}