import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wtg_front/screens/reset_password/reset_token_screen.dart';
import 'package:wtg_front/screens/registration/2_token_screen.dart';
import 'package:wtg_front/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:wtg_front/services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wtg_front/screens/home_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:wtg_front/screens/registration/additional_info_screen.dart';

// --- PALETA DE CORES ATUALIZADA ---
const Color loginTabActiveColor = Color(0xFFF6A61F);
const Color registerTabActiveColor = Color(0xFFec9827);
const Color primaryButtonColor = Color(0xFFdb4939);
const Color labelColor = Color(0xFF002c58);

const Color lightTextColor = Color(0xFF6B7280);
const Color darkTextColor = Color(0xFF1F2937);
const Color backgroundColor = Colors.white;
const Color togglerBackgroundColor = Color(0xFFE5E7EB);

// --- NOVAS CORES PARA OS INPUTS ---
const Color inputFocusColor = Color(0xFF1E3799); // Cor solicitada
const Color placeholderColor = Color(0xFFE0E0E0); // Cor da borda padrão


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
  
  Future<void> _saveSessionCookie(String? cookie) async {
    if (cookie == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_cookie', cookie);
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
      
      await _saveSessionCookie(responseData['cookie']);

      if (mounted) {
        final bool isRegistrationComplete = responseData['isRegistrationComplete'] ?? false;

        if (isRegistrationComplete) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                initialPosition: position,
                loginResponse: responseData,
              ),
            ),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AdditionalInfoScreen(
                registrationData: {
                  ...responseData,
                  'isSsoUser': false, 
                },
              ),
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
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
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
      
      await _saveSessionCookie(responseData['cookie']);

      if (mounted) {
        final bool isRegistrationComplete = responseData['isRegistrationComplete'] ?? false;

        if (isRegistrationComplete) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                initialPosition: _currentPosition,
                loginResponse: responseData,
              ),
            ),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AdditionalInfoScreen(
                registrationData: {
                  ...responseData,
                  'isSsoUser': true,
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao fazer login com Google: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _forgotPassword() async {
    final emailForResetController = TextEditingController(text: _emailController.text);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> sendRequest() async {
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
                  builder: (context) => ResetTokenScreen(email: emailForResetController.text),
                ));

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Código de recuperação enviado para seu e-mail!')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro: ${e.toString().replaceAll("Exception: ", "")}')),
                );
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: loginTabActiveColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.vpn_key_outlined, color: loginTabActiveColor, size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Redefinir senha',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkTextColor),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Digite seu e-mail para receber o código de recuperação.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: lightTextColor),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: emailForResetController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: "email@example.com",
                      border: OutlineInputBorder(),
                    ),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _isLoading ? null : sendRequest,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Enviar', style: TextStyle(color: Colors.white)),
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
                  Image.asset('assets/images/Novalogo.png', height: 140),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 60,
                    child: Image.asset(
                      'assets/images/LaRuaNameLogo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _AuthToggler(isLogin: _showLogin, onToggle: _toggleForm),
                  const SizedBox(height: 32),
                  
                  // --- INPUTS ATUALIZADOS ---
                  _buildTextField(
                    label: 'Digite seu e-mail',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Por favor, insira um e-mail.';
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(value)) return 'Por favor, insira um e-mail válido.';
                      return null;
                    },
                  ),
                  
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _showLogin ? 1.0 : 0.0,
                      child: _showLogin ? _buildLoginFields() : const SizedBox.shrink(),
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

  // --- NOVO WIDGET PADRONIZADO DE INPUT ---
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool isObscured = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: labelColor, fontSize: 16)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          obscureText: isObscured,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: placeholderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: placeholderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: inputFocusColor, width: 2),
            ),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
  
  Widget _buildLoginFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Senha',
          controller: _passwordController,
          isObscured: !_isPasswordVisible,
          validator: (value) {
            if (_showLogin && (value == null || value.isEmpty)) return 'Por favor, insira sua senha.';
            return null;
          },
          suffixIcon: IconButton(
            icon: Icon(_isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: lightTextColor),
            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible)
          ),
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
                onChanged: (value) => setState(() => _rememberMe = value ?? false),
                activeColor: loginTabActiveColor,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Mantenha-me conectado', style: TextStyle(color: darkTextColor)),
          ],
        ),
        TextButton(
          onPressed: _forgotPassword,
          child: const Text('Esqueci a senha', style: TextStyle(fontWeight: FontWeight.bold, color: loginTabActiveColor)),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handlePrimaryAction,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryButtonColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(double.infinity, 50),
        elevation: 0,
      ),
      child: _isLoading
          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _showLogin
                  ? const Text('Entrar', key: ValueKey('login_text'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                  : const Row(
                      key: ValueKey('register_row'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Continuar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    final Color activeColor = title == 'Entrar' ? loginTabActiveColor : registerTabActiveColor;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 1))
                  ]
                : [],
          ),
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
      Expanded(child: Divider(color: placeholderColor)),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Text('Ou', style: TextStyle(color: lightTextColor)),
      ),
      Expanded(child: Divider(color: placeholderColor)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: const BorderSide(color: placeholderColor),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: const BorderSide(color: placeholderColor),
          ),
        ),
      ),
    ],
  );
}