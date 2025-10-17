// lib/services/api_service.dart

import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class ApiService {
  final String _baseUrl = _getBaseUrl();
  String? _sessionCookie;

  void setSessionCookie(String? cookie) {
    _sessionCookie = cookie;
  }

  static String _getBaseUrl() {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080/api';
    } else {
      return 'http://192.168.1.42:8080/api';
    }
  }

  Future<Map<String, dynamic>> getCoordinatesFromAddress(Map<String, dynamic> addressData) async {
    final uri = Uri.parse('$_baseUrl/geocoding/from-address');
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      if (_sessionCookie != null) 'Cookie': _sessionCookie!,
    };

    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(addressData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorBody['error'] ?? 'Falha ao obter coordenadas.');
    }
  }

  // --- MÉTODO NOVO ---
  /// Cria uma nova promoção (evento) no backend.
  Future<Map<String, dynamic>> createPromotion(Map<String, dynamic> promotionData) async {
    final uri = Uri.parse('$_baseUrl/promotions');
     final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      if (_sessionCookie != null) 'Cookie': _sessionCookie!,
    };

    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(promotionData),
    );

    if (response.statusCode == 201) {
      // Retorna o corpo da resposta, que deve ser o UserDto atualizado
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorBody['message'] ?? 'Falha ao criar o evento.');
    }
  }

  // --- MÉTODO NOVO ---
  /// Faz o upload de uma lista de imagens para uma promoção existente.
Future<void> uploadPromotionImages(int promotionId, List<File> images) async {
    final uri = Uri.parse('$_baseUrl/promotions/$promotionId/images');
    var request = http.MultipartRequest('POST', uri);

    if (_sessionCookie != null) {
      request.headers['Cookie'] = _sessionCookie!;
    }

    for (var imageFile in images) {
      // 2. Detecta o MIME type do arquivo (ex: 'image/png', 'image/jpeg')
      final mimeType = lookupMimeType(imageFile.path);
      final mediaType = mimeType != null ? MediaType.parse(mimeType) : null;

      request.files.add(
        await http.MultipartFile.fromPath(
          'images', // O nome do campo esperado pelo backend
          imageFile.path,
          contentType: mediaType, // 3. Usa o MediaType dinâmico
        ),
      );
    }

    final response = await request.send();

    if (response.statusCode != 201) {
      final responseBody = await response.stream.bytesToString();
      throw Exception('Falha ao fazer upload das imagens: $responseBody');
    }
  }

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
        throw Exception(
            responseBody['message'] ?? 'Falha ao iniciar o registo.');
      }
    } on http.ClientException catch (e) {
      print('Erro de cliente ao iniciar registo: ${e.message}');
      throw Exception(
          'Não foi possível ligar ao servidor. Verifique a sua ligação e tente novamente.');
    }
  }

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
      throw Exception(
          responseBody['message'] ?? 'Falha na validação do token.');
    }
  }

  Future<Map<String, dynamic>> register(
      Map<String, dynamic> registrationData) async {
    final uri = Uri.parse('$_baseUrl/users/register');
    print('Enviando requisição de registo final para: $uri');
    print('Payload do registo: ${jsonEncode(registrationData)}');

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
      String errorMessage =
          errorBody['message'] ?? 'Ocorreu um erro durante o cadastro.';
      throw Exception(errorMessage);
    }
  }

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

  Future<Map<String, dynamic>> loginWithGoogle(String token,
      {double? latitude, double? longitude}) async {
    final uri = Uri.parse('$_baseUrl/auth/google');
    print('Enviando requisição de login SSO para: $uri');

    final body = <String, dynamic>{'token': token};
    if (latitude != null && longitude != null) {
      body['latitude'] = latitude;
      body['longitude'] = longitude;
    }

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(body),
      );

      print('Resposta do login SSO: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        String? rawCookie = response.headers['set-cookie'];
        if (rawCookie != null) {
          responseData['cookie'] = rawCookie;
        }
        return responseData;
      } else {
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(errorBody['error'] ?? 'Falha no login com Google');
      }
    } on http.ClientException catch (e) {
      print('Erro de cliente no login SSO: ${e.message}');
      throw Exception(
          'Não foi possível ligar ao servidor. Verifique a sua ligação e tente novamente.');
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final uri = Uri.parse('$_baseUrl/auth/forgot-password');
    print('Enviando requisição de esqueci a senha para: $uri');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'email': email}),
    );

    print('Resposta do esqueci a senha: ${response.statusCode}');
    final responseBody = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      return responseBody;
    } else {
      throw Exception(
          responseBody['message'] ?? 'Falha ao solicitar recuperação de senha.');
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final uri = Uri.parse('$_baseUrl/auth/reset-password');
    print('Enviando requisição para redefinir a senha para: $uri');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'token': token,
        'newPassword': newPassword,
      }),
    );

    print('Resposta da redefinição de senha: ${response.statusCode}');
    final responseBody = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      return responseBody;
    } else {
      throw Exception(
          responseBody['message'] ?? 'Falha ao redefinir a senha.');
    }
  }

  Future<Map<String, dynamic>> updateUser(
      Map<String, dynamic> userData, String cookie) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/users/update'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Cookie': cookie,
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

  Future<List<dynamic>> filterPromotions({
    required double latitude,
    required double longitude,
    double radius = 5.0,
  }) async {
    final uri =
        Uri.parse('$_baseUrl/promotions/filter').replace(queryParameters: {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'radius': radius.toString(),
    });

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Falha ao buscar promoções');
    }
  }
}