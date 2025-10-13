import 'package:flutter/material.dart';
import 'package:wtg_front/services/api_service.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _apiService = ApiService();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  bool _has8Chars = false;
  bool _hasLowercase = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePasswordRealtime);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.removeListener(_validatePasswordRealtime);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validatePasswordRealtime() {
    final password = _passwordController.text;
    setState(() {
      _has8Chars = password.length >= 8;
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = password.contains(RegExp(r'[@$!%*?&]'));
    });
  }

  Future<void> _submitRegistration() async {
    FocusScope.of(context).unfocus();

    if (!_has8Chars ||
        !_hasLowercase ||
        !_hasUppercase ||
        !_hasNumber ||
        !_hasSpecialChar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sua senha não atende a todos os critérios.')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('As senhas não coincidem.')),
      );
      return;
    }
    
    final email = _emailController.text;
    final userName = email.split('@').first;

    setState(() => _isLoading = true);

    Map<String, dynamic> registrationData = {
      "firstName": userName,
      "fullName": userName,
      "email": email,
      "password": _passwordController.text,
      "confirmPassword": _confirmPasswordController.text,
    };

    try {
      await _apiService.register(registrationData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Cadastro realizado com sucesso! Faça o login.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Erro no cadastro: ${e.toString().replaceAll("Exception: ", "")}')),
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 140,
                  width: 140,
                  child: ClipOval(
                    child: Image.asset('assets/images/LaRuaLogo.png'),
                  ),
                ),
                const SizedBox(height: 16),
                // MODIFICADO: Trocado o widget Text pela imagem
                SizedBox(
                  height: 40,
                  child: Image.asset('assets/images/LaRuaNameLogo.png'),
                ),
                const SizedBox(height: 40),
                _buildLoginToggler(),
                const SizedBox(height: 24),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordController,
                  label: 'Senha',
                  isPassword: true,
                  isConfirm: false,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirme sua senha',
                  isPassword: true,
                  isConfirm: true,
                ),
                const SizedBox(height: 24),
                _buildPasswordRequirements(),
                const SizedBox(height: 24),
                _buildPrimaryButton('Continuar', _submitRegistration),
                const SizedBox(height: 32),
                _buildDivider(),
                const SizedBox(height: 32),
                _buildSocialLoginRow(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // O restante do código permanece o mesmo.
  // ... (Cole o resto dos métodos _buildLoginToggler, _buildTextField, etc. aqui)
  
  Widget _buildLoginToggler() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    'Entrar',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                  )
                ],
              ),
              child: const Center(
                child: Text(
                  'Cadastre-se',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool isConfirm = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword
              ? (isConfirm ? !_isConfirmPasswordVisible : !_isPasswordVisible)
              : false,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      (isConfirm
                              ? _isConfirmPasswordVisible
                              : _isPasswordVisible)
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        if (isConfirm) {
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                        } else {
                          _isPasswordVisible = !_isPasswordVisible;
                        }
                      });
                    },
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
        const Text('Sua senha deve conter:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildRequirementRow('8 caracteres', _has8Chars),
        _buildRequirementRow('1 letra minúscula', _hasLowercase),
        _buildRequirementRow('1 letra maiúscula', _hasUppercase),
        _buildRequirementRow('1 número', _hasNumber),
        _buildRequirementRow('1 caractere especial (ex: @, \$, !, %, *, ?, &)', _hasSpecialChar),
      ],
    );
  }
  
  Widget _buildRequirementRow(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: met ? Colors.green : Colors.red),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: met ? Colors.green : Colors.red)),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF377DFF),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        minimumSize: const Size(double.infinity, 50),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ))
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward),
              ],
            ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[300])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Ou',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[300])),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: Colors.grey.shade300),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
      ],
    );
  }
}