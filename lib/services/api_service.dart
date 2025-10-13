// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ATENÇÃO: Use o IP da sua máquina na rede local.
  final String _baseUrl = 'http://192.168.1.10:8080/api';

  // Método de login ATUALIZADO para incluir geolocalização
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    double? latitude,
    double? longitude,
  }) async {
    final body = <String, dynamic>{
      'email': email,
      'password': password,
    };
    if (latitude != null && longitude != null) {
      body['latitude'] = latitude;
      body['longitude'] = longitude;
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorBody['error'] ?? 'Falha no login');
    }
  }

  // NOVO método para buscar promoções com base na localização
  Future<List<dynamic>> filterPromotions({
    required double latitude,
    required double longitude,
    double radius = 5.0, // Raio padrão de 5km
  }) async {
    final uri = Uri.parse('$_baseUrl/promotions/filter').replace(queryParameters: {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'radius': radius.toString(),
    });

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        // TODO: Adicionar token de autenticação se for uma rota protegida
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Falha ao buscar promoções');
    }
  }
  
  // Seus outros métodos (register, forgotPassword) permanecem aqui...
  Future<void> register(Map<String, dynamic> registrationData) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/users/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(registrationData),
    );

    if (response.statusCode != 201) {
      final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      String errorMessage = 'Erro desconhecido durante o cadastro.';
      if (errorBody['message'] != null) {
        errorMessage = errorBody['message'];
      } else if (errorBody['messages'] != null && errorBody['messages'] is Map) {
        final validationErrors = errorBody['messages'] as Map<String, dynamic>;
        if (validationErrors.isNotEmpty) {
          errorMessage = validationErrors.values.first;
        }
      }
      throw Exception(errorMessage);
    }
  }
  Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      // Se o servidor retornar um erro, lança uma exceção.
      final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorBody['message'] ?? 'Falha ao solicitar recuperação de senha');
    }
  }
}
