// lib/screens/auth_screen.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wtg_front/screens/reset_password/reset_token_screen.dart';
import 'package:wtg_front/screens/registration/2_token_screen.dart';
import 'package:wtg_front/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:wtg_front/services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wtg_front/screens/home_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:wtg_front/screens/registration/additional_info_screen.dart';
import 'dart:io' show Platform;

// --- PALETA DE CORES ---
const Color primaryColor = Color(0xFF214886);
const Color lightTextColor = Color(0xFF6B7280);
const Color darkTextColor = Color(0xFF1F2937);
const Color backgroundColor = Colors.white;
const Color fieldBackgroundColor = Color(0xFFF9FAFB);
const Color togglerBackgroundColor = Color(0xFFE5E7EB);
const Color borderColor = Color(0xFFD1D5DB);

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _showLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  final _locationService = LocationService();
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _isPasswordVisible = false;

  Position? _currentPosition;

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    final position = await _locationService.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentPosition = position;
      });
    }
  }

  void _toggleForm(bool showLogin) {
    if (_showLogin != showLogin) {
      _formKey.currentState?.reset();
      _emailController.clear();
      _passwordController.clear();
      FocusScope.of(context).unfocus();
      setState(() {
        _showLogin = showLogin;
      });
    }
  }

  Future<void> _handlePrimaryAction() async {
    if (_showLogin) {
      _performLogin();
    } else {
      _initiateRegistration();
    }
  }

  Future<void> _performLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final position = _currentPosition;

    try {
      final responseData = await _apiService.login(
        email: _emailController.text,
        password: _passwordController.text,
        latitude: position?.latitude,
        longitude: position?.longitude,
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              initialPosition: position,
              loginResponse: responseData,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e is http.ClientException
            ? 'Erro de conexão: ${e.message}'
            : e.toString().replaceFirst('Exception: ', '');
        if (errorMessage.contains("401")) {
          errorMessage = "E-mail ou senha inválidos.";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _initiateRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      await _apiService.initiateRegistration(_emailController.text);
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TokenScreen(
              email: _emailController.text,
              latitude: _currentPosition?.latitude,
              longitude: _currentPosition?.longitude,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${e.toString().replaceAll("Exception: ", "")} Volte para a tela de login para continuar.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Não foi possível obter o token do Google.');
      }

      final position = await _locationService.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }

      final responseData = await _apiService.loginWithGoogle(
        idToken,
        latitude: position?.latitude,
        longitude: position?.longitude,
      );

      if (mounted) {
        final bool isNewUser = responseData['isNewUser'] ?? false;

        if (isNewUser) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AdditionalInfoScreen(
                registrationData: {
                  ...responseData,
                  'isSsoUser': true,
                  'authToken': responseData['token'],
                  'latitude': position?.latitude,
                  'longitude': position?.longitude,
                },
              ),
            ),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                initialPosition: _currentPosition,
                loginResponse: responseData,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao fazer login com Google: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- MÉTODO REESCRITO COM NOVO DESIGN E TAMANHO AJUSTADO ---
  Future<void> _forgotPassword() async {
    final emailForResetController =
        TextEditingController(text: _emailController.text);
    
    Future<void> sendRequest(
        void Function(void Function()) setDialogState) async {
      if (emailForResetController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, preencha o e-mail.')),
        );
        return;
      }
      
      setDialogState(() => _isLoading = true);

      try {
        await _apiService.forgotPassword(emailForResetController.text);
        if (!mounted) return;

        Navigator.of(context).pop();

        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) =>
              ResetTokenScreen(email: emailForResetController.text),
        ));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Código de recuperação enviado para seu e-mail!')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Erro: ${e.toString().replaceAll("Exception: ", "")}')),
        );
      } finally {
        if (mounted) {
          _isLoading = false;
          setDialogState(() {});
        }
      }
    }

    // Conteúdo comum para ambos os popups
    Widget buildContent(Widget emailField) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.vpn_key_outlined,
                color: primaryColor, size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            'Redefinir senha',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: darkTextColor),
          ),
          const SizedBox(height: 8),
          const Text(
            'Digite seu e-mail para receber o código de recuperação.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: lightTextColor),
          ),
          const SizedBox(height: 24),
          emailField,
        ],
      );
    }

    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return CupertinoAlertDialog(
                content: Material( // Envolve com Material para evitar problemas de tema
                  color: Colors.transparent,
                  child: buildContent(
                    CupertinoTextField(
                      controller: emailForResetController,
                      placeholder: 'email@example.com',
                      keyboardType: TextInputType.emailAddress,
                      decoration: BoxDecoration(
                        color: CupertinoColors.extraLightBackgroundGray,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                actions: [
                  CupertinoDialogAction(
                    child:
                        const Text('Cancelar', style: TextStyle(color: primaryColor)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    onPressed:
                        _isLoading ? null : () => sendRequest(setDialogState),
                    child: _isLoading
                        ? const CupertinoActivityIndicator()
                        : const Text('Enviar',
                            style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
                content: SizedBox( // Garante largura e altura suficientes
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: buildContent(
                    TextField(
                      controller: emailForResetController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: "E-mail",
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                actions: [
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: primaryColor),
                    child: const Text('Cancelar'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                    ),
                    onPressed:
                        _isLoading ? null : () => sendRequest(setDialogState),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Enviar'),
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset('assets/images/LaRuaLogo.png', height: 140),
                  const SizedBox(height: 16),
                  Image.asset('assets/images/LaRuaNameLogo.png', height: 40),
                  const SizedBox(height: 40),
                  _AuthToggler(isLogin: _showLogin, onToggle: _toggleForm),
                  const SizedBox(height: 32),
                  const Text('Digite seu e-mail',
                      style: TextStyle(
                          color: darkTextColor,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                        filled: true,
                        fillColor: fieldBackgroundColor,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none)),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira um e-mail.';
                      }
                      final emailRegex =
                          RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(value)) {
                        return 'Por favor, insira um e-mail válido.';
                      }
                      return null;
                    },
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _showLogin ? 1.0 : 0.0,
                      child: _showLogin
                          ? _buildLoginFields()
                          : const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildPrimaryButton(),
                  const SizedBox(height: 32),
                  _buildDivider(),
                  const SizedBox(height: 32),
                  _buildSocialLoginRow(_handleGoogleSignIn),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text('Senha',
            style:
                TextStyle(fontWeight: FontWeight.bold, color: darkTextColor)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
              filled: true,
              fillColor: fieldBackgroundColor,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              suffixIcon: IconButton(
                  icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: lightTextColor),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible))),
          validator: (value) {
            if (_showLogin && (value == null || value.isEmpty)) {
              return 'Por favor, insira sua senha.';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildOptionsRow(),
      ],
    );
  }

  Widget _buildOptionsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (value) =>
                    setState(() => _rememberMe = value ?? false),
                activeColor: primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Mantenha-me conectado',
                style: TextStyle(color: darkTextColor)),
          ],
        ),
        TextButton(
          onPressed: _forgotPassword,
          child: const Text(
            'Esqueci a senha',
            style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handlePrimaryAction,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(double.infinity, 50),
        elevation: 0,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 3))
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _showLogin
                  ? const Text('Entrar',
                      key: ValueKey('login_text'),
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                  : const Row(
                      key: ValueKey('register_row'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Continuar',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward),
                      ],
                    ),
            ),
    );
  }
}

class _AuthToggler extends StatelessWidget {
  final bool isLogin;
  final ValueChanged<bool> onToggle;

  const _AuthToggler({required this.isLogin, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: togglerBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildToggleButton('Entrar', isLogin, () => onToggle(true)),
          _buildToggleButton('Cadastre-se', !isLogin, () => onToggle(false)),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String title, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: isSelected
              ? BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 1))
                  ],
                )
              : null,
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? darkTextColor : lightTextColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildDivider() {
  return Row(
    children: [
      Expanded(child: Divider(color: borderColor)),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Text('Ou', style: TextStyle(color: lightTextColor)),
      ),
      Expanded(child: Divider(color: borderColor)),
    ],
  );
}

Widget _buildSocialLoginRow(VoidCallback onGoogleTap) {
  return Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: onGoogleTap,
          icon: Image.asset('assets/images/google_logo.png', height: 24),
          label: const Text(''),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: const BorderSide(color: borderColor),
          ),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () {
            /* TODO: Apple Login */
          },
          icon: const Icon(Icons.apple, color: Colors.black, size: 28),
          label: const Text(''),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: const BorderSide(color: borderColor),
          ),
        ),
      ),
    ],
  );
}