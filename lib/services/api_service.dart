import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ATENÇÃO: Troque a URL base pelo IP da sua máquina ou 10.0.2.2 para emulador Android
  final String _baseUrl = 'http://192.168.1.33/api';

  // Método para o login tradicional
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
      // Se o login for bem-sucedido, decodifica o JSON e o retorna
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      // Se falhar, lança uma exceção com a mensagem de erro
      throw Exception('Falha no login: ${response.body}');
    }
  }

  // Futuramente, aqui ficará a lógica para o login SSO
}