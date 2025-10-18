import 'package:flutter/material.dart';
import 'package:wtg_front/screens/tabs/home_tab.dart';
import 'package:wtg_front/screens/tabs/my_events_tab.dart';
import 'package:wtg_front/screens/tabs/profile_tab.dart';

// Cores
const Color primaryAppColor = Color(0xFF6A00FF);
const Color darkTextColor = Color(0xFF2D3748);
const Color iconColor = Color(0xFF718096);

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
      const MyEventsTab(),
      const ProfileTab(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Meus Eventos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: primaryAppColor,
        unselectedItemColor: iconColor,
        onTap: _onItemTapped,
        showUnselectedLabels: false,
        showSelectedLabels: false,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 10,
      ),
    );
  }
}