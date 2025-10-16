// lib/screens/reset_password/reset_password_screen.dart

import 'package:flutter/material.dart';
import 'package:wtg_front/screens/auth_screen.dart';
import 'package:wtg_front/services/api_service.dart';

// Cores utilizadas na tela, seguindo a paleta do app.
const Color darkTextColor = Color(0xFF1F2937);
const Color fieldBackgroundColor = Color(0xFFF9FAFB);

// Novas cores solicitadas e as do medidor de senha
const Color primaryButtonColor = Color(0xFFd74533);
const Color successColor = Color(0xFF10ac84);
const Color errorColor = Color(0xFFd74533);
const Color hintTextColor = Color(0xFF10ac84);
const Color keyIconColor = Color(0xFFf19f2a); // --- NOVA COR DO ÍCONE

// --- CORES DO MEDIDOR DE SENHA (COPIADO DA TELA DE CADASTRO) ---
const Color passwordWeakColor = Color(0xFFd74533);
const Color passwordMediumColor = Color(0xFFec9b28);
const Color passwordStrongColor = Color(0xFF10ac84);

// --- ENUM DO MEDIDOR DE SENHA (COPIADO DA TELA DE CADASTRO) ---
enum PasswordStrength { none, weak, medium, strong }

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String token;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.token,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;

  // --- VARIÁVEIS DE ESTADO PARA O MEDIDOR E REQUISITOS ---
  PasswordStrength _passwordStrength = PasswordStrength.none;
  bool _has8Chars = false,
      _hasUppercase = false,
      _hasNumber = false,
      _hasSpecialChar = false;

  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_validatePassword);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE VALIDAÇÃO ATUALIZADA (COPIADA DA TELA DE CADASTRO) ---
  void _validatePassword() {
    final pass = _passwordController.text;
    int score = 0;

    setState(() {
      _has8Chars = pass.length >= 8;
      _hasUppercase = pass.contains(RegExp(r'[A-Z]'));
      _hasNumber = pass.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = pass.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

      if (_has8Chars) score++;
      if (_hasUppercase) score++;
      if (_hasNumber) score++;
      if (_hasSpecialChar) score++;

      if (pass.isEmpty) {
        _passwordStrength = PasswordStrength.none;
      } else if (score <= 1) {
        _passwordStrength = PasswordStrength.weak;
      } else if (score <= 3) {
        _passwordStrength = PasswordStrength.medium;
      } else {
        _passwordStrength = PasswordStrength.strong;
      }
    });
  }

  Future<void> _submitNewPassword() async {
    // ... (lógica de submit permanece a mesma)
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('As senhas não coincidem.')));
      return;
    }
    if (!(_has8Chars && _hasUppercase && _hasNumber && _hasSpecialChar)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A senha não atende aos critérios.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _apiService.resetPassword(
        token: widget.token,
        newPassword: _passwordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Senha redefinida com sucesso! Por favor, faça o login.')),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Erro: ${e.toString().replaceAll("Exception: ", "")}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool allRequirementsMet =
        _has8Chars && _hasUppercase && _hasNumber && _hasSpecialChar;
    final bool isPasswordEmpty = _passwordController.text.isEmpty;

    final Color requirementsColor = isPasswordEmpty
        ? Colors.grey
        : allRequirementsMet
            ? successColor
            : errorColor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: darkTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    // --- COR DO FUNDO DO ÍCONE ALTERADA ---
                    color: keyIconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  // --- COR DO ÍCONE ALTERADA ---
                  child: const Icon(Icons.vpn_key_outlined,
                      color: keyIconColor, size: 32),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Crie uma nova senha',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: darkTextColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Lembre-se de criar uma senha forte e segura!',
                style: TextStyle(fontSize: 16, color: hintTextColor),
              ),
              const SizedBox(height: 40),
              const Text('Nova Senha',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: darkTextColor)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: _isPasswordObscured,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: fieldBackgroundColor,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordObscured
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () =>
                        setState(() => _isPasswordObscured = !_isPasswordObscured),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Confirme a nova senha',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: darkTextColor)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _isConfirmPasswordObscured,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: fieldBackgroundColor,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  suffixIcon: IconButton(
                    icon: Icon(_isConfirmPasswordObscured
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () => setState(() =>
                        _isConfirmPasswordObscured = !_isConfirmPasswordObscured),
                  ),
                ),
              ),

              // --- MEDIDOR DE SENHA ADICIONADO AQUI ---
              const SizedBox(height: 16),
              _buildPasswordStrengthIndicator(),
              const SizedBox(height: 24),

              Text('Sua senha deve conter:',
                  style: TextStyle(color: requirementsColor)),
              const SizedBox(height: 8),
              _buildRequirementRow('8 caracteres', _has8Chars),
              _buildRequirementRow('1 letra maiúscula', _hasUppercase),
              _buildRequirementRow('1 número', _hasNumber),
              _buildRequirementRow(
                  '1 caractere especial (ex: @, \$, !, %, #, ?)',
                  _hasSpecialChar),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitNewPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryButtonColor,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Redefinir Senha',
                        style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementRow(String text, bool met) {
    final bool isPasswordEmpty = _passwordController.text.isEmpty;
    final Color color =
        isPasswordEmpty ? Colors.grey : (met ? successColor : errorColor);

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.circle_outlined,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  // --- WIDGET DO MEDIDOR DE SENHA (COPIADO DA TELA DE CADASTRO) ---
  Widget _buildPasswordStrengthIndicator() {
    String strengthText;
    Color strengthColor;

    switch (_passwordStrength) {
      case PasswordStrength.weak:
        strengthText = 'Fraca';
        strengthColor = passwordWeakColor;
        break;
      case PasswordStrength.medium:
        strengthText = 'Média';
        strengthColor = passwordMediumColor;
        break;
      case PasswordStrength.strong:
        strengthText = 'Forte';
        strengthColor = passwordStrongColor;
        break;
      default:
        strengthText = '';
        strengthColor = Colors.grey[300]!;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStrengthBar(
                _passwordStrength.index >= 1 ? strengthColor : Colors.grey[300]!,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStrengthBar(
                _passwordStrength.index >= 2 ? strengthColor : Colors.grey[300]!,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStrengthBar(
                _passwordStrength.index >= 3 ? strengthColor : Colors.grey[300]!,
              ),
            ),
          ],
        ),
        if (strengthText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              strengthText,
              style: TextStyle(
                color: strengthColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  // --- WIDGET AUXILIAR DO MEDIDOR (COPIADO DA TELA DE CADASTRO) ---
  Widget _buildStrengthBar(Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 6,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}