// lib/screens/registration/3_password_screen.dart

import 'package:flutter/material.dart';
import 'package:wtg_front/screens/registration/additional_info_screen.dart';

const Color primaryColor = Color(0xFF214886);
const Color darkTextColor = Color(0xFF002956);
const Color fieldBackgroundColor = Color(0xFFF9FAFB);
const Color primaryButtonColor = Color(0xFFd74533);

// --- CORES DO BREADCRUMB ADICIONADAS ---
const Color verificationStepColor = Color(0xFF214886);
const Color passwordStepColor = Color(0xFFec9b28);
const Color infoStepColor = Color(0xFF1F73F8);

// --- CORES DO MEDIDOR E REQUISITOS DE SENHA ---
const Color passwordWeakColor = Color(0xFFd74533);
const Color passwordMediumColor = Color(0xFFec9b28);
const Color passwordStrongColor = Color(0xFF10ac84);

// Enum para representar a força da senha
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('As senhas não coincidem.')));
      return;
    }
    if (!(_has8Chars && _hasUppercase && _hasNumber && _hasSpecialChar)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A senha não atende aos critérios.')));
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

  @override
  Widget build(BuildContext context) {
    // --- LÓGICA DE COR PARA A SEÇÃO DE REQUISITOS ---
    final bool allRequirementsMet = _has8Chars && _hasUppercase && _hasNumber && _hasSpecialChar;
    final bool isPasswordEmpty = _passwordController.text.isEmpty;

    final Color requirementsColor = isPasswordEmpty
        ? Colors.grey // Cor neutra quando o campo está vazio
        : allRequirementsMet
            ? passwordStrongColor // Verde quando tudo está OK
            : passwordWeakColor; // Vermelho se algum critério não for atendido

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: darkTextColor),
            onPressed: () => Navigator.of(context).pop()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBreadcrumbs(currentStep: 2),
              const SizedBox(height: 32),
              const Text('Crie uma senha',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: darkTextColor)),
              const SizedBox(height: 8),
              const Text('Não esqueça: a senha tem que ser forte!',
                  style: TextStyle(fontSize: 16, color: Color.fromRGBO(238, 155, 42, 0.933))),
              const SizedBox(height: 40),
              
              const Text('Senha', style: TextStyle(fontWeight: FontWeight.bold, color: darkTextColor)),
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
                        onPressed: () {
                          setState(() {
                            _isPasswordObscured = !_isPasswordObscured;
                          });
                        },
                      ))),
              const SizedBox(height: 24),

              const Text('Confirme sua senha', style: TextStyle(fontWeight: FontWeight.bold, color: darkTextColor)),
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
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordObscured = !_isConfirmPasswordObscured;
                          });
                        },
                      ))),
              
              const SizedBox(height: 16),
              _buildPasswordStrengthIndicator(),
              const SizedBox(height: 24),

              Text('Sua senha deve conter:', style: TextStyle(color: requirementsColor)),
              _buildRequirementRow('8 caracteres', _has8Chars, requirementsColor, isPasswordEmpty),
              _buildRequirementRow('1 letra maiúscula', _hasUppercase, requirementsColor, isPasswordEmpty),
              _buildRequirementRow('1 número', _hasNumber, requirementsColor, isPasswordEmpty),
              _buildRequirementRow(
                  '1 caractere especial (ex: @, \$, !, %, #, ?)',
                  _hasSpecialChar, requirementsColor, isPasswordEmpty),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _continue,
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryButtonColor,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('Continuar',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
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

  // --- WIDGET DE REQUISITOS ATUALIZADO PARA RECEBER A COR ---
  Widget _buildRequirementRow(String text, bool met, Color dynamicColor, bool isPasswordEmpty) {
    final Color iconColor = isPasswordEmpty ? Colors.grey : (met ? passwordStrongColor : passwordWeakColor);
    final Color textColor = isPasswordEmpty ? Colors.grey : (met ? darkTextColor : passwordWeakColor);

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.circle_outlined,
            color: iconColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: textColor)),
        ],
      ),
    );
  }
  
  Widget _buildBreadcrumbs({required int currentStep}) {
    return Row(
      children: [
        _buildStep(
          icon: Icons.mark_email_read_outlined,
          label: 'Verificação',
          stepColor: verificationStepColor,
          isComplete: currentStep > 1,
          isActive: currentStep == 1,
        ),
        _buildConnector(isComplete: currentStep > 1, color: passwordStepColor),
        _buildStep(
          icon: Icons.lock_outline,
          label: 'Senha',
          stepColor: passwordStepColor,
          isComplete: currentStep > 2,
          isActive: currentStep == 2,
        ),
        _buildConnector(isComplete: currentStep > 2, color: infoStepColor),
        _buildStep(
          icon: Icons.person_outline,
          label: 'Dados',
          stepColor: infoStepColor,
          isComplete: false, 
          isActive: currentStep == 3,
        ),
      ],
    );
  }

  Widget _buildStep({required IconData icon, required String label, required Color stepColor, required bool isActive, required bool isComplete}) {
    final color = isActive || isComplete ? stepColor : Colors.grey[400];
    
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isActive || isComplete ? stepColor : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: color!, width: 2),
          ),
          child: Icon(
            icon,
            color: isActive || isComplete ? Colors.white : Colors.grey[400],
            size: 22,
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: darkTextColor, fontSize: 12, fontWeight: isActive || isComplete ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildConnector({required bool isComplete, required Color color}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        color: isComplete ? color : Colors.grey[300],
      ),
    );
  }
}