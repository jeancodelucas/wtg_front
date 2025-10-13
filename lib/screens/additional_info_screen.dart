// lib/screens/additional_info_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:wtg_front/screens/registration_success_screen.dart';
import 'package:wtg_front/services/api_service.dart';

// --- PALETA DE CORES ATUALIZADA ---
const Color primaryColor = Color(0xFF214886);
const Color lightTextColor = Color(0xFF6B7280);
const Color darkTextColor = Color(0xFF1F2937);
const Color fieldBackgroundColor = Color(0xFFF9FAFB);
const Color borderColor = Color(0xFFD1D5DB);

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
  String? _selectedPronoun;
  bool _isLoading = false;

  final List<String> _pronouns = ['ele/dele', 'ela/dela', 'elu/delu', 'Outro'];

  @override
  void dispose() {
    _nicknameController.dispose();
    _cpfController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  String? _validateCpf(String? cpf) {
    if (cpf == null || cpf.isEmpty) return 'CPF é obrigatório.';
    String numbers = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (numbers.length != 11) return 'CPF inválido (deve conter 11 dígitos).';
    if (RegExp(r'^(\d)\1*$').hasMatch(numbers)) return 'CPF inválido.';

    List<int> digits = numbers.runes.map((r) => int.parse(String.fromCharCode(r))).toList();
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

  Future<void> _submitFinalRegistration() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      widget.registrationData['firstName'] = _nicknameController.text;
      widget.registrationData['fullName'] = _nicknameController.text;
      widget.registrationData['cpf'] = _cpfController.text.replaceAll(RegExp(r'[^0-9]'), '');
      widget.registrationData['pronouns'] = _selectedPronoun;

      try {
        await _apiService.register(widget.registrationData);

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const RegistrationSuccessScreen(),
            ),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Erro no cadastro: ${e.toString().replaceAll("Exception: ", "")}')),
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
                _buildBreadcrumbs(),
                const SizedBox(height: 24),
                const Text(
                  'Queremos te conhecer!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: darkTextColor),
                ),
                const SizedBox(height: 8),
                const Text('Conta um pouco mais sobre tu', style: TextStyle(fontSize: 16, color: lightTextColor)),
                const SizedBox(height: 40),
                _buildTextField(
                  controller: _nicknameController,
                  label: 'Como você quer ser chamado? *',
                  validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  controller: _cpfController,
                  label: 'Qual seu CPF? *',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, CpfInputFormatter()],
                  validator: _validateCpf,
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  controller: _birthdayController,
                  label: 'Preencha sua data de nascimento *',
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  suffixIcon: const Icon(Icons.calendar_today_outlined, color: lightTextColor),
                  validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 24),
                _buildDropdownField(),
                const SizedBox(height: 40),
                _buildPrimaryButton('Finalizar cadastro', _submitFinalRegistration, _isLoading, false),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBreadcrumbs() {
    return Row(
      children: [
        _buildBreadcrumbItem(isActive: true),
        const SizedBox(width: 8),
        _buildBreadcrumbItem(isActive: true),
        const SizedBox(width: 8),
        _buildBreadcrumbItem(isActive: true),
      ],
    );
  }

  Widget _buildBreadcrumbItem({required bool isActive}) {
    return Expanded(
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          color: isActive ? primaryColor : borderColor,
          borderRadius: BorderRadius.circular(2),
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
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: darkTextColor)),
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Qual seu pronome? *', style: TextStyle(fontWeight: FontWeight.bold, color: darkTextColor)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedPronoun,
          hint: const Text('Selecione', style: TextStyle(color: lightTextColor)),
          decoration: InputDecoration(
            filled: true,
            fillColor: fieldBackgroundColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          items: _pronouns.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          onChanged: (String? newValue) => setState(() => _selectedPronoun = newValue),
          validator: (value) => value == null ? 'Campo obrigatório' : null,
        ),
      ],
    );
  }
}

Widget _buildPrimaryButton(String text, VoidCallback onPressed, bool isLoading, bool showArrow) {
  return ElevatedButton(
    onPressed: isLoading ? null : onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      minimumSize: const Size(double.infinity, 50),
      elevation: 0,
    ),
    child: isLoading
        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              if (showArrow) const SizedBox(width: 8),
              if (showArrow) const Icon(Icons.arrow_forward),
            ],
          ),
  );
}

class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
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