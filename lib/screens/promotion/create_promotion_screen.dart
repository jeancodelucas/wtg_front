// lib/screens/promotion/create_promotion_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';
import 'package:wtg_front/models/promotion_type.dart';
import 'package:wtg_front/services/api_service.dart';
import 'map_confirmation_screen.dart';

// --- PALETA DE CORES PADRONIZADA ---
const Color darkBackgroundColor = Color(0xFF1A202C);
const Color primaryTextColor = Colors.white;
const Color secondaryTextColor = Color(0xFFA0AEC0);
const Color fieldBackgroundColor = Color(0xFF2D3748);
const Color fieldBorderColor = Color(0xFF4A5568);
const Color primaryButtonColor = Color(0xFFE53E3E);
const Color accentColor = Color(0xFF4299E1);

class CreatePromotionScreen extends StatefulWidget {
  const CreatePromotionScreen({super.key});

  @override
  State<CreatePromotionScreen> createState() => _CreatePromotionScreenState();
}

class _CreatePromotionScreenState extends State<CreatePromotionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  bool _isLoading = false;
  bool _isGeocodingLoading = false;

  // Controladores para todos os campos
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _obsController = TextEditingController();
  final _addressController = TextEditingController();
  final _numberController = TextEditingController();
  final _complementController = TextEditingController();
  final _referenceController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _addressObsController = TextEditingController();
  final _cityController = TextEditingController();
  final _ufController = TextEditingController();

  // Variáveis de estado
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  Map<String, double>? _confirmedCoordinates;
  PromotionType? _selectedPromotionType;
  bool _isFree = false;

  // --- NENHUMA ALTERAÇÃO NA LÓGICA ABAIXO ---

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _obsController.dispose();
    _addressController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _referenceController.dispose();
    _postalCodeController.dispose();
    _cityController.dispose();
    _ufController.dispose();
    _addressObsController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Você já selecionou o máximo de 6 imagens.')));
      return;
    }
    final List<XFile> pickedFiles =
        await _picker.pickMultiImage(imageQuality: 80);
    if (pickedFiles.isNotEmpty) {
      setState(() {
        for (var file in pickedFiles) {
          if (_selectedImages.length < 6) {
            _selectedImages.add(File(file.path));
          }
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _geocodeAddressAndShowMap() async {
    FocusScope.of(context).unfocus();
    if (_addressController.text.isEmpty ||
        _numberController.text.isEmpty ||
        _postalCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Preencha o Logradouro, Número e CEP para buscar a localização.')));
      return;
    }

    setState(() => _isGeocodingLoading = true);

    try {
      final String fullAddress =
          '${_addressController.text}, ${_numberController.text} - ${_postalCodeController.text}, ${_cityController.text}';
      final locations = await locationFromAddress(fullAddress);

      if (locations.isEmpty) {
        throw Exception('Endereço não encontrado. Verifique os dados.');
      }

      final initialCoords = {
        'latitude': locations.first.latitude,
        'longitude': locations.first.longitude,
      };

      if (!mounted) return;

      final finalCoords =
          await Navigator.of(context).push<Map<String, double>>(
        MaterialPageRoute(
          builder: (context) => MapConfirmationScreen(
            initialLatitude: initialCoords['latitude']!,
            initialLongitude: initialCoords['longitude']!,
          ),
        ),
      );

      if (finalCoords != null) {
        setState(() {
          _confirmedCoordinates = finalCoords;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Localização confirmada!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Erro ao buscar endereço: ${e.toString().replaceAll("Exception: ", "")}')));
      }
    } finally {
      if (mounted) setState(() => _isGeocodingLoading = false);
    }
  }

  Future<void> _submitPromotion() async {
    if (!_formKey.currentState!.validate() ||
        _confirmedCoordinates == null ||
        _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Por favor, preencha todos os campos, adicione imagens e confirme a localização.')));
      return;
    }

    setState(() => _isLoading = true);

    String? cookie;
    String? newPromotionId;

    try {
      final prefs = await SharedPreferences.getInstance();
      cookie = prefs.getString('session_cookie');
      if (cookie == null)
        throw Exception('Sessão expirada. Faça o login novamente.');

      final promotionData = {
        "title": _titleController.text,
        "description": _descriptionController.text,
        "obs": _obsController.text,
        "promotionType": _selectedPromotionType!.name.toUpperCase(),
        "active": true,
        "address": {
          "address": _addressController.text,
          "number": int.tryParse(_numberController.text) ?? 0,
          "complement": _complementController.text,
          "reference": _referenceController.text,
          "postalCode": _postalCodeController.text,
          "obs": _addressObsController.text,
        },
        "latitude": _confirmedCoordinates!['latitude'],
        "longitude": _confirmedCoordinates!['longitude'],
      };

      final createResponse =
          await _apiService.createPromotion(promotionData, cookie);
      newPromotionId = createResponse['id']?.toString();
      if (newPromotionId == null)
        throw Exception('Não foi possível obter o ID da promoção criada.');

      if (_selectedImages.isNotEmpty) {
        await _apiService.uploadPromotionImages(
            newPromotionId, _selectedImages, cookie);
      }

      await _apiService.completePromotionRegistration(newPromotionId, cookie);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Seu rolê foi cadastrado com sucesso!')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Erro ao cadastrar: ${e.toString().replaceAll("Exception: ", "")}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- BUILD METHOD E WIDGETS DE UI ATUALIZADOS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastre seu Rolê',
            style: TextStyle(color: primaryTextColor)),
        backgroundColor: darkBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: secondaryTextColor),
      ),
      backgroundColor: darkBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Fotos do Rolê",
                  "Adicione até 6 fotos para mostrar o seu evento."),
              const SizedBox(height: 16),
              _buildImageGrid(),
              const SizedBox(height: 32),
              _buildSectionTitle(
                  "Sobre o Rolê", "Dê um nome e descreva seu evento."),
              _buildTextField(
                  controller: _titleController,
                  label: 'Nome do Rolê *',
                  icon: Icons.festival_outlined),
              const SizedBox(height: 16),
              _buildDropdownField(),
              const SizedBox(height: 16),
              _buildTextField(
                  controller: _descriptionController,
                  label: 'Descrição do rolê *',
                  icon: Icons.notes_outlined,
                  maxLines: 3),
              const SizedBox(height: 16),
              _buildTextField(
                  controller: _obsController,
                  label: 'Alguma observação?',
                  icon: Icons.info_outline,
                  maxLines: 2),
              const SizedBox(height: 32),
              _buildSectionTitle(
                  "Endereço do Rolê", "Onde o seu evento vai acontecer?"),
              _buildTextField(
                  controller: _addressController,
                  label: 'Logradouro *',
                  icon: Icons.location_on_outlined),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _buildTextField(
                          controller: _numberController,
                          label: 'Nº *',
                          icon: Icons.pin,
                          keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildTextField(
                          controller: _postalCodeController,
                          label: 'CEP *',
                          icon: Icons.local_post_office_outlined,
                          keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                  controller: _complementController,
                  label: 'Complemento',
                  icon: Icons.add_road_outlined),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _buildTextField(
                          controller: _cityController,
                          label: 'Cidade *',
                          icon: Icons.location_city_outlined)),
                  const SizedBox(width: 16),
                  SizedBox(
                      width: 100,
                      child: _buildTextField(
                          controller: _ufController,
                          label: 'Estado *',
                          icon: Icons.public_outlined)),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                  controller: _referenceController,
                  label: 'Ponto de referência',
                  icon: Icons.assistant_photo_outlined),
              const SizedBox(height: 16),
              _buildTextField(
                  controller: _addressObsController,
                  label: 'Observações sobre o endereço?',
                  icon: Icons.speaker_notes_outlined,
                  maxLines: 2),
              const SizedBox(height: 32),
              _buildMapButton(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
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
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _selectedImages.length + 1,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemBuilder: (context, index) {
        if (index == _selectedImages.length) {
          return _buildAddImageButton();
        }
        return Stack(
          children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_selectedImages[index],
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover)),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeImage(index),
                child: const CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close, color: Colors.white, size: 18)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddImageButton() {
    return _selectedImages.length < 6
        ? DottedBorder(
            color: fieldBorderColor,
            strokeWidth: 2,
            dashPattern: const [6, 6],
            borderType: BorderType.RRect,
            radius: const Radius.circular(12),
            child: InkWell(
              onTap: _pickImages,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                    color: fieldBackgroundColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12)),
                child: const Center(
                    child: Icon(Icons.add_a_photo_outlined,
                        color: secondaryTextColor, size: 32)),
              ),
            ),
          )
        : const SizedBox.shrink();
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      required IconData icon,
      int? maxLines = 1,
      TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: primaryTextColor),
      validator: (value) {
        if (label.trim().endsWith('*') && (value == null || value.isEmpty)) {
          return 'Campo obrigatório';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: secondaryTextColor),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: Icon(icon, color: accentColor),
        filled: true,
        fillColor: fieldBackgroundColor,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: accentColor, width: 2)),
      ),
    );
  }
  
  Widget _buildDropdownField() {
    return DropdownButtonFormField<PromotionType>(
      value: _selectedPromotionType,
      items: PromotionType.values.map((type) {
        return DropdownMenuItem<PromotionType>(
          value: type,
          child: Text(type.displayName),
        );
      }).toList(),
      onChanged: (PromotionType? newValue) {
        setState(() {
          _selectedPromotionType = newValue;
        });
      },
      style: const TextStyle(color: primaryTextColor, fontSize: 16),
      dropdownColor: fieldBackgroundColor,
      decoration: InputDecoration(
        labelText: 'Qual o tipo desse rolê? *',
        labelStyle: const TextStyle(color: secondaryTextColor),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: const Icon(Icons.category_outlined, color: accentColor),
        filled: true,
        fillColor: fieldBackgroundColor,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: accentColor, width: 2)),
      ),
      validator: (value) => value == null ? 'Campo obrigatório' : null,
    );
  }

  Widget _buildMapButton() {
    if (_confirmedCoordinates != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: fieldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green)
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            const Expanded(
                child: Text('Localização confirmada!',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16))),
            TextButton(
                onPressed: _geocodeAddressAndShowMap,
                child: const Text('Ajustar', style: TextStyle(color: secondaryTextColor, fontSize: 16)))
          ],
        ),
      );
    } else {
      return OutlinedButton.icon(
        icon: _isGeocodingLoading
            ? const SizedBox.shrink()
            : const Icon(Icons.map_outlined, color: accentColor),
        label: _isGeocodingLoading
            ? const CircularProgressIndicator(color: accentColor)
            : const Text('Buscar e confirmar no mapa', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
        onPressed: _isGeocodingLoading || _isLoading
            ? null
            : _geocodeAddressAndShowMap,
        style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            side: const BorderSide(color: accentColor, width: 2)
            ),
      );
    }
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading || _isGeocodingLoading ? null : _submitPromotion,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryButtonColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 64),
        padding: const EdgeInsets.symmetric(vertical: 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
      ),
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text('Salvar Rolê',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}