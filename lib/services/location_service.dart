// lib/services/location_service.dart

import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  Timer? _timer;

  /// Verifica permissão, serviço e retorna a posição atual.
  Future<Position?> getCurrentPosition() async {
    // 1. Garante que o serviço de localização do dispositivo está ligado
    bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationServiceEnabled) {
      print("O serviço de localização (GPS) do dispositivo está desativado.");
      // Se o GPS estiver desligado, não há o que fazer a não ser retornar nulo.
      return null;
    }

    // 2. Garante que o app tem permissão para acessar a localização
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      print("Permissão de localização negada pelo usuário.");
      return null;
    }

    // 3. Se tudo estiver certo, obtém a posição
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (e) {
      print("Erro ao obter a localização: $e");
      return null;
    }
  }

  /// Lógica definitiva para gerenciar as permissões de localização.
  Future<bool> _handleLocationPermission() async {
    // Verifica o status atual da permissão
    PermissionStatus status = await Permission.location.status;

    // Se a permissão já foi concedida, retorna true.
    if (status.isGranted) {
      return true;
    }

    // Se a permissão ainda não foi solicitada ou foi negada uma vez, solicita novamente.
    if (status.isDenied) {
      status = await Permission.location.request();
      // Retorna true se o usuário concedeu a permissão agora.
      return status.isGranted;
    }
    
    // Se a permissão foi negada permanentemente, direciona o usuário para as configurações.
    if (status.isPermanentlyDenied) {
      print("Permissão negada permanentemente. Abrindo configurações do app.");
      await openAppSettings();
      return false;
    }

    // Para qualquer outro caso, retorna false.
    return false;
  }
  
  /// Inicia as atualizações periódicas de localização.
  void startLocationUpdates({required Function(Position position) onUpdate}) {
    if (_timer?.isActive ?? false) return;

    print("Iniciando atualizações periódicas de localização...");
    
    _timer = Timer.periodic(const Duration(minutes: 10), (timer) async {
      print("Timer ativado: buscando nova localização...");
      Position? position = await getCurrentPosition();
      if (position != null) {
        onUpdate(position);
      }
    });
  }

  /// Para o serviço de atualização periódica.
  void stopLocationUpdates() {
    print("Parando atualizações de localização.");
    _timer?.cancel();
    _timer = null;
  }
}