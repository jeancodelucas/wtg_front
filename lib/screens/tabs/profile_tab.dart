// lib/tabs/profile_tab.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wtg_front/screens/auth_screen.dart';

// --- PALETA DE CORES PADRONIZADA ---
const Color darkBackgroundColor = Color(0xFF1A202C);
const Color primaryTextColor = Colors.white;
const Color secondaryTextColor = Color(0xFFA0AEC0);
const Color fieldBackgroundColor = Color(0xFF2D3748);
const Color primaryButtonColor = Color(0xFFE53E3E);

// --- CORES PARA OS ÍCONES ---
const Color walletColor = Color(0xFF48BB78);   // Verde
const Color settingsColor = Color(0xFF4299E1); // Azul
const Color aboutColor = Color(0xFFF6AD55);      // Laranja

class ProfileTab extends StatefulWidget {
  final Map<String, dynamic> loginResponse;
  const ProfileTab({super.key, required this.loginResponse});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.loginResponse['user'];
    final userFirstName = user?['firstName'] ?? 'Usuário';
    final userEmail = user?['email'] ?? 'email@example.com';
    // --- RECUPERANDO A URL DA FOTO ---
    final String? pictureUrl = user?['pictureUrl'];

    return Scaffold(
      backgroundColor: darkBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileHeader(userFirstName, userEmail, pictureUrl),
            const SizedBox(height: 32),

            _buildProfileOption(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Carteira',
              iconColor: walletColor,
              onTap: () {},
            ),
            const SizedBox(height: 16),
            _buildProfileOption(
              icon: Icons.settings_outlined,
              title: 'Configurações da conta',
              iconColor: settingsColor,
              onTap: () {},
            ),
            const SizedBox(height: 16),
            _buildProfileOption(
              icon: Icons.info_outline,
              title: 'Sobre',
              iconColor: aboutColor,
              onTap: () {},
            ),
            const SizedBox(height: 32),
            const Divider(color: fieldBackgroundColor),
            const SizedBox(height: 16),

            _buildProfileOption(
              icon: Icons.logout,
              title: 'Sair',
              iconColor: primaryButtonColor,
              onTap: _logout,
              isLogout: true,
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET DO CABEÇALHO ATUALIZADO ---
  Widget _buildProfileHeader(String name, String email, String? imageUrl) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: fieldBackgroundColor,
          // Se a URL da imagem existir, usa a imagem da rede, senão, mostra o ícone
          backgroundImage: (imageUrl != null) ? NetworkImage(imageUrl) : null,
          child: (imageUrl == null)
              ? const Icon(
                  Icons.person,
                  size: 50,
                  color: secondaryTextColor,
                )
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: const TextStyle(
            color: primaryTextColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: const TextStyle(
            color: secondaryTextColor,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color iconColor,
    bool isLogout = false,
  }) {
    return Material(
      color: fieldBackgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isLogout ? primaryButtonColor : primaryTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: secondaryTextColor, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}