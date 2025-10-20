// lib/screens/promotion/create_promotion_step1_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:wtg_front/models/promotion_type.dart';
import 'package:wtg_front/screens/promotion/create_promotion_step2_screen.dart';

// --- PALETA DE CORES PADRONIZADA ---
const Color darkBackgroundColor = Color(0xFF1A202C);
const Color primaryTextColor = Colors.white;
const Color secondaryTextColor = Color(0xFFA0AEC0);
const Color fieldBackgroundColor = Color(0xFF2D3748);
const Color fieldBorderColor = Color(0xFF4A5568);
const Color primaryButtonColor = Color(0xFFE53E3E);

// --- NOVA COR DE DESTAQUE ---
const Color accentColor = Color(0xFF218c74); // Novo tom de Verde

// Cores do Breadcrumb
const Color step2Color = Color(0xFFF6AD55); // Laranja
const Color step3Color = Color(0xFFF56565); // Vermelho

class CreatePromotionStep1Screen extends StatefulWidget {
  final Map<String, dynamic> loginResponse;
  const CreatePromotionStep1Screen({super.key, required this.loginResponse});

  @override
  State<CreatePromotionStep1Screen> createState() =>
      _CreatePromotionStep1ScreenState();
}

class _CreatePromotionStep1ScreenState
    extends State<CreatePromotionStep1Screen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _infoController = TextEditingController();
  final _obsController = TextEditingController();
  final _ticketValueController = TextEditingController();
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  PromotionType? _selectedPromotionType;
  bool _isFree = true;
  bool _isLoading = false;

  // --- NENHUMA ALTERAÇÃO NA LÓGICA ABAIXO ---

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
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Você pode selecionar no máximo 6 imagens.')));
      return;
    }
    final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 85, limit: 6 - _selectedImages.length);
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
      if (_selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Por favor, adicione pelo menos uma imagem.')));
        return;
      }

      final promotionData = {
        'title': _nomeController.text,
        'description': _infoController.text,
        'obs': _obsController.text,
        'promotionType': _selectedPromotionType?.name,
        'free': _isFree,
        'ticketValue':
            !_isFree ? _ticketValueController.text.replaceAll(',', '.') : null,
        'active': true,
        'images': _selectedImages,
        'loginResponse': widget.loginResponse,
      };
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) =>
            CreatePromotionStep2Screen(promotionData: promotionData),
      ));
    }
  }

  // --- BUILD METHOD E WIDGETS DE UI ATUALIZADOS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackgroundColor,
      appBar: AppBar(
        backgroundColor: darkBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: secondaryTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Cadastre seu Rolê',
            style: TextStyle(
                color: primaryTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 22)),
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
                _buildBreadcrumbs(),
                const SizedBox(height: 24),
                _buildSectionTitle(
                    "Fotos do Rolê", "Adicione até 6 fotos do seu evento."),
                _buildImageGrid(),
                const SizedBox(height: 32),
                _buildSectionTitle(
                    "Sobre o Rolê", "Dê um nome e descreva seu evento."),
                _buildTextField(
                    label: 'Nome do rolê *',
                    controller: _nomeController,
                    hint: 'Ex: Show na Praia',
                    icon: Icons.festival_outlined),
                const SizedBox(height: 24),
                _buildTypeAndFreeRow(),
                const SizedBox(height: 24),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child:
                      !_isFree ? _buildTicketValueField() : const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),
                _buildTextField(
                    label: 'Informações adicionais *',
                    hint: 'Ex: show do DJ na areia da praia...',
                    controller: _infoController,
                    icon: Icons.notes_outlined,
                    maxLines: 4),
                const SizedBox(height: 24),
                _buildTextField(
                    label: 'Observações',
                    hint: 'Ex: Levar protetor solar',
                    controller: _obsController,
                    icon: Icons.info_outline,
                    maxLines: 2),
                const SizedBox(height: 40),
                _buildPrimaryButton(
                    'Continuar', _continueToNextStep, _isLoading),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primaryTextColor)),
        const SizedBox(height: 8),
        Text(subtitle,
            style: const TextStyle(fontSize: 15, color: secondaryTextColor)),
        const SizedBox(height: 16),
        const Divider(color: fieldBorderColor),
        const SizedBox(height: 24),
      ],
    );
  }
  
  Widget _buildBreadcrumbs() {
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.4,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildStep(icon: Icons.storefront, stepColor: accentColor, isActive: true),
            _buildConnector(isComplete: false, color: step2Color),
            _buildStep(icon: Icons.location_on_outlined, stepColor: step2Color),
            _buildConnector(isComplete: false, color: step3Color),
            _buildStep(icon: Icons.check, stepColor: step3Color),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({
    required IconData icon,
    required Color stepColor,
    bool isActive = false,
    bool isComplete = false,
  }) {
    final double iconSize = isActive ? 26.0 : 20.0;
    final double containerSize = isActive ? 44.0 : 38.0;
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

  Widget _buildImageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
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
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                    color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
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
      child: DottedBorder(
        color: fieldBorderColor,
        strokeWidth: 2,
        dashPattern: const [6, 6],
        borderType: BorderType.RRect,
        radius: const Radius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: fieldBackgroundColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Center(
            child: Icon(
              isFirstPlaceholder ? Icons.camera_alt_outlined : Icons.add,
              color: secondaryTextColor,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      {required String label,
      String? hint,
      required TextEditingController controller,
      required IconData icon,
      int maxLines = 1,
      TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: primaryTextColor),
      validator: (value) =>
          (label.contains('*') && (value == null || value.isEmpty))
              ? 'Campo obrigatório'
              : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: fieldBorderColor),
        labelStyle: const TextStyle(color: secondaryTextColor),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: Icon(icon, color: accentColor),
        filled: true,
        fillColor: fieldBackgroundColor,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: fieldBorderColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: accentColor, width: 2)),
      ),
    );
  }

  Widget _buildTypeAndFreeRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          flex: 3,
          child: DropdownButtonFormField<PromotionType>(
            value: _selectedPromotionType,
            hint: const Text('Selecione',
                style: TextStyle(color: secondaryTextColor)),
            onChanged: (value) {
              setState(() {
                _selectedPromotionType = value;
              });
            },
            items: PromotionType.values.map((type) {
              return DropdownMenuItem(
                  value: type, child: Text(type.displayName));
            }).toList(),
            validator: (value) => value == null ? 'Obrigatório' : null,
            style: const TextStyle(color: primaryTextColor, fontSize: 16),
            dropdownColor: fieldBackgroundColor,
            decoration: InputDecoration(
              labelText: 'Tipo do Rolê *',
              labelStyle: const TextStyle(color: secondaryTextColor),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              prefixIcon:
                  const Icon(Icons.category_outlined, color: accentColor),
              filled: true,
              fillColor: fieldBackgroundColor,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: fieldBorderColor)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: accentColor, width: 2)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Padding(
          padding: const EdgeInsets.only(bottom: 5.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Gratuito?',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: secondaryTextColor,
                      fontSize: 16)),
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
                activeColor: accentColor,
                trackOutlineColor: MaterialStateProperty.all(fieldBorderColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTicketValueField() {
    return _buildTextField(
      controller: _ticketValueController,
      label: 'Valor do Ingresso (R\$) *',
      icon: Icons.attach_money_outlined,
      hint: 'Ex: 25,50',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }

  Widget _buildPrimaryButton(
      String text, VoidCallback onPressed, bool isLoading) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryButtonColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 64),
        padding: const EdgeInsets.symmetric(vertical: 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
}