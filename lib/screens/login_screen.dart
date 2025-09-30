import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wtg_front/screens/profile_screen.dart';
import 'package:wtg_front/services/api_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final ApiService _apiService;
  late final GoogleSignIn _googleSignIn;

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _googleSignIn = GoogleSignIn();
  }

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
    } on http.ClientException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro de conexão: ${e.message}')),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        String errorMessage = e.toString().replaceFirst('Exception: ', '');
        if (errorMessage.contains("401")) {
          errorMessage = "E-mail ou senha inválidos.";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
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
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Não foi possível obter o ID Token do Google.');
      }

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
        "token": idToken,
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

  Future<void> _forgotPassword() async {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Recuperar Senha'),
          content: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: "Digite seu e-mail"),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Enviar'),
              onPressed: () async {
                if (emailController.text.isNotEmpty) {
                  Navigator.of(context).pop();
                  _sendForgotPasswordRequest(emailController.text);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendForgotPasswordRequest(String email) async {
    setState(() => _isLoading = true);
    try {
      await _apiService.forgotPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Se o e-mail estiver cadastrado, um link será enviado.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Se o e-mail estiver cadastrado, um link será enviado.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Fundo com gradiente mantido
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFff9a9e),
              Color(0xFFfad0c4),
              Color(0xFFa18cd1),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset('assets/images/LaRuaLogo.png', height: 220), // Altura reduzida
                  const SizedBox(height: 10), // Espaçamento reduzido
                  
                  // Texto "LaRua"
                  const Text(
                    'LaRua',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 35), // Espaçamento reduzido

                  // Campos de Texto
                  _buildTextField(_emailController, 'E-mail', false),
                  const SizedBox(height: 20),
                  _buildTextField(
                      _passwordController, 'Password', !_isPasswordVisible),
                  const SizedBox(height: 20),

                  // Botões (sem alteração de funcionalidade)
                  if (_isLoading)
                    const CircularProgressIndicator(color: Colors.white)
                  else ...[
                    _buildLoginButton('LOGIN', _performLogin, const Color(0xFF6A1B9A)),
                    const SizedBox(height: 15),
                    _buildGoogleLoginButton('Login with Google', _performGoogleLogin),
                  ],

                  // "Esqueci minha senha" - movido para o final
                  TextButton(
                    onPressed: _forgotPassword,
                    child: const Text(
                      'Esqueci minha senha',
                      style: TextStyle(
                          color: Colors.black54, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget de campo de texto com novo design
  Widget _buildTextField(
      TextEditingController controller, String label, bool obscureText) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.black87, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        // Linha inferior
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF6A1B9A), width: 2),
        ),
        // Ícone para mostrar/ocultar senha
        suffixIcon: label == 'Password'
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              )
            : null,
      ),
    );
  }

  // Widgets de botão sem alteração
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
        minimumSize: const Size(double.infinity, 50),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildGoogleLoginButton(String text, VoidCallback onPressed) {
    return ElevatedButton.icon(
      icon: Image.asset(
        'assets/images/google_logo.png',
        height: 24,
      ),
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

