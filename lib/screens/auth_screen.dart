// lib/screens/auth_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wtg_front/screens/main_screen.dart';
import 'package:wtg_front/screens/reset_password/reset_token_screen.dart';
import 'package:wtg_front/screens/registration/2_token_screen.dart';
import 'package:wtg_front/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:wtg_front/services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:wtg_front/screens/registration/additional_info_screen.dart';

// --- PALETA DE CORES PADRONIZADA ---
const Color darkBackgroundColor = Color(0xFF1A202C);
const Color primaryTextColor = Colors.white;
const Color secondaryTextColor = Color(0xFFA0AEC0);
const Color fieldBackgroundColor = Color(0xFF2D3748);
const Color fieldBorderColor = Color(0xFF4A5568);
const Color primaryButtonColor = Color(0xFFE53E3E);

const Color loginTabActiveColor = Color(0xFFF6AD55); // Laranja para "Entrar"
const Color registerTabActiveColor = Color(0xFF4299E1); // Azul para "Cadastre-se"
const Color darkTextColor = Color(0xFF1F2937);
const Color lightTextColor = Color(0xFF6B7280);

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

  // --- NENHUMA ALTERAÇÃO NA LÓGICA ABAIXO ---

  Future<void> _initializeLocation() async {
    final position = await _locationService.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentPosition = position;
      });
    }
  }

  Future<void> _saveSessionCookie(String? rawCookie) async {
    if (rawCookie == null) return;
    String? sessionCookie = rawCookie.split(';')[0];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_cookie', sessionCookie);
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

    try {
      final responseData = await _apiService.login(
        email: _emailController.text,
        password: _passwordController.text,
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
      );

      await _saveSessionCookie(responseData['cookie']);

      if (mounted) {
        final bool isRegistrationComplete =
            responseData['isRegistrationComplete'] ?? false;
        if (isRegistrationComplete) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (context) => MainScreen(loginResponse: responseData)),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AdditionalInfoScreen(
                  registrationData: {...responseData, 'isSsoUser': false}),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e is http.ClientException
            ? 'Erro de conexão: ${e.message}'
            : e.toString().replaceFirst('Exception: ', '');
        if (errorMessage.contains("401")) {
          errorMessage = "E-mail ou senha inválidos.";
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage)));
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
                  '${e.toString().replaceAll("Exception: ", "")} Volte para a tela de login para continuar.')),
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
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      if (idToken == null)
        throw Exception('Não foi possível obter o token do Google.');

      final position = await _locationService.getCurrentPosition();
      if (mounted)
        setState(() {
          _currentPosition = position;
        });

      final responseData = await _apiService.loginWithGoogle(
        idToken,
        latitude: position?.latitude,
        longitude: position?.longitude,
      );

      await _saveSessionCookie(responseData['cookie']);

      if (mounted) {
        final bool isRegistrationComplete =
            responseData['isRegistrationComplete'] ?? false;
        if (isRegistrationComplete) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (context) => MainScreen(loginResponse: responseData)),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AdditionalInfoScreen(
                  registrationData: {...responseData, 'isSsoUser': true}),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final emailForResetController =
        TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> sendRequest() async {
              if (emailForResetController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor, preencha o e-mail.')));
                return;
              }
              setDialogState(() => _isLoading = true);
              try {
                await _apiService
                    .forgotPassword(emailForResetController.text);
                if (!mounted) return;
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        ResetTokenScreen(email: emailForResetController.text)));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Código de recuperação enviado para seu e-mail!')));
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        'Erro: ${e.toString().replaceAll("Exception: ", "")}')));
              } finally {
                if (mounted) {
                  _isLoading = false;
                  setDialogState(() {});
                }
              }
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: loginTabActiveColor.withOpacity(0.1),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.vpn_key_outlined,
                        color: loginTabActiveColor, size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text('Redefinir senha',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: darkTextColor)),
                  const SizedBox(height: 8),
                  const Text(
                      'Digite seu e-mail para receber o código de recuperação.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: lightTextColor)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: emailForResetController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                        hintText: "email@example.com",
                        border: OutlineInputBorder()),
                    onSubmitted: (_) => sendRequest(),
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: darkTextColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancelar'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryButtonColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _isLoading ? null : sendRequest,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Enviar',
                                style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  // --- BUILD METHOD E WIDGETS DE UI ATUALIZADOS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset('assets/images/Novalogo.png', height: 120),
                  const SizedBox(height: 8),
                  SizedBox(
                      height: 50,
                      child: Image.asset('assets/images/LaRuaNameLogo.png',
                          fit: BoxFit.contain)),
                  const SizedBox(height: 48),
                  _AuthToggler(isLogin: _showLogin, onToggle: _toggleForm),
                  const SizedBox(height: 32),
                  _buildTextField(
                    label: 'Seu e-mail',
                    controller: _emailController,
                    icon: Icons.alternate_email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Por favor, insira um e-mail.';
                      final emailRegex =
                          RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(value))
                        return 'Por favor, insira um e-mail válido.';
                      return null;
                    },
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _showLogin
                        ? _buildLoginFields()
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 32),
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool isObscured = false,
    Widget? suffixIcon,
  }) {
    final focusColor =
        _showLogin ? loginTabActiveColor : registerTabActiveColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: secondaryTextColor,
                fontSize: 16)),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          obscureText: isObscured,
          style: const TextStyle(
              color: primaryTextColor, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: focusColor, size: 22),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: fieldBackgroundColor,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: focusColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        _buildTextField(
          label: 'Sua senha',
          controller: _passwordController,
          isObscured: !_isPasswordVisible,
          icon: Icons.lock_outline,
          validator: (value) {
            if (_showLogin && (value == null || value.isEmpty))
              return 'Por favor, insira sua senha.';
            return null;
          },
          suffixIcon: IconButton(
              icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: secondaryTextColor),
              onPressed: () =>
                  setState(() => _isPasswordVisible = !_isPasswordVisible)),
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
        GestureDetector(
          onTap: () => setState(() => _rememberMe = !_rememberMe),
          child: Row(
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: (value) =>
                    setState(() => _rememberMe = value ?? false),
                activeColor: loginTabActiveColor,
                checkColor: darkBackgroundColor,
                side: const BorderSide(color: secondaryTextColor, width: 2),
              ),
              const Text('Manter conectado',
                  style: TextStyle(color: secondaryTextColor)),
            ],
          ),
        ),
        TextButton(
          onPressed: _forgotPassword,
          child: const Text('Esqueci a senha',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: loginTabActiveColor)),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handlePrimaryAction,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            _showLogin ? loginTabActiveColor : primaryButtonColor,
        foregroundColor:
            _showLogin ? darkBackgroundColor : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: const Size(double.infinity, 60),
        elevation: 3,
        shadowColor: (_showLogin ? loginTabActiveColor : primaryButtonColor)
            .withOpacity(0.4),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 3))
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.5),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Text(
                _showLogin ? 'Entrar' : 'Continuar',
                key: ValueKey<bool>(_showLogin),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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
          color: fieldBackgroundColor, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          _buildToggleButton('Entrar', isLogin, () => onToggle(true)),
          _buildToggleButton('Cadastre-se', !isLogin, () => onToggle(false)),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String title, bool isSelected, VoidCallback onTap) {
    final Color activeColor =
        _isLogin(title) ? loginTabActiveColor : registerTabActiveColor;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? (_isLogin(title)
                        ? darkBackgroundColor
                        : primaryTextColor)
                    : secondaryTextColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isLogin(String title) => title == 'Entrar';
}

Widget _buildDivider() {
  return Row(
    children: [
      const Expanded(child: Divider(color: fieldBorderColor)),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Text('Ou', style: TextStyle(color: secondaryTextColor)),
      ),
      const Expanded(child: Divider(color: fieldBorderColor)),
    ],
  );
}

Widget _buildSocialLoginRow(VoidCallback onGoogleTap) {
  return Row(
    children: [
      Expanded(
        child: OutlinedButton(
          onPressed: onGoogleTap,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            side: const BorderSide(color: fieldBorderColor),
          ),
          child: Image.asset('assets/images/google_logo.png', height: 26),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: OutlinedButton(
          onPressed: () {
            /* TODO: Apple Login */
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            side: const BorderSide(color: fieldBorderColor),
          ),
          child: const Icon(Icons.apple, color: Colors.white, size: 28),
        ),
      ),
    ],
  );
}