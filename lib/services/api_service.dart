import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ATENÇÃO: Verifique se o IP e a PORTA estão corretos.
  final String _baseUrl = 'http://192.168.1.33:8080/api';

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
      // Propaga o erro para a tela de login poder tratar.
      throw Exception('Falha no login: ${response.statusCode}');
    }
  }

  // Novo método para "esqueci minha senha"
  Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/forgot-password'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
      }),
    );

    if (response.statusCode != 200) {
      // Se o backend retornar um erro (ex: e-mail não encontrado), isso será lançado.
      final responseBody = jsonDecode(response.body);
      throw Exception(responseBody['message'] ?? 'Falha ao solicitar redefinição de senha.');
    }
  }
}

