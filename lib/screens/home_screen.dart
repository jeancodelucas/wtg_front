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

  @override
  void initState() {
    super.initState();
    // 1. Carrega as promoções iniciais se a posição foi obtida no login
    if (widget.initialPosition != null) {
      _fetchPromotions(widget.initialPosition!);
    } else {
      // Se não, busca a localização agora
      _locationService.getCurrentPosition().then((position) {
        if (position != null) {
          _fetchPromotions(position);
        } else {
          setState(() => _isLoading = false);
          // Opcional: mostrar mensagem de que a localização é necessária
        }
      });
    }

    // 2. Inicia o timer para atualizações periódicas
    _locationService.startLocationUpdates(onUpdate: (newPosition) {
      print("Nova localização recebida, buscando novas promoções...");
      _fetchPromotions(newPosition);
    });
  }

  @override
  void dispose() {
    // 3. Para o timer quando a tela for destruída
    _locationService.stopLocationUpdates();
    super.dispose();
  }

  Future<void> _fetchPromotions(Position position) async {
    setState(() => _isLoading = true);
    try {
      final promotions = await _apiService.filterPromotions(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      setState(() {
        _promotions = promotions;
        _isLoading = false;
      });
      print("${promotions.length} promoções encontradas.");
    } catch (e) {
      print("Erro ao buscar promoções: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Eventos Próximos')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _promotions.isEmpty
              ? const Center(child: Text('Nenhum evento encontrado por perto.'))
              : ListView.builder(
                  itemCount: _promotions.length,
                  itemBuilder: (context, index) {
                    final promotion = _promotions[index];
                    return ListTile(
                      title: Text(promotion['title'] ?? 'Sem Título'),
                      subtitle: Text(promotion['description'] ?? ''),
                    );
                  },
                ),
    );
  }
}