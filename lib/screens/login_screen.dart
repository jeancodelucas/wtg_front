import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wtg_front/screens/profile_screen.dart';
import 'package:wtg_front/services/api_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:wtg_front/screens/registration_screen.dart'; // Import da nova tela

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final ApiService _apiService;
  late final GoogleSignIn _googleSignIn;

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
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
    // Implementação mockada
    setState(() {
      _isLoading = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isLoading = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login com Google ainda não implementado.')),
      );
    }
  }

  Future<void> _performAppleLogin() async {
    // Implementação mockada
    setState(() {
      _isLoading = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isLoading = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login com Apple ainda não implementado.')),
      );
    }
  }

  Future<void> _forgotPassword() async {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Recuperar Senha'),
          content: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: "Digite seu e-mail",
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
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
                  'Se o e-mail existir, um link de recuperação será enviado.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${e.toString()}')),
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/LaRuaLogo.png', height: 250),
                const Text(
                  'LaRua',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                _buildTextField(
                    _emailController, 'E-mail', TextInputType.emailAddress),
                const SizedBox(height: 15),
                _buildTextField(
                    _passwordController, 'Password', TextInputType.visiblePassword),
                const SizedBox(height: 30),
                if (_isLoading)
                  const CircularProgressIndicator(color: Colors.white)
                else
                  Column(
                    children: [
                      _buildLoginButton(
                          'LOGIN', _performLogin, const Color(0xFF6A1B9A)),
                      const SizedBox(height: 15),
                      _buildGoogleLoginButton(
                          'Login with Google', _performGoogleLogin),
                      const SizedBox(height: 15),
                      _buildAppleLoginButton(
                          'Login with Apple', _performAppleLogin),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _forgotPassword,
                        child: const Text(
                          'Esqueci minha senha',
                          style: TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const RegistrationScreen(),
                          ));
                        },
                        child: const Text(
                          'Não tem uma conta? Cadastre-se',
                          style: TextStyle(
                              color: Color(0xFF6A1B9A),
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ESTE MÉTODO FOI CORRIGIDO PARA O ESTILO DA IMAGEM
  Widget _buildTextField(TextEditingController controller, String label,
      TextInputType keyboardType) {
    bool isPassword = label == 'Password';
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword && !_isPasswordVisible,
      style: const TextStyle(color: Colors.black87),
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
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
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
        height: 24.0,
        width: 24.0,
      ),
      label: Text(
        text,
        style: const TextStyle(fontSize: 18, color: Colors.black87),
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
        side: BorderSide(color: Colors.grey.shade400, width: 1),
      ),
    );
  }

  Widget _buildAppleLoginButton(String text, VoidCallback onPressed) {
    return ElevatedButton.icon(
      icon: const Icon(
        Icons.apple,
        color: Colors.white,
        size: 28.0,
      ),
      label: Text(
        text,
        style: const TextStyle(
            fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
      ),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }
}

