import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wtg_front/services/api_service.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Controllers
  final _firstNameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _phoneController = TextEditingController();
  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Promotion Controllers
  final _promoTitleController = TextEditingController();
  final _promoDescController = TextEditingController();
  final _addressController = TextEditingController();
  final _addressNumController = TextEditingController();
  final _addressComplementController = TextEditingController();
  final _addressPostalCodeController = TextEditingController();
  final _addressReferenceController = TextEditingController();

  // State
  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _createPromotion = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final ApiService _apiService = ApiService();

  @override
  void dispose() {
    _firstNameController.dispose();
    _fullNameController.dispose();
    _birthdayController.dispose();
    _phoneController.dispose();
    _userNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _promoTitleController.dispose();
    _promoDescController.dispose();
    _addressController.dispose();
    _addressNumController.dispose();
    _addressComplementController.dispose();
    _addressPostalCodeController.dispose();
    _addressReferenceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _birthdayController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'O campo $fieldName é obrigatório.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'O campo E-mail é obrigatório.';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Por favor, insira um e-mail válido.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'O campo Senha é obrigatório.';
    }
    final passwordRegex =
        RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
    if (!passwordRegex.hasMatch(value)) {
      return 'A senha deve ter no mínimo 8 caracteres, incluindo uma maiúscula, uma minúscula, um número e um caractere especial.';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return 'As senhas não coincidem.';
    }
    return null;
  }

  void _onStepContinue() {
    bool isStepValid = _formKey.currentState?.validate() ?? false;
    if (isStepValid) {
      if (_currentStep < 2) {
        setState(() {
          _currentStep += 1;
        });
      } else {
        _submitRegistration();
      }
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
      });
    }
  }

  Future<void> _submitRegistration() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    Map<String, dynamic> registrationData = {
      "firstName": _firstNameController.text,
      "fullName": _fullNameController.text,
      "birthday": _selectedDate?.toIso8601String().substring(0, 10),
      "phone": _phoneController.text,
      "userName": _userNameController.text,
      "email": _emailController.text,
      "password": _passwordController.text,
      "confirmPassword": _confirmPasswordController.text,
    };

    if (_createPromotion) {
      registrationData['promotion'] = {
        "title": _promoTitleController.text,
        "description": _promoDescController.text,
        "active": true, // Promotion starts active by default
        "free": true, // Assuming default is free
        "obs": "",
        "address": {
          "address": _addressController.text,
          "number": int.tryParse(_addressNumController.text) ?? 0,
          "complement": _addressComplementController.text,
          "reference": _addressReferenceController.text,
          "postalCode": _addressPostalCodeController.text,
          "obs": ""
        }
      };
    }
    
    try {
      await _apiService.register(registrationData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cadastro realizado com sucesso! Faça o login.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro no cadastro: ${e.toString().replaceAll("Exception: ", "")}')),
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
      appBar: AppBar(
        title: const Text('Cadastro de Novo Usuário'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFff9a9e),
              Color(0xFFfad0c4),
              Color(0xFFa18cd1),
            ],
          ),
        ),
        child: Form(
          key: _formKey,
          child: Stepper(
            type: StepperType.vertical,
            currentStep: _currentStep,
            onStepContinue: _onStepContinue,
            onStepCancel: _onStepCancel,
            onStepTapped: (step) => setState(() => _currentStep = step),
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: _isLoading && _currentStep == 2
                    ? const Center(child: CircularProgressIndicator())
                    : Row(
                        children: [
                          ElevatedButton(
                            onPressed: details.onStepContinue,
                            child: Text(_currentStep == 2 ? 'CADASTRAR' : 'CONTINUAR'),
                          ),
                          if (_currentStep > 0)
                            TextButton(
                              onPressed: details.onStepCancel,
                              child: const Text('VOLTAR'),
                            ),
                        ],
                      ),
              );
            },
            steps: [
              _buildStep1(),
              _buildStep2(),
              _buildStep3(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pop(),
        label: const Text('Cancelar'),
        icon: const Icon(Icons.close),
        backgroundColor: Colors.red,
      ),
    );
  }

  Step _buildStep1() {
    return Step(
      title: const Text('Dados Pessoais'),
      isActive: _currentStep >= 0,
      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      content: Column(
        children: [
          _buildFormTextField(_firstNameController, 'Primeiro Nome', validator: (val) => _validateRequired(val, 'Primeiro Nome')),
          _buildFormTextField(_fullNameController, 'Nome Completo', validator: (val) => _validateRequired(val, 'Nome Completo')),
          _buildFormTextField(
            _birthdayController,
            'Data de Nascimento',
            readOnly: true,
            onTap: () => _selectDate(context),
            validator: (val) => _validateRequired(val, 'Data de Nascimento'),
          ),
          _buildFormTextField(_phoneController, 'Telefone', keyboardType: TextInputType.phone),
        ],
      ),
    );
  }

  Step _buildStep2() {
    return Step(
      title: const Text('Dados da Conta'),
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      content: Column(
        children: [
          _buildFormTextField(_userNameController, 'Nome de Usuário', validator: (val) => _validateRequired(val, 'Nome de Usuário')),
          _buildFormTextField(_emailController, 'E-mail', keyboardType: TextInputType.emailAddress, validator: _validateEmail),
          _buildFormTextField(
            _passwordController,
            'Senha',
            obscureText: !_isPasswordVisible,
            validator: _validatePassword,
            suffixIcon: IconButton(
              icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
          ),
          _buildFormTextField(
            _confirmPasswordController,
            'Confirmar Senha',
            obscureText: !_isConfirmPasswordVisible,
            validator: _validateConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
            ),
          ),
        ],
      ),
    );
  }

  Step _buildStep3() {
    return Step(
      title: const Text('Evento (Opcional)'),
      isActive: _currentStep >= 2,
      content: Column(
        children: [
          CheckboxListTile(
            title: const Text("Desejo criar um evento junto com meu cadastro"),
            value: _createPromotion,
            onChanged: (bool? value) {
              setState(() {
                _createPromotion = value ?? false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
          if (_createPromotion) ...[
            _buildFormTextField(_promoTitleController, 'Título do Evento', validator: (val) => _createPromotion ? _validateRequired(val, 'Título do Evento') : null),
            _buildFormTextField(_promoDescController, 'Descrição do Evento', validator: (val) => _createPromotion ? _validateRequired(val, 'Descrição do Evento') : null),
            _buildFormTextField(_addressController, 'Endereço', validator: (val) => _createPromotion ? _validateRequired(val, 'Endereço') : null),
            _buildFormTextField(_addressNumController, 'Número', keyboardType: TextInputType.number, validator: (val) => _createPromotion ? _validateRequired(val, 'Número') : null),
            _buildFormTextField(_addressComplementController, 'Complemento', validator: (val) => _createPromotion ? _validateRequired(val, 'Complemento') : null),
            _buildFormTextField(_addressPostalCodeController, 'CEP', keyboardType: TextInputType.number, validator: (val) => _createPromotion ? _validateRequired(val, 'CEP') : null),
            _buildFormTextField(_addressReferenceController, 'Referência', validator: (val) => _createPromotion ? _validateRequired(val, 'Referência') : null),
          ],
        ],
      ),
    );
  }

  Widget _buildFormTextField(
    TextEditingController controller,
    String label, {
    bool obscureText = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool readOnly = false,
    void Function()? onTap,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white70,
        ),
      ),
    );
  }
}
