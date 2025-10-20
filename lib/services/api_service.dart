// lib/services/api_service.dart

import 'dart:convert';
import 'dart:io' show File, Platform;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:wtg_front/models/promotion_type.dart';

class ApiService {
  final String _baseUrl = _getBaseUrl();

  static String _getBaseUrl() {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080/api';
    } else {
      // Use o IP da sua máquina na rede local para testes no iOS
      return 'http://192.168.1.42:8080/api';
    }
  }

  Future<Map<String, dynamic>> createPromotion(
      Map<String, dynamic> promotionData, String cookie) async {
    final uri = Uri.parse('$_baseUrl/promotions');
    print('Enviando requisição para criar promoção: $uri');

    // Cria uma cópia do mapa para poder modificá-lo com segurança
    final Map<String, dynamic> payload = Map.from(promotionData);

    // --- CORREÇÃO APLICADA AQUI ---
    // Verifica se 'promotionType' é um enum e o converte para String (ex: "PARTY")
    if (payload['promotionType'] is PromotionType) {
      payload['promotionType'] = (payload['promotionType'] as PromotionType).name;
    }
    
    // Remove dados que não são enviados para a API no passo 3
    payload.remove('images');
    payload.remove('loginResponse');
    payload.remove('addressData');
    payload.remove('coordinates');


    print('Payload final: ${jsonEncode(payload)}');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Cookie': cookie,
      },
      body: jsonEncode(payload),
    );

    print('Resposta da criação de promoção: ${response.statusCode}');
    final responseBody = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 201) {
      return responseBody;
    } else {
      if (responseBody['messages'] != null) {
        throw Exception('Erro de validação: ${responseBody['messages']}');
      }
      throw Exception(responseBody['message'] ?? 'Falha ao criar o evento.');
    }
  }

  // O restante dos seus métodos (login, register, filterPromotions, etc.) continuam aqui...
  
  Future<Map<String, dynamic>> completePromotionRegistration(String promotionId, String cookie) async {
    final uri = Uri.parse('$_baseUrl/promotions/$promotionId/complete');
    print('Finalizando cadastro da promoção: $uri');

    final response = await http.patch( // Usando PATCH
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Cookie': cookie,
      },
    );

    print('Resposta da finalização: ${response.statusCode}');
    final responseBody = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      return responseBody;
    } else {
      throw Exception(responseBody['message'] ?? 'Falha ao finalizar o cadastro do evento.');
    }
  }

  Future<Map<String, dynamic>> getMyPromotion(String cookie) async {
    final uri = Uri.parse('$_baseUrl/promotions/my-promotion');
    print('Buscando promoção do usuário em: $uri');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Cookie': cookie,
      },
    );

    print('Resposta de /my-promotion: ${response.statusCode}');

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorBody['message'] ?? 'Falha ao buscar sua promoção');
    }
  }
  
  Future<List<dynamic>> getPromotionImageViews(
      int promotionId, String cookie) async {
    final uri = Uri.parse('$_baseUrl/promotions/$promotionId/image-urls');
    print('Buscando URLs das imagens em: $uri');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Cookie': cookie,
      },
    );
    print('Resposta de /image-urls: ${response.statusCode}');

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(
          errorBody['message'] ?? 'Falha ao buscar imagens da promoção');
    }
  }

  Future<void> uploadPromotionImages(String promotionId, List<File> images, String cookie) async {
    final uri = Uri.parse('$_baseUrl/promotions/$promotionId/images');
    print('Enviando imagens para: $uri');

    var request = http.MultipartRequest('POST', uri);
    request.headers['Cookie'] = cookie;

    for (var imageFile in images) {
      final mimeType = lookupMimeType(imageFile.path);
      final mediaType = mimeType != null ? MediaType.parse(mimeType) : null;

      request.files.add(
        await http.MultipartFile.fromPath(
          'images',
          imageFile.path,
          contentType: mediaType,
        ),
      );
    }

    try {
      final response = await request.send();
      print('Resposta do upload de imagens: ${response.statusCode}');
      if (response.statusCode != 201) {
        final responseBody = await response.stream.bytesToString();
        throw Exception('Falha ao enviar as imagens: $responseBody');
      }
    } catch (e) {
      throw Exception('Falha ao enviar as imagens.');
    }
  }
  
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    double? latitude,
    double? longitude,
  }) async {
    final uri = Uri.parse('$_baseUrl/auth/login');
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

    if (response.statusCode == 200) {
      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      
      String? rawCookie = response.headers['set-cookie'];
      if (rawCookie != null) {
        responseData['cookie'] = rawCookie;
      }
      return responseData;
    } else {
      final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorBody['error'] ?? 'Falha no login');
    }
  }

  Future<Map<String, double>> getCoordinatesFromAddress(Map<String, String> addressData) async {
    print('Buscando coordenadas para o endereço (função de placeholder): $addressData');
    await Future.delayed(const Duration(seconds: 1)); 
    return {
      'latitude': -8.057838,
      'longitude': -34.870639,
    };
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
      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      String? rawCookie = response.headers['set-cookie'];
      if (rawCookie != null) {
        responseData['cookie'] = rawCookie;
      }
      return responseData;

    } else {
      final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      String errorMessage =
          errorBody['message'] ?? 'Ocorreu um erro durante o cadastro.';
      throw Exception(errorMessage);
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
    required String cookie,
    double? latitude,
    double? longitude,
    double? radius,
    PromotionType? promotionType,
  }) async {
    final queryParameters = <String, String>{};
    
    if (latitude != null && longitude != null && radius != null) {
      queryParameters['latitude'] = latitude.toString();
      queryParameters['longitude'] = longitude.toString();
      queryParameters['radius'] = radius.toString();
    }

    if (promotionType != null) {
      queryParameters['promotionType'] = promotionType.name.toUpperCase();
    }

    final uri = Uri.parse('$_baseUrl/promotions/filter').replace(
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
    );

    print('Enviando requisição para: $uri');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Cookie': cookie,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Falha ao buscar promoções. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }
}