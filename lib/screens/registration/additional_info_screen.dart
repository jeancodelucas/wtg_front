// lib/screens/registration/additional_info_screen.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:wtg_front/screens/registration_success_screen.dart';
import 'package:wtg_front/services/api_service.dart';
import 'dart:io' show Platform;

const Color primaryButtonColor = Color(0xFFd74533);
const Color primaryColor = Color(0xFF214886);
const Color lightTextColor = Color(0xFF002956);
const Color darkTextColor = Color(0xFF002956);
const Color fieldBackgroundColor = Color(0xFFF9FAFB);

const Color verificationStepColor = Color(0xFF214886);
const Color passwordStepColor = Color(0xFFec9b28);
const Color infoStepColor = Color(0xFFd74533);

class AdditionalInfoScreen extends StatefulWidget {
  final Map<String, dynamic> registrationData;

  const AdditionalInfoScreen({super.key, required this.registrationData});

  @override
  State<AdditionalInfoScreen> createState() => _AdditionalInfoScreenState();
}

class _AdditionalInfoScreenState extends State<AdditionalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  final _nicknameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _pronounController = TextEditingController();

  String? _selectedPronoun;
  bool _isLoading = false;

  final List<String> _pronouns = [
    'Ele/Dele',
    'Ela/Dela',
    'Elu/Delu',
    'Outro',
    'Prefiro não dizer'
  ];

  @override
  void dispose() {
    _nicknameController.dispose();
    _cpfController.dispose();
    _birthdayController.dispose();
    _pronounController.dispose();
    super.dispose();
  }

  String? _validateCpf(String? cpf) {
    if (cpf == null || cpf.isEmpty) return 'CPF é obrigatório.';
    String numbers = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (numbers.length != 11) return 'CPF inválido (deve conter 11 dígitos).';
    if (RegExp(r'^(\d)\1*$').hasMatch(numbers)) return 'CPF inválido.';

    List<int> digits =
        numbers.runes.map((r) => int.parse(String.fromCharCode(r))).toList();
    int calc(int end) {
      int sum = 0;
      for (int i = 0; i < end; i++) {
        sum += digits[i] * (end + 1 - i);
      }
      int result = (sum * 10) % 11;
      return result == 10 ? 0 : result;
    }

    if (calc(9) != digits[9] || calc(10) != digits[10]) return 'CPF inválido.';
    return null;
  }

  Future<void> _selectDate(BuildContext context) async {
    FocusScope.of(context).unfocus();
    if (Platform.isIOS) {
      _showIOSDatePicker();
    } else {
      _showAndroidDatePicker();
    }
  }

  void _showAndroidDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      setState(() {
        _birthdayController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _showIOSDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 250,
        color: const Color.fromARGB(255, 255, 255, 255),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: CupertinoDatePicker(
                initialDateTime: DateTime.now(),
                maximumDate: DateTime.now(),
                minimumDate: DateTime(1900),
                mode: CupertinoDatePickerMode.date,
                onDateTimeChanged: (picked) {
                  setState(() {
                    _birthdayController.text =
                        DateFormat('dd/MM/yyyy').format(picked);
                  });
                },
              ),
            ),
            CupertinoButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            )
          ],
        ),
      ),
    );
  }

  void _selectPronoun() {
    FocusScope.of(context).unfocus();
    if (Platform.isIOS) {
      _showIOSPronounPicker();
    } else {
      _showAndroidPronounDialog();
    }
  }

  void _showIOSPronounPicker() {
    final initialIndex =
        _selectedPronoun != null ? _pronouns.indexOf(_selectedPronoun!) : 0;

    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 250,
        color: const Color.fromARGB(255, 255, 255, 255),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: CupertinoPicker(
                scrollController:
                    FixedExtentScrollController(initialItem: initialIndex),
                itemExtent: 32.0,
                onSelectedItemChanged: (index) {
                  setState(() {
                    _selectedPronoun = _pronouns[index];
                    _pronounController.text = _pronouns[index];
                  });
                },
                children: _pronouns
                    .map((pronoun) => Center(child: Text(pronoun)))
                    .toList(),
              ),
            ),
            CupertinoButton(
              child: const Text('OK'),
              onPressed: () {
                if (_selectedPronoun == null) {
                  setState(() {
                    _selectedPronoun = _pronouns[initialIndex];
                    _pronounController.text = _pronouns[initialIndex];
                  });
                }
                Navigator.of(context).pop();
              },
            )
          ],
        ),
      ),
    );
  }

  void _showAndroidPronounDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecione seu pronome'),
          content: SizedBox(
            width: double.minPositive,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _pronouns.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(_pronouns[index]),
                  onTap: () {
                    setState(() {
                      _selectedPronoun = _pronouns[index];
                      _pronounController.text = _pronouns[index];
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitFinalRegistration() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String birthdateToSend = '';
      if (_birthdayController.text.isNotEmpty) {
        try {
          DateTime parsedDate =
              DateFormat('dd/MM/yyyy').parse(_birthdayController.text);
          birthdateToSend = DateFormat('yyyy-MM-dd').format(parsedDate);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Formato de data inválido.')),
            );
            setState(() => _isLoading = false);
            return;
          }
        }
      }

      final isSsoUser = widget.registrationData['isSsoUser'] ?? false;
      Map<String, dynamic>? apiResponse;

      try {
        if (isSsoUser) {
          final userUpdateData = {
            "firstName": _nicknameController.text,
            "cpf": _cpfController.text.replaceAll(RegExp(r'[^0-9]'), ''),
            "birthday": birthdateToSend,
            "pronouns": _selectedPronoun,
          };

          final cookie = widget.registrationData['cookie'] as String?;
          if (cookie == null) {
            throw Exception(
                "Sessão de autenticação não encontrada para usuário SSO.");
          }

          apiResponse = await _apiService.updateUser(userUpdateData, cookie);
        } else {
          widget.registrationData['userName'] =
              widget.registrationData['email'];
          widget.registrationData['firstName'] = _nicknameController.text;
          widget.registrationData['fullName'] = _nicknameController.text;
          widget.registrationData['cpf'] =
              _cpfController.text.replaceAll(RegExp(r'[^0-9]'), '');
          widget.registrationData['birthday'] = birthdateToSend;
          widget.registrationData['pronouns'] = _selectedPronoun;
          apiResponse = await _apiService.register(widget.registrationData);
        }

        if (mounted && apiResponse != null) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (context) =>
                    RegistrationSuccessScreen(userData: apiResponse!)),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Erro: ${e.toString().replaceAll("Exception: ", "")}')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: darkTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- CHAMADA CORRIGIDA AQUI ---
                _buildBreadcrumbs(),
                const SizedBox(height: 32),
                const Text(
                  'Queremos te conhecer!',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: darkTextColor),
                ),
                const SizedBox(height: 8),
                const Text('Conta um pouco mais sobre tu',
                    style: TextStyle(fontSize: 16, color: passwordStepColor)),
                const SizedBox(height: 40),
                _buildTextField(
                  controller: _nicknameController,
                  label: 'Como você quer ser chamado? *',
                  validator: (value) =>
                      value!.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  controller: _cpfController,
                  label: 'Qual seu CPF? *',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CpfInputFormatter()
                  ],
                  validator: _validateCpf,
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  controller: _birthdayController,
                  label: 'Preencha sua data de nascimento *',
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  suffixIcon: const Icon(Icons.calendar_today_outlined,
                      color: lightTextColor),
                  validator: (value) =>
                      value!.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  controller: _pronounController,
                  label: 'Qual seu pronome? *',
                  readOnly: true,
                  onTap: _selectPronoun,
                  suffixIcon:
                      const Icon(Icons.arrow_drop_down, color: lightTextColor),
                  validator: (value) =>
                      value!.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 40),
                _buildPrimaryButton('Finalizar cadastro',
                    _submitFinalRegistration, _isLoading, false),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: darkTextColor)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            filled: true,
            fillColor: fieldBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }

  Widget _buildBreadcrumbs() {
    const int currentStep = 3;
    return Row(
      children: [
        _buildStepIndicator(
          step: 1,
          currentStep: currentStep,
          icon: Icons.mark_email_read_outlined,
          activeColor: verificationStepColor,
        ),
        _buildConnector(isComplete: currentStep > 1, color: passwordStepColor),
        _buildStepIndicator(
          step: 2,
          currentStep: currentStep,
          icon: Icons.lock_outline,
          activeColor: passwordStepColor,
        ),
        _buildConnector(isComplete: currentStep > 2, color: infoStepColor),
        _buildStepIndicator(
          step: 3,
          currentStep: currentStep,
          icon: Icons.person_outline,
          activeColor: infoStepColor,
        ),
      ],
    );
  }

  Widget _buildStepIndicator({
    required int step,
    required int currentStep,
    required IconData icon,
    required Color activeColor,
  }) {
    final bool isActive = step == currentStep;
    final bool isComplete = step < currentStep;
    final Color color = isActive || isComplete ? activeColor : Colors.grey[400]!;

    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          step.toString(),
          style: TextStyle(
            color: color,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
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

Widget _buildPrimaryButton(
    String text, VoidCallback onPressed, bool isLoading, bool showArrow) {
  return ElevatedButton(
    onPressed: isLoading ? null : onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryButtonColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      minimumSize: const Size(double.infinity, 50),
      elevation: 0,
    ),
    child: isLoading
        ? const SizedBox(
            height: 24,
            width: 24,
            child:
                CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(text,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              if (showArrow) const SizedBox(width: 8),
              if (showArrow) const Icon(Icons.arrow_forward),
            ],
          ),
  );
}

class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (newText.length > 11) return oldValue;
    var formattedText = '';
    for (int i = 0; i < newText.length; i++) {
      formattedText += newText[i];
      if ((i == 2 || i == 5) && i != newText.length - 1) {
        formattedText += '.';
      } else if (i == 8 && i != newText.length - 1) {
        formattedText += '-';
      }
    }
    return newValue.copyWith(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}