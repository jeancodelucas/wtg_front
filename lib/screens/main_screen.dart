// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wtg_front/screens/auth_screen.dart';
import 'tabs/home_tab.dart';
import 'tabs/my_events_tab.dart';
import 'tabs/profile_tab.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';

// --- PALETA DE CORES PADRONIZADA (dark mode) ---
const Color darkBackgroundColor = Color(0xFF1A202C);
const Color primaryTextColor = Colors.white;
const Color secondaryTextColor = Color(0xFFA0AEC0);
const Color primaryButtonColor = Color(0xFFE53E3E);
const Color navigationBarColor = Color(0xFF2D3748);

class MainScreen extends StatefulWidget {
  final Map<String, dynamic> loginResponse;

  const MainScreen({super.key, required this.loginResponse});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final List<Widget> _tabs;

  // --- ÍCONES ATUALIZADOS ---
  final iconList = <IconData>[
    Icons.home_filled,
    Icons.star_rounded, // Ícone alterado
    Icons.person,
  ];
  
  final labelList = [
    "Início",
    "Meu Evento",
    "Perfil"
  ];

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
      appBar: AppBar(
        backgroundColor: darkBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: SizedBox(
          height: 35,
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
      // --- BOTTOM NAVIGATION BAR ATUALIZADA COM EFEITO E DESTAQUE ---
      bottomNavigationBar: AnimatedBottomNavigationBar.builder(
        itemCount: iconList.length,
        tabBuilder: (int index, bool isActive) {
          final color = isActive ? primaryButtonColor : secondaryTextColor;
          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                iconList[index],
                size: 24,
                color: color,
              ),
              const SizedBox(height: 4),
              Text(
                labelList[index],
                maxLines: 1,
                style: TextStyle(
                  color: color, 
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal
                ),
              )
            ],
          );
        },
        backgroundColor: navigationBarColor,
        activeIndex: _currentIndex,
        gapLocation: GapLocation.none,
        notchSmoothness: NotchSmoothness.softEdge,
        leftCornerRadius: 32, // Bordas mais arredondadas
        rightCornerRadius: 32, // Bordas mais arredondadas
        onTap: (index) => setState(() => _currentIndex = index),
        // Sombra suave para um efeito flutuante
        shadow: BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 10,
        ),
      ),
    );
  }
}