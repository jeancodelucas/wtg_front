import 'package:flutter/material.dart';
import 'package:wtg_front/screens/auth_screen.dart';
import 'package:wtg_front/screens/tabs/home_tab.dart';
import 'package:wtg_front/screens/tabs/my_events_tab.dart';
import 'package:wtg_front/screens/tabs/profile_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_screen.dart';
import 'tabs/home_tab.dart';
import 'tabs/my_events_tab.dart';
import 'tabs/profile_tab.dart';



// Cores
const Color primaryAppColor = Color(0xFF6A00FF);
const Color darkTextColor = Color(0xFF2D3748);
const Color iconColor = Color(0xFF718096);
const Color primaryColor = Color(0xFFF6A61F);

class MainScreen extends StatefulWidget {
  final Map<String, dynamic> loginResponse;

  const MainScreen({super.key, required this.loginResponse});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      HomeTab(loginResponse: widget.loginResponse),
      // --- CORREÇÃO APLICADA AQUI ---
      // Adicionando o parâmetro que estava faltando
      MyEventsTab(loginResponse: widget.loginResponse), 
      ProfileTab(loginResponse: widget.loginResponse),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
    final userFirstName =
        widget.loginResponse['user']?['firstName'] ?? 'Usuário';

    return Scaffold(
      appBar: AppBar(
        title: Text('Olá, $userFirstName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: _logout,
          ),
        ],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
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
        currentIndex: _selectedIndex,
        selectedItemColor:
            const Color(0xFFd74533), // Cor primária para o item ativo
        onTap: _onItemTapped,
      ),
    );
  }
}