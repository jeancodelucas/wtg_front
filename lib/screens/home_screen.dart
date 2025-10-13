// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wtg_front/services/api_service.dart';
import 'package:wtg_front/services/location_service.dart';

class HomeScreen extends StatefulWidget {
  final Position? initialPosition;

  const HomeScreen({super.key, this.initialPosition});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationService _locationService = LocationService();
  final ApiService _apiService = ApiService();

  List<dynamic> _promotions = [];
  bool _isLoading = true;
  String? _message; // Unifica as mensagens de erro e de status

  @override
  void initState() {
    super.initState();
    _initializeLocationAndFetchPromotions();
    _locationService.startLocationUpdates(onUpdate: _fetchPromotions);
  }

  @override
  void dispose() {
    _locationService.stopLocationUpdates();
    super.dispose();
  }

  Future<void> _initializeLocationAndFetchPromotions() async {
    if (widget.initialPosition != null) {
      _fetchPromotions(widget.initialPosition!);
    } else {
      final position = await _locationService.getCurrentPosition();
      if (position != null && mounted) {
        _fetchPromotions(position);
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          _message = "É necessário acesso à localização para exibir eventos próximos.";
        });
      }
    }
  }

  Future<void> _fetchPromotions(Position position) async {
    // Evita reconstruir a tela com o loading em atualizações de fundo
    if (!_isLoading) { 
      print("Atualização silenciosa em segundo plano...");
    }

    try {
      final promotions = await _apiService.filterPromotions(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (mounted) {
        setState(() {
          _promotions = promotions;
          _isLoading = false;
          if (_promotions.isEmpty) {
            _message = "Nenhum evento encontrado por perto.";
          } else {
            _message = null; // Limpa a mensagem se encontrar promoções
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _message = "Não foi possível carregar os eventos. Tente novamente mais tarde.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Eventos Próximos')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_message != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            _message!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _promotions.length,
      itemBuilder: (context, index) {
        final promotion = _promotions[index];
        return ListTile(
          title: Text(promotion['title'] ?? 'Sem Título'),
          subtitle: Text(promotion['description'] ?? ''),
        );
      },
    );
  }
}