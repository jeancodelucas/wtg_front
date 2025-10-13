// lib/screens/registration/3_password_screen.dart

import 'package:flutter/material.dart';
import 'package:wtg_front/screens/registration/additional_info_screen.dart';

const Color primaryColor = Color(0xFF214886);
const Color darkTextColor = Color(0xFF1F2937);

class PasswordScreen extends StatefulWidget {
  final String email;
  const PasswordScreen({super.key, required this.email});

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

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
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
    if (!(_has8Chars &&
        _hasUppercase &&
        _hasNumber &&
        _hasSpecialChar)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A senha não atende aos critérios.')));
      return;
    }

    final registrationData = {
      'email': widget.email,
      'password': _passwordController.text,
      'confirmPassword': _confirmPasswordController.text,
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
              const SizedBox(height: 24),
              const Text('Crie uma senha',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: darkTextColor)),
              const SizedBox(height: 8),
              const Text('Não esqueça: a senha tem que ser forte!',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 40),
              TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                      labelText: 'Senha',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 24),
              TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                      labelText: 'Confirme sua senha',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)))),
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
    return Row(
      children: [
        Icon(Icons.check_circle,
            color: met ? Colors.green : Colors.grey, size: 16),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: met ? Colors.green : Colors.grey)),
      ],
    );
  }
}