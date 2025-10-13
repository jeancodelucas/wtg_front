// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wtg_front/services/api_service.dart';
import 'package:wtg_front/services/location_service.dart';

class HomeScreen extends StatefulWidget {
  // Recebe a posição inicial da tela de login, que pode ser nula.
  final Position? initialPosition;

  const HomeScreen({super.key, this.initialPosition});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Instâncias dos serviços de localização e API.
  final LocationService _locationService = LocationService();
  final ApiService _apiService = ApiService();

  // Lista para armazenar as promoções buscadas.
  List<dynamic> _promotions = [];
  // Controla o estado de carregamento da tela.
  bool _isLoading = true;
  // Armazena uma mensagem de erro, caso ocorra.
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Inicia o processo de obtenção da localização e busca das promoções.
    _initializeLocationAndFetchPromotions();

    // Inicia as atualizações periódicas de localização em segundo plano.
    _locationService.startLocationUpdates(onUpdate: (newPosition) {
      print("Nova localização recebida, buscando novas promoções...");
      _fetchPromotions(newPosition);
    });
  }

  @override
  void dispose() {
    // Para o timer de atualização periódica quando a tela é fechada para economizar bateria.
    _locationService.stopLocationUpdates();
    super.dispose();
  }

  /// Método inicial para obter a primeira localização e buscar as promoções.
  Future<void> _initializeLocationAndFetchPromotions() async {
    // Se uma posição inicial foi passada pela tela de login, usa-a diretamente.
    if (widget.initialPosition != null) {
      _fetchPromotions(widget.initialPosition!);
    } else {
      // Se não, tenta obter a localização atual do dispositivo.
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        // Se a localização foi obtida com sucesso, busca as promoções.
        _fetchPromotions(position);
      } else {
        // Se a permissão de localização foi negada ou houve um erro,
        // exibe uma mensagem informativa para o usuário.
        setState(() {
          _isLoading = false;
          _errorMessage = "É necessário acesso à localização para exibir eventos próximos.";
        });
      }
    }
  }

  /// Busca as promoções na API com base na localização fornecida.
  Future<void> _fetchPromotions(Position position) async {
    // Ativa o indicador de carregamento, exceto para atualizações silenciosas em segundo plano.
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null; // Limpa erros anteriores
      });
    }

    try {
      // Chama o serviço da API para filtrar as promoções.
      final promotions = await _apiService.filterPromotions(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      // Atualiza o estado da tela com as novas promoções.
      if (mounted) {
        setState(() {
          _promotions = promotions;
        });
      }
      print("${promotions.length} promoções encontradas.");
    } catch (e) {
      // Em caso de erro na API, armazena a mensagem para exibição.
      print("Erro ao buscar promoções: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Não foi possível carregar os eventos. Tente novamente mais tarde.";
        });
      }
    } finally {
      // Garante que o indicador de carregamento seja desativado ao final.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Constrói a interface da tela.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Eventos Próximos')),
      body: _buildBody(),
    );
  }

  /// Decide qual widget exibir no corpo da tela com base no estado atual.
  Widget _buildBody() {
    if (_isLoading) {
      // Exibe um círculo de progresso enquanto os dados estão sendo carregados.
      return const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      // Exibe a mensagem de erro se algo deu errado (ex: sem permissão de localização).
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    } else if (_promotions.isEmpty) {
      // Exibe uma mensagem se nenhuma promoção foi encontrada nas proximidades.
      return const Center(
        child: Text(
          'Nenhum evento encontrado por perto.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    } else {
      // Exibe a lista de promoções encontradas.
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
}