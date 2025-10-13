// lib/services/location_service.dart

import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  Timer? _timer;

  /// Pede permissão e, se concedida, retorna a posição atual.
  Future<Position?> getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();
    
    // CORREÇÃO PRINCIPAL ESTÁ AQUI: a condição é "!hasPermission"
    if (!hasPermission) {
      print("Permissão de localização negada pelo usuário.");
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

  /// Inicia as atualizações periódicas de localização.
  void startLocationUpdates({required Function(Position position) onUpdate}) {
    if (_timer?.isActive ?? false) return;

    print("Iniciando atualizações de localização...");
    
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
  
  /// Lógica corrigida para gerenciar as permissões de localização.
  Future<bool> _handleLocationPermission() async {
    // 1. Solicita a permissão. O pop-up só aparece se o usuário ainda não escolheu.
    PermissionStatus status = await Permission.location.request();

    // 2. Verifica o resultado.
    if (status.isGranted) {
      return true; // Permissão concedida.
    }
    
    if (status.isPermanentlyDenied) {
      // Se negou permanentemente, abre as configurações do app para habilitar manualmente.
      await openAppSettings();
      return false;
    }

    // Para todos os outros casos (ex: 'denied'), a permissão não foi concedida.
    return false;
  }
}