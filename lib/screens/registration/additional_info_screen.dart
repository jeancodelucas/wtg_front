// lib/screens/registration/additional_info_screen.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wtg_front/screens/registration_success_screen.dart';
import 'package:wtg_front/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';


// --- PALETA DE CORES (ESCURA E VIBRANTE) ---
const Color darkBackgroundColor = Color(0xFF1A202C);
const Color primaryTextColor = Colors.white;
const Color secondaryTextColor = Color(0xFFA0AEC0);
const Color fieldBackgroundColor = Color(0xFF2D3748);
const Color fieldBorderColor = Color(0xFF4A5568);
const Color primaryButtonColor = Color(0xFFE53E3E);

// Cores dos ícones e etapas do Breadcrumb
const Color verificationStepColor = Color(0xFF4299E1);
const Color passwordStepColor = Color(0xFFF6AD55);
const Color infoStepColor = Color(0xFFF56565);

// --- ENUM PARA TIPO DE DOCUMENTO ---
enum DocumentType { cpf, cnpj }

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
  final _cnpjController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _pronounController = TextEditingController();

  String? _selectedPronoun;
  bool _isLoading = false;
  DocumentType? _selectedDocumentType;
  File? _selectedImageFile;
  String? _networkImageUrl;

  final List<String> _pronouns = [
    'Ele/Dele',
    'Ela/Dela',
    'Elu/Delu',
    'Outro',
    'Prefiro não dizer'
  ];

  @override
  void initState() {
    super.initState();
    // Verifica se já existe uma URL de imagem (vinda do SSO)
    final pictureUrl = widget.registrationData['user']?['pictureUrl'];
    if (pictureUrl != null) {
      _networkImageUrl = pictureUrl;
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _cpfController.dispose();
    _cnpjController.dispose();
    _birthdayController.dispose();
    _pronounController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = File(pickedFile.path);
        _networkImageUrl = null; // Prioriza a imagem local selecionada
      });
    }
  }


  // --- LÓGICAS DE VALIDAÇÃO E PICKERS (inalteradas) ---
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

  String? _validateCnpj(String? cnpj) {
    if (cnpj == null || cnpj.isEmpty) return 'CNPJ é obrigatório.';
    String numbers = cnpj.replaceAll(RegExp(r'[^0-9]'), '');
    if (numbers.length != 14) return 'CNPJ inválido (deve conter 14 dígitos).';
    if (RegExp(r'^(\d)\1*$').hasMatch(numbers)) return 'CNPJ inválido.';

    List<int> digits =
        numbers.runes.map((r) => int.parse(String.fromCharCode(r))).toList();
    List<int> weights1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    List<int> weights2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    int calc(List<int> weights) {
      int sum = 0;
      for (int i = 0; i < weights.length; i++) {
        sum += digits[i] * weights[i];
      }
      int result = sum % 11;
      return result < 2 ? 0 : 11 - result;
    }
    if (calc(weights1) != digits[12] || calc(weights2) != digits[13]) {
      return 'CNPJ inválido.';
    }
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

      String? pictureUrl = _networkImageUrl;

      try {
        final isSsoUser = widget.registrationData['isSsoUser'] ?? false;
        String? sessionCookie = widget.registrationData['cookie'];
        
        if (sessionCookie == null && !isSsoUser) {
           final tempPayload = { ...widget.registrationData };
           tempPayload['firstName'] = _nicknameController.text;
           tempPayload['fullName'] = _nicknameController.text;
           tempPayload['cpf'] = _selectedDocumentType == DocumentType.cpf ? _cpfController.text.replaceAll(RegExp(r'[^0-9]'), '') : null;
           tempPayload['cnpj'] = _selectedDocumentType == DocumentType.cnpj ? _cnpjController.text.replaceAll(RegExp(r'[^0-9]'), '') : null;

           final initialResponse = await _apiService.register(tempPayload);
           sessionCookie = initialResponse['cookie'];
           if (sessionCookie == null) throw Exception("Falha ao obter sessão após o registro inicial.");
        }
        
        if (sessionCookie == null) throw Exception("Sessão de usuário inválida.");

        if (_selectedImageFile != null) {
          pictureUrl = await _apiService.uploadProfilePicture(_selectedImageFile!, sessionCookie);
        }

        String birthdateToSend = '';
        if (_birthdayController.text.isNotEmpty) {
          DateTime parsedDate = DateFormat('dd/MM/yyyy').parse(_birthdayController.text);
          birthdateToSend = DateFormat('yyyy-MM-dd').format(parsedDate);
        }
        
        final String pronounToSend = _selectedDocumentType == DocumentType.cnpj ? 'Ele/Dele' : _selectedPronoun ?? '';
        
        final finalUserData = {
          "firstName": _nicknameController.text,
          "cpf": _selectedDocumentType == DocumentType.cpf ? _cpfController.text.replaceAll(RegExp(r'[^0-9]'), '') : null,
          "cnpj": _selectedDocumentType == DocumentType.cnpj ? _cnpjController.text.replaceAll(RegExp(r'[^0-9]'), '') : null,
          "birthday": birthdateToSend,
          "pronouns": pronounToSend,
          "pictureUrl": pictureUrl, 
        };

        final updatedUser = await _apiService.updateUser(finalUserData, sessionCookie);
        
        final apiResponse = {
          'user': updatedUser,
          'cookie': sessionCookie,
        };

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
                builder: (context) =>
                    RegistrationSuccessScreen(userData: apiResponse)),
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
        backgroundColor: darkBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: secondaryTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          _buildBreadcrumbs(),
          const SizedBox(width: 16)
        ],
      ),
      backgroundColor: darkBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildProfilePictureUploader(), // WIDGET DA FOTO
                        const SizedBox(height: 32),
                        const Text(
                          'Queremos te conhecer!',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: primaryTextColor),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Conte um pouco mais sobre você para uma experiência completa.',
                          style: TextStyle(fontSize: 16, color: secondaryTextColor),
                        ),
                        const SizedBox(height: 32),
                        _buildTextField(
                          controller: _nicknameController,
                          label: 'Como você quer ser chamado? *',
                          icon: Icons.person_outline,
                          iconColor: infoStepColor,
                          validator: (value) =>
                              value!.isEmpty ? 'Campo obrigatório' : null,
                        ),
                        const SizedBox(height: 20),
                        _buildDocumentSelector(),
                        const SizedBox(height: 20),
                        
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return SizeTransition(
                              sizeFactor: animation,
                              child: child,
                            );
                          },
                          child: _selectedDocumentType == null
                              ? const SizedBox.shrink()
                              : _selectedDocumentType == DocumentType.cpf
                                ? _buildTextField(
                                    key: const ValueKey('cpf'),
                                    controller: _cpfController,
                                    label: 'Qual seu CPF? *',
                                    icon: Icons.badge_outlined,
                                    iconColor: infoStepColor,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      CpfInputFormatter()
                                    ],
                                    validator: _validateCpf,
                                  )
                                : _buildTextField(
                                    key: const ValueKey('cnpj'),
                                    controller: _cnpjController,
                                    label: 'Qual o CNPJ do rolê? *',
                                    icon: Icons.business_center_outlined,
                                    iconColor: infoStepColor,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      CnpjInputFormatter()
                                    ],
                                    validator: _validateCnpj,
                                  ),
                        ),

                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _birthdayController,
                          label: 'Sua data de nascimento *',
                          icon: Icons.calendar_today_outlined,
                          iconColor: infoStepColor,
                          readOnly: true,
                          onTap: () => _selectDate(context),
                          validator: (value) =>
                              value!.isEmpty ? 'Campo obrigatório' : null,
                        ),
                        const SizedBox(height: 20),

                        AnimatedSwitcher(
                           duration: const Duration(milliseconds: 300),
                           transitionBuilder: (child, animation) {
                            return SizeTransition(
                              sizeFactor: animation,
                              child: child,
                            );
                          },
                          child: _selectedDocumentType == DocumentType.cpf
                              ? _buildTextField(
                                  key: const ValueKey('pronoun'),
                                  controller: _pronounController,
                                  label: 'Qual seu pronome? *',
                                  icon: Icons.wc_outlined,
                                  iconColor: infoStepColor,
                                  tooltipMessage:
                                      'Para que possamos nos dirigir a você de forma correta, por favor nos diga como gostaria de ser chamado!',
                                  readOnly: true,
                                  onTap: _selectPronoun,
                                  validator: (value) =>
                                      value!.isEmpty ? 'Campo obrigatório' : null,
                                )
                              : const SizedBox.shrink(),
                        ),

                        const Spacer(),
                        const SizedBox(height: 24),
                        _buildPrimaryButton(
                          'Finalizar cadastro',
                          _submitFinalRegistration,
                          _isLoading,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  // --- NOVO WIDGET PARA A FOTO DE PERFIL ---
  Widget _buildProfilePictureUploader() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: fieldBackgroundColor,
            backgroundImage: _selectedImageFile != null
                ? FileImage(_selectedImageFile!)
                : (_networkImageUrl != null
                    ? NetworkImage(_networkImageUrl!)
                    : null) as ImageProvider?,
            child: (_selectedImageFile == null && _networkImageUrl == null)
                ? const Icon(Icons.person, size: 50, color: secondaryTextColor)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: infoStepColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: darkBackgroundColor, width: 2),
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Esse rolê é de uma pessoa física ou tem CNPJ?',
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: 16.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildChoiceChip(
                label: 'Pessoa Física (CPF)',
                selected: _selectedDocumentType == DocumentType.cpf,
                onSelected: (selected) {
                  setState(() {
                    _selectedDocumentType = DocumentType.cpf;
                    _cnpjController.clear();
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildChoiceChip(
                label: 'Pessoa Jurídica (CNPJ)',
                selected: _selectedDocumentType == DocumentType.cnpj,
                onSelected: (selected) {
                   setState(() {
                    _selectedDocumentType = DocumentType.cnpj;
                    _cpfController.clear();
                    // Limpa o campo de pronome ao selecionar CNPJ
                    _pronounController.clear(); 
                    _selectedPronoun = null;
                  });
                },
              ),
            ),
          ],
        )
      ],
    );
  }
  
  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: fieldBackgroundColor,
      selectedColor: infoStepColor,
      labelStyle: TextStyle(
        color: selected ? Colors.white : secondaryTextColor,
        fontWeight: FontWeight.bold,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? infoStepColor : fieldBorderColor,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      showCheckmark: false,
    );
  }
  
  Widget _buildBreadcrumbs() {
    return SizedBox(
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
            isComplete: true,
          ),
          _buildConnector(isComplete: true, color: infoStepColor),
          _buildStep(
            icon: Icons.person_add_alt_1_outlined,
            stepColor: infoStepColor,
            isActive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required IconData icon,
    required Color stepColor,
    bool isActive = false,
    bool isComplete = false,
  }) {
    final double iconSize = isActive ? 28.0 : 22.0;
    final double containerSize = isActive ? 48.0 : 40.0;
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

  Widget _buildTextField({
    Key? key,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color iconColor,
    String? tooltipMessage,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: secondaryTextColor,
                fontSize: 16.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (tooltipMessage != null)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Tooltip(
                  message: tooltipMessage,
                  child: const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: secondaryTextColor,
                  ),
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                      color: fieldBackgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: fieldBorderColor)),
                  textStyle: const TextStyle(color: primaryTextColor),
                  triggerMode: TooltipTriggerMode.tap,
                  preferBelow: false,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          readOnly: readOnly,
          onTap: onTap,
          style: const TextStyle(
              color: primaryTextColor, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: iconColor, size: 22),
            suffixIcon: (readOnly && onTap != null)
                ? const Icon(Icons.arrow_drop_down, color: secondaryTextColor)
                : null,
            filled: true,
            fillColor: fieldBackgroundColor,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: fieldBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: fieldBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: iconColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 2),
            ),
          ),
        ),
      ],
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

class CnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (newText.length > 14) return oldValue;
    var formattedText = '';
    for (int i = 0; i < newText.length; i++) {
      formattedText += newText[i];
      if (i == 1 && i != newText.length - 1) {
        formattedText += '.';
      } else if (i == 4 && i != newText.length - 1) {
        formattedText += '.';
      } else if (i == 7 && i != newText.length - 1) {
        formattedText += '/';
      } else if (i == 11 && i != newText.length - 1) {
        formattedText += '-';
      }
    }
    return newValue.copyWith(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}