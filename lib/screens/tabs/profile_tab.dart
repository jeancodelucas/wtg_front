// lib/tabs/profile_tab.dart

import 'package:flutter/material.dart';

class ProfileTab extends StatelessWidget {
  // 1. Adicionando o campo para receber os dados do login
  final Map<String, dynamic> loginResponse;

  // 2. Adicionando o construtor que exige o loginResponse
  const ProfileTab({super.key, required this.loginResponse});

  @override
  Widget build(BuildContext context) {
    // Exemplo de como usar os dados recebidos
    final userFirstName = loginResponse['user']?['firstName'] ?? 'Usuário';
    
    return Center(
      child: Text(
        'Perfil de $userFirstName (Em breve)',
        style: const TextStyle(fontSize: 20),
      ),
    );
  }
}