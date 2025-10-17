import 'package:flutter/material.dart';
import 'package:wtg_front/screens/registration/additional_info_screen.dart';

// Cores
const Color primaryButtonColor = Color(0xFFd74533);
const Color darkTextColor = Color(0xFF002956);
const Color placeholderColor = Color(0xFFE0E0E0);
const Color passwordWeakColor = Color(0xFFd74533);
const Color passwordMediumColor = Color(0xFFec9b28);
const Color passwordStrongColor = Color(0xFF10ac84);

// Cores do Breadcrumb
const Color verificationStepColor = Color(0xFF214886);
const Color passwordStepColor = Color(0xFFec9b28);
const Color infoStepColor = Color(0xFFd74533);

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('As senhas não coincidem.')));
      return;
    }
    if (!(_has8Chars && _hasUppercase && _hasNumber && _hasSpecialChar)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A senha não atende aos critérios.')));
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
        builder: (context) => AdditionalInfoScreen(registrationData: registrationData)));
  }

  @override
  Widget build(BuildContext context) {
    final bool allRequirementsMet = _has8Chars && _hasUppercase && _hasNumber && _hasSpecialChar;
    final bool isPasswordEmpty = _passwordController.text.isEmpty;

    final Color requirementsColor = isPasswordEmpty ? Colors.grey : allRequirementsMet ? passwordStrongColor : passwordWeakColor;

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
              _buildBreadcrumbs(),
              const SizedBox(height: 32),
              const Text('Crie uma senha',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: darkTextColor)),
              const SizedBox(height: 8),
              const Text('Não esqueça: a senha tem que ser forte!',
                  style: TextStyle(fontSize: 16, color: passwordStepColor)),
              const SizedBox(height: 40),
              
              _buildTextField(
                label: 'Senha',
                controller: _passwordController,
                isObscured: _isPasswordObscured,
                onToggleVisibility: () => setState(() => _isPasswordObscured = !_isPasswordObscured),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                label: 'Confirme sua senha',
                controller: _confirmPasswordController,
                isObscured: _isConfirmPasswordObscured,
                onToggleVisibility: () => setState(() => _isConfirmPasswordObscured = !_isConfirmPasswordObscured),
              ),
              const SizedBox(height: 16),
              _buildPasswordStrengthIndicator(),
              const SizedBox(height: 24),

              Text('Sua senha deve conter:', style: TextStyle(color: requirementsColor)),
              _buildRequirementRow('8 caracteres', _has8Chars, requirementsColor, isPasswordEmpty),
              _buildRequirementRow('1 letra maiúscula', _hasUppercase, requirementsColor, isPasswordEmpty),
              _buildRequirementRow('1 número', _hasNumber, requirementsColor, isPasswordEmpty),
              _buildRequirementRow('1 caractere especial (ex: @, \$, !, %, #, ?)', _hasSpecialChar, requirementsColor, isPasswordEmpty),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _continue,
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryButtonColor,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('Continuar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET DE INPUT PADRONIZADO ---
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool isObscured = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: darkTextColor, fontSize: 16)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isObscured,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: placeholderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: placeholderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: passwordStepColor, width: 2)),
            suffixIcon: onToggleVisibility != null
                ? IconButton(
                    icon: Icon(isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: onToggleVisibility,
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    String strengthText;
    Color strengthColor;
    switch (_passwordStrength) {
      case PasswordStrength.weak: strengthText = 'Fraca'; strengthColor = passwordWeakColor; break;
      case PasswordStrength.medium: strengthText = 'Média'; strengthColor = passwordMediumColor; break;
      case PasswordStrength.strong: strengthText = 'Forte'; strengthColor = passwordStrongColor; break;
      default: strengthText = ''; strengthColor = Colors.grey[300]!;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildStrengthBar(_passwordStrength.index >= 1 ? strengthColor : Colors.grey[300]!)),
            const SizedBox(width: 8),
            Expanded(child: _buildStrengthBar(_passwordStrength.index >= 2 ? strengthColor : Colors.grey[300]!)),
            const SizedBox(width: 8),
            Expanded(child: _buildStrengthBar(_passwordStrength.index >= 3 ? strengthColor : Colors.grey[300]!)),
          ],
        ),
        if (strengthText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(strengthText, style: TextStyle(color: strengthColor, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  Widget _buildStrengthBar(Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 6,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildRequirementRow(String text, bool met, Color dynamicColor, bool isPasswordEmpty) {
    final Color iconColor = isPasswordEmpty ? Colors.grey : (met ? passwordStrongColor : passwordWeakColor);
    final Color textColor = isPasswordEmpty ? Colors.grey : (met ? darkTextColor : passwordWeakColor);
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          Icon(met ? Icons.check_circle : Icons.circle_outlined, color: iconColor, size: 18),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: textColor)),
        ],
      ),
    );
  }
  
  Widget _buildBreadcrumbs() {
    const int currentStep = 2;
    return Row(
      children: [
        _buildStepIndicator(step: 1, currentStep: currentStep, icon: Icons.mark_email_read_outlined, activeColor: verificationStepColor),
        _buildConnector(isComplete: currentStep > 1, color: passwordStepColor),
        _buildStepIndicator(step: 2, currentStep: currentStep, icon: Icons.lock_outline, activeColor: passwordStepColor),
        _buildConnector(isComplete: currentStep > 2, color: infoStepColor),
        _buildStepIndicator(step: 3, currentStep: currentStep, icon: Icons.person_outline, activeColor: infoStepColor),
      ],
    );
  }

  Widget _buildStepIndicator({required int step, required int currentStep, required IconData icon, required Color activeColor}) {
    final bool isActive = step == currentStep;
    final bool isComplete = step < currentStep;
    final Color color = isActive || isComplete ? activeColor : Colors.grey[400]!;

    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(step.toString(), style: TextStyle(color: color, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildConnector({required bool isComplete, required Color color}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 32, left: 4, right: 4),
        color: isComplete ? color : Colors.grey[300],
      ),
    );
  }
}