// lib/services/location_service.dart

import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  Timer? _timer;

  // Pede permissão e retorna a posição atual. Usado no login.
  Future<Position?> getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      print("Permissão de localização negada.");
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (e) {
      print("Erro ao obter localização: $e");
      return null;
    }
  }

  // Inicia as atualizações periódicas. Usado na Home.
  void startLocationUpdates({required Function(Position position) onUpdate}) {
    if (_timer?.isActive ?? false) return; // Já está rodando

    print("Iniciando atualizações de localização...");
    
    // Executa a cada 10 minutos
    _timer = Timer.periodic(const Duration(minutes: 10), (timer) async {
      print("Timer ativado: buscando nova localização...");
      Position? position = await getCurrentPosition();
      if (position != null) {
        onUpdate(position);
      }
    });
  }

  // Para o serviço quando o usuário sai do app ou faz logout.
  void stopLocationUpdates() {
    print("Parando atualizações de localização.");
    _timer?.cancel();
    _timer = null;
  }
  
  // Lógica interna para gerenciar as permissões
  Future<bool> _handleLocationPermission() async {
    PermissionStatus status = await Permission.location.status;
    if (status.isDenied) {
      status = await Permission.location.request();
    }
    
    if (status.isPermanentlyDenied) {
      // Opcional: mostrar um diálogo para o usuário ir para as configurações
      openAppSettings();
      return false;
    }

    return status.isGranted;
  }
}