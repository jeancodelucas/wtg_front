import 'package:flutter/material.dart';
import 'package:wtg_front/screens/profile_screen.dart';
import 'package:wtg_front/services/api_service.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Importe o pacote do Google Sign In

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(); // Instância do Google Sign In

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _performLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final responseData = await _apiService.login(
        _emailController.text,
        _passwordController.text,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ProfileScreen(userData: responseData),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro no login: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _performGoogleLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // Usuário cancelou o login do Google
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Não foi possível obter o ID Token do Google.');
      }

      // TODO: Enviar o idToken para o seu backend para verificação e login
      // Atualmente, seu backend só aceita login tradicional.
      // Você precisaria de um endpoint como POST /api/auth/google que aceita { "idToken": "..." }
      // Por enquanto, vamos simular um sucesso e mostrar o token.
      
      // Simulação de resposta da API com o idToken para fins de demonstração
      final simulatedResponse = {
        "status": "ok",
        "messagem": "Login com Google bem-sucedido (simulado)",
        "code": 200,
        "user": {
          "id": 123,
          "firstName": googleUser.displayName?.split(' ').first ?? "Usuário",
          "fullName": googleUser.displayName,
          "email": googleUser.email,
          "pictureUrl": googleUser.photoUrl,
          "userType": "COMMON",
        },
        "token": idToken, // Incluindo o ID Token retornado pelo Google
      };

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ProfileScreen(userData: simulatedResponse),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro no login com Google: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Fundo com gradiente
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFff9a9e), // Cor superior esquerda (rosa/laranja)
              Color(0xFFfad0c4), // Cor do meio (amarelo claro)
              Color(0xFFa18cd1), // Cor inferior direita (roxo)
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView( // Para evitar overflow em teclados
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                  Image.asset('assets/images/LaRuaLogo.png', 
                  height: 320),
                const SizedBox(height: 20),

                // Logo "LaRua"
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6A1B9A), // Roxo escuro
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'LaRua',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Campo de E-mail
                _buildTextField(_emailController, 'E-mail', false),
                const SizedBox(height: 20),

                // Campo de Senha
                _buildTextField(_passwordController, 'Password', true),
                const SizedBox(height: 40),

                // Botão de Login Tradicional
                _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : _buildLoginButton('LOGIN', _performLogin, const Color(0xFF6A1B9A)),
                const SizedBox(height: 20),

                // Botão de Login com Google
                _isLoading
                    ? const SizedBox.shrink() // Oculta o botão Google se estiver carregando
                    : _buildGoogleLoginButton('Login with Google', _performGoogleLogin),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para construir os campos de texto
  Widget _buildTextField(TextEditingController controller, String label, bool obscureText) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9), // Fundo branco semi-transparente
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3), // Sombra leve
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          border: InputBorder.none, // Remove a borda padrão do TextField
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  // Widget auxiliar para construir os botões de login
  Widget _buildLoginButton(String text, VoidCallback onPressed, Color color) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        minimumSize: const Size(double.infinity, 50), // Largura total
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Widget auxiliar para construir o botão de Login com Google
Widget _buildGoogleLoginButton(String text, VoidCallback onPressed) {
  return ElevatedButton.icon(
    icon: Image.asset( // Já com o nome do asset corrigido
      'assets/images/google_logo.png',
      height: 24,
    ),
    // CORREÇÃO: O widget Text foi envolvido por um Flexible.
    label: Flexible(
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, color: Colors.black87),
      ),
    ),
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      minimumSize: const Size(double.infinity, 50),
      side: const BorderSide(color: Colors.grey, width: 0.5),
    ),
  );
}
}