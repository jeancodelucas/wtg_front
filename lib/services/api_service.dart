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
      return 'http://192.168.1.42:8080/api';
    }
  }

  // NOVO: Adiciona um comentário a uma promoção
  Future<Map<String, dynamic>> createComment({
    required int promotionId,
    required String comment,
    required String cookie,
  }) async {
    final uri = Uri.parse('$_baseUrl/comments');
    print('Enviando novo comentário para: $uri');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Cookie': cookie,
      },
      body: jsonEncode({
        'promotionId': promotionId,
        'comment': comment,
      }),
    );

    print('Resposta de /comments POST: ${response.statusCode}');

    if (response.statusCode == 201) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorBody['message'] ?? 'Falha ao criar o comentário');
    }
  }

  // ... (O restante do seu código do api_service.dart permanece o mesmo)
  Future<Map<String, dynamic>> getPromotionDetail(
      int promotionId, String cookie) async {
    final uri = Uri.parse('$_baseUrl/promotions/detail/$promotionId');
    print('Buscando detalhes da promoção em: $uri');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Cookie': cookie,
      },
    );

    print('Resposta de /promotions/detail: ${response.statusCode}');

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(
          errorBody['message'] ?? 'Falha ao buscar detalhes da promoção');
    }
  }

  Future<void> deleteComment(int commentId, String cookie) async {
    final uri = Uri.parse('$_baseUrl/comments/$commentId');
    print('Deletando comentário em: $uri');

    final response = await http.delete(
      uri,
      headers: {
        'Cookie': cookie,
      },
    );

    print('Resposta da deleção do comentário: ${response.statusCode}');

    if (response.statusCode != 204) {
      throw Exception('Falha ao deletar o comentário.');
    }
  }

  Future<Map<String, dynamic>> updatePromotion(
      String promotionId,
      Map<String, dynamic> promotionData,
      List<File> newImages,
      List<String> removedImageUrls,
      String cookie) async {
    final uri = Uri.parse('$_baseUrl/promotions/$promotionId/edit');
    var request = http.MultipartRequest('PUT', uri);
    request.headers['Cookie'] = cookie;

    final Map<String, dynamic> payload = Map.from(promotionData);
    if (payload['promotionType'] != null) {
      if (payload['promotionType'] is PromotionType) {
        payload['promotionType'] =
            (payload['promotionType'] as PromotionType).name.toUpperCase();
      } else if (payload['promotionType'] is String) {
        payload['promotionType'] =
            (payload['promotionType'] as String).toUpperCase();
      }
    }
    
    payload['removedImageUrls'] = removedImageUrls;

    payload.remove('images');
    payload.remove('loginResponse');
    payload.remove('promotion');
    payload.remove('removedImages'); 

    request.files.add(
      http.MultipartFile.fromString(
        'dto',
        jsonEncode(payload),
        contentType: MediaType('application', 'json'),
      ),
    );

    for (var imageFile in newImages) {
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

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorBody['message'] ?? 'Falha ao atualizar o evento');
    }
  }

  Future<Map<String, dynamic>> createPromotion(
      Map<String, dynamic> promotionData, String cookie) async {
    final uri = Uri.parse('$_baseUrl/promotions');
    final Map<String, dynamic> payload = Map.from(promotionData);

    if (payload['promotionType'] is PromotionType) {
      payload['promotionType'] = (payload['promotionType'] as PromotionType).name;
    }
    
    payload.remove('images');
    payload.remove('loginResponse');
    payload.remove('addressData');
    payload.remove('coordinates');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Cookie': cookie,
      },
      body: jsonEncode(payload),
    );

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

  Future<Map<String, dynamic>> completePromotionRegistration(String promotionId, String cookie) async {
    final uri = Uri.parse('$_baseUrl/promotions/$promotionId/complete');
    final response = await http.patch(
      uri,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Cookie': cookie,
      },
    );

    final responseBody = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      return responseBody;
    } else {
      throw Exception(responseBody['message'] ?? 'Falha ao finalizar o cadastro do evento.');
    }
  }

  Future<Map<String, dynamic>> getMyPromotion(String cookie) async {
    final uri = Uri.parse('$_baseUrl/promotions/my-promotion');
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
      final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorBody['message'] ?? 'Falha ao buscar sua promoção');
    }
  }
  
  Future<List<dynamic>> getPromotionImageViews(
      int promotionId, String cookie) async {
    final uri = Uri.parse('$_baseUrl/promotions/$promotionId/image-urls');
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
      final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(
          errorBody['message'] ?? 'Falha ao buscar imagens da promoção');
    }
  }

  Future<void> uploadPromotionImages(String promotionId, List<File> images, String cookie) async {
    final uri = Uri.parse('$_baseUrl/promotions/$promotionId/images');
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
    await Future.delayed(const Duration(seconds: 1)); 
    return {
      'latitude': -8.057838,
      'longitude': -34.870639,
    };
  }
  
  Future<Map<String, dynamic>> initiateRegistration(String email) async {
    final uri = Uri.parse('$_baseUrl/users/register');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'email': email}),
      );

      final responseBody = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        return responseBody;
      } else {
        throw Exception(
            responseBody['message'] ?? 'Falha ao iniciar o registo.');
      }
    } on http.ClientException catch (e) {
      throw Exception(
          'Não foi possível ligar ao servidor. Verifique a sua ligação e tente novamente.');
    }
  }

  Future<Map<String, dynamic>> validateToken(String email, String token) async {
    final uri = Uri.parse('$_baseUrl/users/register');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'email': email, 'token': token}),
    );

    final responseBody = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      return responseBody;
    } else {
      throw Exception(
          responseBody['message'] ?? 'Falha na validação do token.');
    }
  }

  Future<void> deletePromotion(String promotionId, String cookie) async {
    final uri = Uri.parse('$_baseUrl/promotions/$promotionId');
    final response = await http.delete(uri, headers: {'Cookie': cookie});
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Falha ao deletar o evento');
    }
  }

  Future<Map<String, dynamic>> register(
      Map<String, dynamic> registrationData) async {
    final uri = Uri.parse('$_baseUrl/users/register');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(registrationData),
    );

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
      throw Exception(
          'Não foi possível ligar ao servidor. Verifique a sua ligação e tente novamente.');
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final uri = Uri.parse('$_baseUrl/auth/forgot-password');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'email': email}),
    );

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
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'token': token,
        'newPassword': newPassword,
      }),
    );

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

  Future<List<dynamic>> getMyPromotions(String cookie) async {
    final uri = Uri.parse('$_baseUrl/promotions/my-promotions');
    final response = await http.get(uri, headers: {
      'Cookie': cookie,
    });

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else if (response.statusCode == 404) {
      return [];
    }
    else {
      throw Exception('Falha ao buscar seus eventos');
    }
  }

Future<String?> uploadProfilePicture(File image, String cookie) async {
    final uri = Uri.parse('$_baseUrl/users/picture/upload');
    var request = http.MultipartRequest('POST', uri);
    request.headers['Cookie'] = cookie;

    final mimeType = lookupMimeType(image.path);
    final mediaType = mimeType != null ? MediaType.parse(mimeType) : null;

    request.files.add(
      await http.MultipartFile.fromPath(
        'picture',
        image.path,
        contentType: mediaType,
      ),
    );

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);
      return data['pictureUrl'];
    } else {
      final responseBody = await response.stream.bytesToString();
      throw Exception('Falha ao enviar a imagem: $responseBody');
    }
  }
}