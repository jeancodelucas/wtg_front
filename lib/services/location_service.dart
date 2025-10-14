// lib/services/location_service.dart

import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  Timer? _timer;

  /// Lógica definitiva para gerenciar as permissões de localização.
  Future<bool> _handleLocationPermission() async {
    print("[LocationService] Iniciando verificação de permissão...");

    // 1. Verifica o status atual da permissão de localização.
    PermissionStatus status = await Permission.location.status;
    print("[LocationService] Status da permissão atual: $status");

    // 2. Se a permissão já foi concedida, não há mais nada a fazer.
    if (status.isGranted) {
      print("[LocationService] Permissão já concedida.");
      return true;
    }

    // 3. Se a permissão foi negada (mas não permanentemente), solicita ao usuário.
    if (status.isDenied) {
      print("[LocationService] Permissão negada. Solicitando ao usuário...");
      status = await Permission.location.request();
      print("[LocationService] Novo status após solicitação: $status");
      // Retorna true se o usuário concedeu a permissão agora.
      return status.isGranted;
    }
    
    // 4. Se a permissão foi negada permanentemente, o usuário precisa ir às configurações.
    if (status.isPermanentlyDenied) {
      print("[LocationService] Permissão negada permanentemente. Solicitando que o usuário abra as configurações.");
      // Abre as configurações do aplicativo para que o usuário possa conceder a permissão manualmente.
      await openAppSettings();
      return false;
    }

    // 5. Para qualquer outro caso (como restrito ou limitado), consideramos como falha.
    print("[LocationService] Status da permissão não tratado: $status. Retornando falso.");
    return false;
  }

  /// Verifica permissão, serviço de GPS e, finalmente, retorna a posição atual.
  Future<Position?> getCurrentPosition() async {
    print("[LocationService] Tentando obter a posição atual...");

    // ETAPA 1: Garantir que o serviço de localização (GPS) do dispositivo está ativado.
    final isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationServiceEnabled) {
      print("[LocationService] ERRO: O serviço de localização (GPS) do dispositivo está desativado.");
      // Se o GPS estiver desligado, não há como prosseguir.
      return null;
    }
    print("[LocationService] SUCESSO: Serviço de localização (GPS) está ativado.");

    // ETAPA 2: Garantir que o aplicativo tem permissão para acessar a localização.
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      print("[LocationService] ERRO: Permissão de localização não foi concedida pelo usuário.");
      return null;
    }
    print("[LocationService] SUCESSO: O aplicativo tem permissão de localização.");


    // ETAPA 3: Se tudo estiver certo, obter a posição atual.
    try {
      print("[LocationService] Buscando coordenadas GPS...");
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15), // Timeout de 15 segundos
      );
    } catch (e) {
      print("[LocationService] ERRO CRÍTICO ao obter a localização: $e");
      return null;
    }
  }
  
  /// Inicia as atualizações periódicas de localização.
  void startLocationUpdates({required Function(Position position) onUpdate}) {
    if (_timer?.isActive ?? false) return;

    print("[LocationService] Iniciando atualizações periódicas de localização...");
    
    _timer = Timer.periodic(const Duration(minutes: 10), (timer) async {
      print("[LocationService] Timer ativado: buscando nova localização...");
      Position? position = await getCurrentPosition();
      if (position != null) {
        onUpdate(position);
      }
    });
  }

  /// Para o serviço de atualização periódica.
  void stopLocationUpdates() {
    print("[LocationService] Parando atualizações de localização.");
    _timer?.cancel();
    _timer = null;
  }
}