// lib/services/api_service.dart

import 'dart:convert';
import 'dart:io' show Platform; // Import necessário para verificar a plataforma
import 'package:http/http.dart' as http;

class ApiService {
  /// Função privada que determina a URL base correta para o backend.
  /// Isto é crucial para o desenvolvimento em diferentes plataformas.
  String _getBaseUrl() {
    if (Platform.isAndroid) {
      // O emulador Android usa este endereço especial para aceder ao 'localhost' da máquina anfitriã.
      return 'http://10.0.2.2:8080/api';
    } else {
      // O simulador iOS, Web, macOS e Windows podem usar 'localhost' diretamente.
      return 'http://localhost:8080/api';
    }
  }

  // A _baseUrl agora é inicializada de forma segura usando a função acima.
  late final String _baseUrl = _getBaseUrl();

  /// ETAPA 1 DO REGISTO: Envia o e-mail do utilizador para receber um token de verificação.
  Future<Map<String, dynamic>> initiateRegistration(String email) async {
    final uri = Uri.parse('$_baseUrl/users/register');
    print('Enviando requisição de início de registo para: $uri');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'email': email}),
      );

      print('Resposta do início de registo: ${response.statusCode}');
      final responseBody = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        return responseBody;
      } else {
        throw Exception(responseBody['message'] ?? 'Falha ao iniciar o registo.');
      }
    } on http.ClientException catch (e) {
      print('Erro de cliente ao iniciar registo: ${e.message}');
      throw Exception('Não foi possível ligar ao servidor. Verifique a sua ligação e tente novamente.');
    }
  }

  /// ETAPA 2 DO REGISTO: Valida o token recebido por e-mail.
  Future<Map<String, dynamic>> validateToken(String email, String token) async {
    final uri = Uri.parse('$_baseUrl/users/register');
    print('Enviando requisição de validação de token para: $uri');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'email': email, 'token': token}),
    );

    print('Resposta da validação do token: ${response.statusCode}');
    final responseBody = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      return responseBody;
    } else {
      throw Exception(responseBody['message'] ?? 'Falha na validação do token.');
    }
  }

  /// ETAPA FINAL DO REGISTO: Envia todos os dados do utilizador para criar a conta.
  Future<Map<String, dynamic>> register(Map<String, dynamic> registrationData) async {
    final uri = Uri.parse('$_baseUrl/users/register');
    print('Enviando requisição de registo final para: $uri');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(registrationData),
    );

    print('Resposta do registo final: ${response.statusCode}');
    
    if (response.statusCode == 201) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      String errorMessage = errorBody['message'] ?? 'Ocorreu um erro durante o cadastro.';
      throw Exception(errorMessage);
    }
  }

  /// Realiza o login do utilizador com e-mail e palavra-passe.
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    double? latitude,
    double? longitude,
  }) async {
    final uri = Uri.parse('$_baseUrl/auth/login');
    print('Enviando requisição de login para: $uri');

    final body = <String, dynamic>{'email': email, 'password': password};
    if (latitude != null && longitude != null) {
      body['latitude'] = latitude;
      body['longitude'] = longitude;
    }

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(body),
    );

    print('Resposta do login: ${response.statusCode}');

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorBody['error'] ?? 'Falha no login');
    }
  }

  /// Realiza o login ou registo de um utilizador através do token do Google (SSO).
  Future<Map<String, dynamic>> loginWithGoogle(String token) async {
    final uri = Uri.parse('$_baseUrl/auth/google');
    print('Enviando requisição de login SSO para: $uri');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'token': token}),
      );

      print('Resposta do login SSO: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(errorBody['error'] ?? 'Falha no login com Google');
      }
    } on http.ClientException catch (e) {
      print('Erro de cliente no login SSO: ${e.message}');
      throw Exception('Não foi possível ligar ao servidor. Verifique a sua ligação e tente novamente.');
    }
  }

  /// Envia um pedido para redefinição de palavra-passe.
  Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorBody['message'] ?? 'Falha ao solicitar recuperação de senha');
    }
  }

  /// Atualiza os dados de um utilizador autenticado.
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

  /// Filtra promoções com base na localização e raio.
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
}