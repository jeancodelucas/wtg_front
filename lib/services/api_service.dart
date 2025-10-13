import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ATENÇÃO: Verifique se o IP e a PORTA estão corretos para o seu ambiente.
  // Para emulador Android, use 10.0.2.2. Para dispositivo físico na mesma rede, use o IP da sua máquina.
  final String _baseUrl = 'http://192.168.0.9:8080/api';

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      // Lança uma exceção com o status code para tratamento na UI
      throw Exception('Falha no login: ${response.statusCode}');
    }
  }

  Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/forgot-password'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{'email': email}),
    );

    if (response.statusCode != 200) {
      throw Exception('Falha ao solicitar a recuperação de senha.');
    }
  }
  
  // CORREÇÃO: Método 'register' adicionado
Future<void> register(Map<String, dynamic> registrationData) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/users/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(registrationData),
    );

    if (response.statusCode != 201) { // 201 Created
      final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      
      // Lógica aprimorada para extrair a mensagem de erro
      String errorMessage = 'Erro desconhecido durante o cadastro.';
      if (errorBody['message'] != null) {
        errorMessage = errorBody['message'];
      } else if (errorBody['messages'] != null && errorBody['messages'] is Map) {
        // Pega a primeira mensagem de erro de validação
        final validationErrors = errorBody['messages'] as Map<String, dynamic>;
        if (validationErrors.isNotEmpty) {
          errorMessage = validationErrors.values.first;
        }
      }
      
      throw Exception(errorMessage);
    }
  }
}

