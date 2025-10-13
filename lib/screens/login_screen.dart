// lib/screens/auth_screen.dart

import 'package:flutter/material.dart';
import 'package:wtg_front/screens/additional_info_screen.dart';
import 'package:wtg_front/services/api_service.dart';
import 'package:wtg_front/screens/profile_screen.dart';
import 'package:http/http.dart' as http;
import 'package:wtg_front/services/location_service.dart';
import 'package:geolocator/geolocator.dart';

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
                  SizedBox(
                    height: 140,
                    width: 140,
                    child: ClipOval(child: Image.asset('assets/images/LaRuaLogo.png')),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 40,
                    child: Image.asset('assets/images/LaRuaNameLogo.png'),
                  ),
                  const SizedBox(height: 40),
                  _AuthToggler(isLogin: _showLogin, onToggle: _toggleForm),
                  const SizedBox(height: 24),
                  _SharedTextField(
                    controller: _emailController,
                    label: 'Email',
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Por favor, insira um e-mail.';
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(value)) return 'Por favor, insira um e-mail válido.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _SharedPasswordField(controller: _passwordController, label: 'Senha'),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return SizeTransition(
                        sizeFactor: animation,
                        axisAlignment: -1.0,
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: _showLogin
                        ? _LoginFormContent(
                            key: const ValueKey('login_content'),
                            formKey: _formKey,
                            emailController: _emailController,
                            passwordController: _passwordController,
                          )
                        : _RegistrationFormContent(
                            key: const ValueKey('register_content'),
                            formKey: _formKey,
                            emailController: _emailController,
                            passwordController: _passwordController,
                            onSuccess: () => _toggleForm(true),
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
}

// --- Conteúdo do Formulário de Login ---
class _LoginFormContent extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;

  const _LoginFormContent({super.key, required this.formKey, required this.emailController, required this.passwordController});

  @override
  __LoginFormContentState createState() => __LoginFormContentState();
}

class __LoginFormContentState extends State<_LoginFormContent> {
  final _apiService = ApiService();
  final _locationService = LocationService();
  bool _isLoading = false;
  bool _rememberMe = false;

  Future<void> _performLogin() async {
    FocusScope.of(context).unfocus();
    if (widget.formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final position = await _locationService.getCurrentPosition();

      try {
        final responseData = await _apiService.login(
          email: widget.emailController.text,
          password: widget.passwordController.text,
          latitude: position?.latitude,
          longitude: position?.longitude,
        );
        if (mounted) {
          // Navegação para a tela Home com a posição inicial (se houver)
          // Navigator.of(context).pushReplacement(
          //   MaterialPageRoute(
          //     builder: (context) => HomeScreen(initialPosition: position),
          //   ),
          // );

          // Navegação temporária para a tela de profile
           Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ProfileScreen(userData: responseData),
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
  }

  // --- LÓGICA DE ESQUECI A SENHA MOVIDA PARA CÁ ---
  Future<void> _forgotPassword() async {
    final emailDialogController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Recuperar Senha'),
          content: TextField(
            controller: emailDialogController,
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
                if (emailDialogController.text.isNotEmpty) {
                  Navigator.of(context).pop();
                  _sendForgotPasswordRequest(emailDialogController.text);
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
      // O erro estava aqui: a chamada agora é feita usando a instância _apiService deste widget
      await _apiService.forgotPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Se o e-mail existir, um link de recuperação será enviado.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao solicitar recuperação: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        _buildOptionsRow(),
        const SizedBox(height: 24),
        _buildPrimaryButton('Entrar', _performLogin, _isLoading, false),
        const SizedBox(height: 32),
        _buildDivider(),
        const SizedBox(height: 32),
        _buildSocialLoginRow(),
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
                activeColor: primaryColor,
                checkColor: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Mantenha-me conectado', style: TextStyle(color: darkTextColor)),
          ],
        ),
        TextButton(
          onPressed: _forgotPassword, // Agora chama o método correto
          child: const Text(
            'Esqueci a senha',
            style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
          ),
        ),
      ],
    );
  }
}

// O restante do arquivo (RegistrationFormContent, widgets compartilhados, etc.)
// permanece o mesmo. Cole apenas o que foi modificado acima, ou substitua
// o arquivo inteiro para garantir. O código completo está abaixo para referência.

class _RegistrationFormContent extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onSuccess;

  const _RegistrationFormContent({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.onSuccess,
  });

  @override
  _RegistrationFormContentState createState() => _RegistrationFormContentState();
}

