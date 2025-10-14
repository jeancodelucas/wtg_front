// lib/screens/registration/3_password_screen.dart

import 'package:flutter/material.dart';
import 'package:wtg_front/screens/registration/additional_info_screen.dart';

const Color primaryColor = Color(0xFF214886);
const Color darkTextColor = Color(0xFF1F2937);
const Color fieldBackgroundColor = Color(0xFFF9FAFB);

// --- CORES DO BREADCRUMB ADICIONADAS ---
const Color verificationStepColor = Color(0xFFFF554D);
const Color passwordStepColor = Color(0xFF10ac84);
const Color infoStepColor = Color(0xFF1F73F8);

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
    setState(() {
      _has8Chars = pass.length >= 8;
      _hasUppercase = pass.contains(RegExp(r'[A-Z]'));
      _hasNumber = pass.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = pass.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
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
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
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

              const SizedBox(height: 24),
              const Text('Sua senha deve conter:'),
              _buildRequirementRow('8 caracteres', _has8Chars),
              _buildRequirementRow('1 letra maiúscula', _hasUppercase),
              _buildRequirementRow('1 número', _hasNumber),
              _buildRequirementRow(
                  '1 caractere especial (ex: @, \$, !, %, #, ?)',
                  _hasSpecialChar),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _continue,
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
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

  Widget _buildRequirementRow(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          Icon(met ? Icons.check_circle : Icons.circle_outlined,
              color: met ? Colors.green : Colors.grey, size: 18),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: met ? Colors.black : Colors.grey)),
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