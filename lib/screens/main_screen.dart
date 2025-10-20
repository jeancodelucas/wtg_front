// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wtg_front/screens/auth_screen.dart';
import 'auth_screen.dart';
import 'tabs/home_tab.dart';
import 'tabs/my_events_tab.dart';
import 'tabs/profile_tab.dart';

// --- PALETA DE CORES PADRONIZADA (dark mode) ---
const Color darkBackgroundColor = Color(0xFF1A202C);
const Color primaryTextColor = Colors.white;
const Color secondaryTextColor = Color(0xFFA0AEC0);
const Color primaryButtonColor = Color(0xFFE53E3E);

class MainScreen extends StatefulWidget {
  final Map<String, dynamic> loginResponse;

  const MainScreen({super.key, required this.loginResponse});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      HomeTab(loginResponse: widget.loginResponse),
      MyEventsTab(loginResponse: widget.loginResponse),
      ProfileTab(loginResponse: widget.loginResponse),
    ];
  }

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
    return Scaffold(
      backgroundColor: darkBackgroundColor,
      // --- APPBAR PADRONIZADA ---
      appBar: AppBar(
        backgroundColor: darkBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false, // Remove o botão de voltar
        title: SizedBox(
          height: 35, // Ajuste a altura conforme necessário
          child: Image.asset(
            'assets/images/LaRuaNameLogo.png',
            fit: BoxFit.contain,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: secondaryTextColor),
            tooltip: 'Sair',
            onPressed: _logout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      // --- BOTTOM NAVIGATION BAR PADRONIZADA ---
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: darkBackgroundColor,
        selectedItemColor: primaryButtonColor, // Cor para o item selecionado
        unselectedItemColor: secondaryTextColor, // Cor para itens não selecionados
        type: BottomNavigationBarType.fixed,
        elevation: 0, // Remove a sombra
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.celebration_outlined),
            activeIcon: Icon(Icons.celebration),
            label: 'Meu Evento',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}