class _RegistrationFormContentState extends State<_RegistrationFormContent> {
  final _confirmPasswordController = TextEditingController();
  bool _has8Chars = false, _hasLowercase = false, _hasUppercase = false, _hasNumber = false, _hasSpecialChar = false;
  bool _passwordsMatch = true;

  @override
  void initState() {
    super.initState();
    widget.passwordController.addListener(_validatePasswordRealtime);
    _confirmPasswordController.addListener(_validateConfirmPassword);
  }

  @override
  void dispose() {
    widget.passwordController.removeListener(_validatePasswordRealtime);
    _confirmPasswordController.removeListener(_validateConfirmPassword);
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validatePasswordRealtime() {
    final password = widget.passwordController.text;
    if (mounted) {
      setState(() {
        _has8Chars = password.length >= 8;
        _hasLowercase = password.contains(RegExp(r'[a-z]'));
        _hasUppercase = password.contains(RegExp(r'[A-Z]'));
        _hasNumber = password.contains(RegExp(r'[0-9]'));
        _hasSpecialChar = password.contains(RegExp(r'[@$!%*?&]'));
      });
    }
  }

  void _validateConfirmPassword() {
    if (mounted) {
      setState(() {
        _passwordsMatch = widget.passwordController.text == _confirmPasswordController.text;
      });
    }
  }
  
  void _submitRegistration() {
    FocusScope.of(context).unfocus();
    _validateConfirmPassword();

    if (widget.formKey.currentState!.validate()) {
      final allCriteriaMet = _has8Chars && _hasLowercase && _hasUppercase && _hasNumber && _hasSpecialChar;
      
      if (!allCriteriaMet || !_passwordsMatch) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, verifique se as senhas coincidem e atendem a todos os critérios.')),
        );
        return;
      }

      final registrationData = {
        "email": widget.emailController.text,
        "password": widget.passwordController.text,
        "confirmPassword": _confirmPasswordController.text,
      };
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AdditionalInfoScreen(
            registrationData: registrationData,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        _SharedPasswordField(
          controller: _confirmPasswordController,
          label: 'Confirme sua senha',
          validationError: !_passwordsMatch && _confirmPasswordController.text.isNotEmpty
              ? 'As senhas não conferem'
              : null,
        ),
        const SizedBox(height: 24),
        _buildPasswordRequirements(),
        const SizedBox(height: 24),
        _buildPrimaryButton('Continuar', _submitRegistration, false, true),
        const SizedBox(height: 32),
        _buildDivider(),
        const SizedBox(height: 32),
        _buildSocialLoginRow(),
      ],
    );
  }

  Widget _buildPasswordRequirements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Sua senha deve conter:', style: TextStyle(fontWeight: FontWeight.bold, color: darkTextColor)),
        const SizedBox(height: 8),
        _buildRequirementRow('Pelo menos 8 caracteres', _has8Chars),
        _buildRequirementRow('Pelo menos 1 letra minúscula', _hasLowercase),
        _buildRequirementRow('Pelo menos 1 letra maiúscula', _hasUppercase),
        _buildRequirementRow('Pelo menos 1 número', _hasNumber),
        _buildRequirementRow('Pelo menos 1 caractere especial', _hasSpecialChar),
      ],
    );
  }

  Widget _buildRequirementRow(String text, bool met) {
    final color = met ? Colors.green : (widget.passwordController.text.isEmpty ? lightTextColor : Colors.red);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}

class _SharedTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;

  const _SharedTextField({required this.controller, required this.label, this.validator});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: darkTextColor)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: fieldBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.transparent),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryColor),
            ),
          ),
        ),
      ],
    );
  }
}

class _SharedPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? validationError;

  const _SharedPasswordField({required this.controller, required this.label, this.validationError});

  @override
  _SharedPasswordFieldState createState() => _SharedPasswordFieldState();
}

class _SharedPasswordFieldState extends State<_SharedPasswordField> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontWeight: FontWeight.bold, color: darkTextColor)),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            filled: true,
            fillColor: fieldBackgroundColor,
            errorText: widget.validationError,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.transparent),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryColor),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: lightTextColor,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}

Widget _buildPrimaryButton(String text, VoidCallback onPressed, bool isLoading, bool showArrow) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(double.infinity, 50),
        elevation: 0,
      ),
      child: isLoading
          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                if (showArrow) const SizedBox(width: 8),
                if (showArrow) const Icon(Icons.arrow_forward),
              ],
            ),
    );
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

Widget _buildSocialLoginRow() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: Image.asset('assets/images/google_logo.png', height: 24),
            label: const Text(''),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: borderColor),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.apple, color: Colors.black, size: 28),
            label: const Text(''),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: borderColor),
            ),
          ),
        ),
      ],
    );
  }