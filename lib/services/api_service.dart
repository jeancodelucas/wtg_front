// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ATENÇÃO: Use o IP da sua máquina na rede local.
  final String _baseUrl = 'http://192.168.1.42:8080/api';

    // NOVO: Etapa 1 - Inicia o registro e solicita o token
  Future<Map<String, dynamic>> initiateRegistration(String email) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/users/register'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'email': email}),
    );

    final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) {
      return responseBody;
    } else {
      throw Exception(responseBody['message'] ?? 'Falha ao iniciar o registro.');
    }
  }

    // NOVO: Etapa 2 - Valida o token enviado por e-mail
  Future<Map<String, dynamic>> validateToken(String email, String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/users/register'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'email': email, 'token': token}),
    );

    final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) {
      return responseBody;
    } else {
      throw Exception(responseBody['message'] ?? 'Falha na validação do token.');
    }
  }

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
  
  // Etapa Final - Registra o usuário com todos os dados
  Future<Map<String, dynamic>> register(Map<String, dynamic> registrationData) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/users/register'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(registrationData),
    );

    if (response.statusCode == 201) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
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
  Future<Map<String, dynamic>> loginWithGoogle(String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/google'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'token': token}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorBody['error'] ?? 'Falha no login com Google');
    }
  }

  // NOVO método para ATUALIZAR o usuário
  Future<Map<String, dynamic>> updateUser(Map<String, dynamic> userData, String authToken) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/users/update'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $authToken', // Assumindo autenticação via Bearer Token
      },
      body: jsonEncode(userData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorBody['message'] ?? 'Falha ao atualizar usuário');
    }
  }
}

