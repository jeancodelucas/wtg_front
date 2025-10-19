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
    final userFirstName = widget.loginResponse['user']?['firstName'] ?? 'Usuário';
    
    String appBarTitle;
    switch (_selectedIndex) {
      case 1:
        appBarTitle = 'Informações do seu rolê';
        break;
      case 2:
        appBarTitle = 'Meu Perfil';
        break;
      default:
        appBarTitle = 'Olá, $userFirstName';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: _logout,
          ),
        ],
      ),
      // --- CORREÇÃO PRINCIPAL APLICADA AQUI ---
      // O widget Center foi removido para permitir que a lista se expanda corretamente.
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.celebration), label: 'Meu Evento'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFFd74533),
        onTap: _onItemTapped,
      ),
    );
  }
}