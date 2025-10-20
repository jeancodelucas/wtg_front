// lib/screens/reset_password/reset_password_screen.dart

import 'package:flutter/material.dart';
import 'package:wtg_front/screens/auth_screen.dart';
import 'package:wtg_front/services/api_service.dart';

// --- PALETA DE CORES PADRONIZADA ---
const Color darkBackgroundColor = Color(0xFF1A202C);
const Color primaryTextColor = Colors.white;
const Color secondaryTextColor = Color(0xFFA0AEC0);
const Color fieldBackgroundColor = Color(0xFF2D3748);
const Color fieldBorderColor = Color(0xFF4A5568);
const Color primaryButtonColor = Color(0xFFE53E3E);

const Color passwordWeakColor = Color(0xFFF56565);
const Color passwordMediumColor = Color(0xFFF6AD55);
const Color passwordStrongColor = Color(0xFF48BB78);
const Color keyIconColor = Color(0xFFF6AD55);

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

  // --- LÓGICA DE FUNCIONALIDADE INALTERADA ---
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

  // --- BUILD METHOD E WIDGETS DE UI ATUALIZADOS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackgroundColor,
      appBar: AppBar(
        backgroundColor: darkBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: secondaryTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Center(
                child: Icon(Icons.vpn_key_outlined,
                    color: keyIconColor, size: 48),
              ),
              const SizedBox(height: 24),
              const Text(
                'Crie uma nova senha',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Lembre-se de criar uma senha forte e segura!',
                style: TextStyle(fontSize: 16, color: secondaryTextColor),
              ),
              const SizedBox(height: 40),
              _buildTextField(
                label: 'Nova Senha',
                controller: _passwordController,
                isObscured: _isPasswordObscured,
                onToggleVisibility: () =>
                    setState(() => _isPasswordObscured = !_isPasswordObscured),
              ),
              const SizedBox(height: 16),
              _buildPasswordStrengthIndicator(),
              const SizedBox(height: 24),
              _buildTextField(
                label: 'Confirme a nova senha',
                controller: _confirmPasswordController,
                isObscured: _isConfirmPasswordObscured,
                onToggleVisibility: () => setState(() =>
                    _isConfirmPasswordObscured = !_isConfirmPasswordObscured),
              ),
              const SizedBox(height: 24),
              _buildPasswordRequirements(),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitNewPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryButtonColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  minimumSize: const Size(double.infinity, 64),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Redefinir Senha',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool isObscured = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: secondaryTextColor, fontSize: 16)),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          obscureText: isObscured,
          style: const TextStyle(color: primaryTextColor, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline, color: keyIconColor, size: 22),
            filled: true,
            fillColor: fieldBackgroundColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: keyIconColor, width: 2)),
            suffixIcon: onToggleVisibility != null
                ? IconButton(
                    icon: Icon(isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: secondaryTextColor),
                    onPressed: onToggleVisibility,
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordRequirements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRequirementRow('Pelo menos 8 caracteres', _has8Chars),
        _buildRequirementRow('Uma letra maiúscula', _hasUppercase),
        _buildRequirementRow('Um número', _hasNumber),
        _buildRequirementRow('Um caractere especial (ex: @#\$%)', _hasSpecialChar),
      ],
    );
  }

  Widget _buildRequirementRow(String text, bool met) {
    final isPasswordEmpty = _passwordController.text.isEmpty;
    final Color color = isPasswordEmpty
        ? secondaryTextColor
        : (met ? passwordStrongColor : secondaryTextColor);
    final IconData icon = isPasswordEmpty
        ? Icons.circle_outlined
        : (met ? Icons.check_circle : Icons.circle_outlined);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: color, fontSize: 14)),
        ],
      ),
    );
  }

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
        strengthColor = fieldBorderColor;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildStrengthBar(
              _passwordStrength.index >= 1 ? strengthColor : fieldBorderColor,
            ),
            const SizedBox(width: 8),
            _buildStrengthBar(
              _passwordStrength.index >= 2 ? strengthColor : fieldBorderColor,
            ),
            const SizedBox(width: 8),
            _buildStrengthBar(
              _passwordStrength.index >= 3 ? strengthColor : fieldBorderColor,
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

  Widget _buildStrengthBar(Color color) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 8,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}