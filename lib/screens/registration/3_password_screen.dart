// lib/screens/registration/3_password_screen.dart

import 'package:flutter/material.dart';
import 'package:wtg_front/screens/registration/additional_info_screen.dart';

// --- PALETA DE CORES PADRONIZADA ---
const Color darkBackgroundColor = Color(0xFF1A202C);
const Color primaryTextColor = Colors.white;
const Color secondaryTextColor = Color(0xFFA0AEC0);
const Color fieldBackgroundColor = Color(0xFF2D3748);
const Color fieldBorderColor = Color(0xFF4A5568);
const Color primaryButtonColor = Color(0xFFE53E3E);

// Cores do Breadcrumb e Feedback de Senha
const Color verificationStepColor = Color(0xFF4299E1);
const Color passwordStepColor = Color(0xFFF6AD55);
const Color infoStepColor = Color(0xFFF56565);
const Color passwordWeakColor = Color(0xFFF56565); // Vermelho para fraca
const Color passwordMediumColor = Color(0xFFF6AD55); // Laranja para média
const Color passwordStrongColor = Color(0xFF48BB78); // Verde para forte

enum PasswordStrength { none, weak, medium, strong }

class PasswordScreen extends StatefulWidget {
  final String email;
  final double? latitude;
  final double? longitude;

  const PasswordScreen({
    super.key,
    required this.email,
    this.latitude,
    this.longitude,
  });

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

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

  // --- NENHUMA ALTERAÇÃO NA LÓGICA ABAIXO ---

  @override
  void dispose() {
    _passwordController.removeListener(_validatePassword);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

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

  void _continue() {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: primaryButtonColor,
          content: Text('As senhas não coincidem.')));
      return;
    }
    if (!(_has8Chars && _hasUppercase && _hasNumber && _hasSpecialChar)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: primaryButtonColor,
          content: Text('A senha não atende a todos os critérios de segurança.')));
      return;
    }

    final registrationData = {
      'email': widget.email,
      'password': _passwordController.text,
      'confirmPassword': _confirmPasswordController.text,
      'latitude': widget.latitude,
      'longitude': widget.longitude,
    };

    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) =>
            AdditionalInfoScreen(registrationData: registrationData)));
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
            onPressed: () => Navigator.of(context).pop()),
        actions: [
          _buildBreadcrumbs(),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              const Text('Crie uma senha',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor)),
              const SizedBox(height: 12),
              const Text('Não esqueça: a senha tem que ser forte!',
                  style: TextStyle(fontSize: 16, color: secondaryTextColor)),
              const SizedBox(height: 40),
              _buildTextField(
                label: 'Senha',
                controller: _passwordController,
                isObscured: _isPasswordObscured,
                onToggleVisibility: () =>
                    setState(() => _isPasswordObscured = !_isPasswordObscured),
              ),
              const SizedBox(height: 16),
              _buildPasswordStrengthIndicator(),
              const SizedBox(height: 24),
              _buildTextField(
                label: 'Confirme sua senha',
                controller: _confirmPasswordController,
                isObscured: _isConfirmPasswordObscured,
                onToggleVisibility: () => setState(() =>
                    _isConfirmPasswordObscured = !_isConfirmPasswordObscured),
              ),
              const SizedBox(height: 32),
              _buildPasswordRequirements(),
              const SizedBox(height: 40),
              _buildPrimaryButton('Continuar', _continue, false),
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
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: secondaryTextColor,
                fontSize: 16)),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          obscureText: isObscured,
          style: const TextStyle(
              color: primaryTextColor, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            prefixIcon:
                const Icon(Icons.lock_outline, color: passwordStepColor, size: 22),
            suffixIcon: onToggleVisibility != null
                ? IconButton(
                    icon: Icon(
                      isObscured
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: secondaryTextColor,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
            filled: true,
            fillColor: fieldBackgroundColor,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: passwordStepColor, width: 2),
            ),
          ),
        ),
      ],
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
                _passwordStrength.index >= 1 ? strengthColor : fieldBorderColor),
            const SizedBox(width: 8),
            _buildStrengthBar(
                _passwordStrength.index >= 2 ? strengthColor : fieldBorderColor),
            const SizedBox(width: 8),
            _buildStrengthBar(
                _passwordStrength.index >= 3 ? strengthColor : fieldBorderColor),
          ],
        ),
        if (strengthText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(strengthText,
                style: TextStyle(color: strengthColor, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  Widget _buildStrengthBar(Color color) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 8,
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      ),
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
  
  Widget _buildBreadcrumbs() {
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.4,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildStep(
              icon: Icons.mark_email_read_outlined,
              stepColor: verificationStepColor,
              isComplete: true,
            ),
            _buildConnector(isComplete: true, color: passwordStepColor),
            _buildStep(
              icon: Icons.lock_open_outlined,
              stepColor: passwordStepColor,
              isActive: true,
            ),
            _buildConnector(isComplete: false, color: infoStepColor),
            _buildStep(
              icon: Icons.person_add_alt_1_outlined,
              stepColor: infoStepColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({
    required IconData icon,
    required Color stepColor,
    bool isActive = false,
    bool isComplete = false,
  }) {
    final double iconSize = isActive ? 26.0 : 20.0;
    final double containerSize = isActive ? 44.0 : 38.0;
    final Color iconColor = isComplete
        ? stepColor.withOpacity(0.4)
        : (isActive ? Colors.white : secondaryTextColor.withOpacity(0.7));

    return Container(
      width: containerSize,
      height: containerSize,
      decoration: BoxDecoration(
        color: isActive ? stepColor : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: isComplete
              ? stepColor.withOpacity(0.4)
              : (isActive ? stepColor : fieldBorderColor),
          width: 2,
        ),
      ),
      child: Center(
        child: Icon(icon, color: iconColor, size: iconSize),
      ),
    );
  }

  Widget _buildConnector({required bool isComplete, required Color color}) {
    return Expanded(
      child: Container(
        height: 2,
        color: isComplete ? color.withOpacity(0.4) : fieldBorderColor,
      ),
    );
  }
}

Widget _buildPrimaryButton(
    String text, VoidCallback onPressed, bool isLoading) {
  return ElevatedButton(
    onPressed: isLoading ? null : onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryButtonColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      minimumSize: const Size(double.infinity, 64),
      elevation: 3,
      shadowColor: primaryButtonColor.withOpacity(0.5),
    ),
    child: isLoading
        ? const SizedBox(
            height: 24,
            width: 24,
            child:
                CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
        : Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
  );
}