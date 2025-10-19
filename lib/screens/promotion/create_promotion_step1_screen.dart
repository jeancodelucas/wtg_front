import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wtg_front/models/promotion_type.dart';
import 'create_promotion_step2_screen.dart';

const Color primaryAppColor = Color(0xFF6A00FF);
const Color backgroundColor = Color(0xFFF8F8FA);
const Color textFieldBackgroundColor = Colors.white;
const Color placeholderColor = Color(0xFFE0E0E0);
const Color darkTextColor = Color(0xFF2D3748);
const Color lightTextColor = Color(0xFF718096);

class CreatePromotionStep1Screen extends StatefulWidget {
  final Map<String, dynamic> loginResponse;
  const CreatePromotionStep1Screen({super.key, required this.loginResponse});

  @override
  State<CreatePromotionStep1Screen> createState() => _CreatePromotionStep1ScreenState();
}

class _CreatePromotionStep1ScreenState extends State<CreatePromotionStep1Screen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _infoController = TextEditingController();
  final _obsController = TextEditingController();
  final _ticketValueController = TextEditingController();
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  PromotionType? _selectedPromotionType;
  bool _isFree = true; // Valor inicializado como true

  @override
  void dispose() {
    _nomeController.dispose();
    _infoController.dispose();
    _obsController.dispose();
    _ticketValueController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Você pode selecionar no máximo 6 imagens.')));
      return;
    }
    final List<XFile> pickedFiles = await _picker.pickMultiImage(imageQuality: 85, limit: 6 - _selectedImages.length);
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles.map((file) => File(file.path)));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _continueToNextStep() {
    if (_formKey.currentState!.validate()) {
      final promotionData = {
        'title': _nomeController.text,
        'description': _infoController.text,
        'obs': _obsController.text,
        // CORREÇÃO APLICADA AQUI: Enviando o nome do enum como String
        'promotionType': _selectedPromotionType?.name,
        'free': _isFree,
        'ticketValue': !_isFree ? _ticketValueController.text.replaceAll(',', '.') : null,
        'active': true,
        'images': _selectedImages,
        'loginResponse': widget.loginResponse,
      };
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => CreatePromotionStep2Screen(promotionData: promotionData),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: darkTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('cadastre seu rolé', style: TextStyle(color: darkTextColor, fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _buildBreadcrumbs(currentStep: 1),
                const SizedBox(height: 32),
                _buildImageGrid(),
                const SizedBox(height: 32),
                _buildTextField(label: 'Nome do rolê', controller: _nomeController),
                const SizedBox(height: 24),
                _buildTypeAndFreeRow(),
                const SizedBox(height: 24),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: !_isFree ? _buildTicketValueField() : const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),
                _buildTextField(label: 'Informações adicionais', hint: 'Ex: show do DJ na areia da praia', controller: _infoController),
                const SizedBox(height: 24),
                _buildTextField(label: 'Observações', controller: _obsController),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _continueToNextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFd74533),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Continuar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketValueField() {
    return Column(
      key: const ValueKey('ticket_value_field'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Valor do Ingresso (R\$) *',
            style: TextStyle(fontWeight: FontWeight.bold, color: darkTextColor, fontSize: 16)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _ticketValueController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'Ex: 25,50',
            filled: true,
            fillColor: textFieldBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: placeholderColor),
            ),
          ),
          validator: (value) {
            if (!_isFree) {
              if (value == null || value.isEmpty) {
                return 'O valor é obrigatório para eventos pagos.';
              }
              final price = double.tryParse(value.replaceAll(',', '.'));
              if (price == null || price <= 0) {
                return 'Por favor, insira um valor válido.';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBreadcrumbs({required int currentStep}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepIndicator(step: 1, currentStep: currentStep, icon: Icons.storefront),
        _buildConnector(isComplete: currentStep > 1),
        _buildStepIndicator(step: 2, currentStep: currentStep, icon: Icons.location_on_outlined),
        _buildConnector(isComplete: currentStep > 2),
        _buildStepIndicator(step: 3, currentStep: currentStep, icon: Icons.check),
      ],
    );
  }

  Widget _buildStepIndicator({required int step, required int currentStep, required IconData icon}) {
    final bool isActive = step == currentStep;
    final bool isComplete = step < currentStep;
    return Column(
      children: [
        Icon(icon, color: isActive || isComplete ? primaryAppColor : Colors.grey[400], size: 28),
        const SizedBox(height: 8),
        Text(step.toString(), style: TextStyle(color: isActive ? primaryAppColor : Colors.grey[400]))
      ],
    );
  }

  Widget _buildConnector({required bool isComplete}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 28, left: 8, right: 8),
        color: isComplete ? primaryAppColor : Colors.grey[300],
      ),
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) {
        if (index < _selectedImages.length) {
          return _buildImageItem(_selectedImages[index], index);
        } else {
          return _buildImagePlaceholder(index);
        }
      },
    );
  }

  Widget _buildImageItem(File imageFile, int index) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(imageFile, fit: BoxFit.cover),
          Positioned(
            top: 4, right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder(int index) {
    bool isFirstPlaceholder = index == _selectedImages.length;
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: placeholderColor, width: 1.5),
        ),
        child: Icon(isFirstPlaceholder ? Icons.camera_alt_outlined : Icons.add, color: Colors.grey[400], size: 32),
      ),
    );
  }

  Widget _buildTextField({required String label, String? hint, required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: darkTextColor, fontSize: 16)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: (value) => (value == null || value.isEmpty) ? 'Campo obrigatório' : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: textFieldBackgroundColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: placeholderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: placeholderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryAppColor, width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeAndFreeRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tipo', style: TextStyle(fontWeight: FontWeight.bold, color: darkTextColor, fontSize: 16)),
              const SizedBox(height: 8),
              DropdownButtonFormField<PromotionType>(
                value: _selectedPromotionType,
                hint: const Text('Selecione', style: TextStyle(color: Colors.grey)),
                onChanged: (value) {
                  setState(() { _selectedPromotionType = value; });
                },
                items: PromotionType.values.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type.displayName));
                }).toList(),
                validator: (value) => value == null ? 'Obrigatório' : null,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: textFieldBackgroundColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: placeholderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: placeholderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryAppColor, width: 2)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Gratuito', style: TextStyle(fontWeight: FontWeight.bold, color: darkTextColor, fontSize: 16)),
            const SizedBox(height: 8),
            Switch(
              value: _isFree,
              onChanged: (value) {
                setState(() { 
                  _isFree = value; 
                  if (_isFree) {
                    _ticketValueController.clear();
                  }
                });
              },
              activeColor: primaryAppColor,
            ),
          ],
        ),
      ],
    );
  }
}