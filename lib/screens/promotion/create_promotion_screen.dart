import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';
import 'package:wtg_front/models/promotion_type.dart';
import 'package:wtg_front/services/api_service.dart';
import 'map_confirmation_screen.dart';

// Estilos
const Color primaryButtonColor = Color(0xFFd74533);
const Color darkTextColor = Color(0xFF002956);
const Color fieldBackgroundColor = Color(0xFFF9FAFB);

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

  @override
  void dispose() {
    // Limpeza de todos os controllers
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Você já selecionou o máximo de 6 imagens.')));
      return;
    }
    final List<XFile> pickedFiles = await _picker.pickMultiImage(imageQuality: 80);
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
    if (_addressController.text.isEmpty || _numberController.text.isEmpty || _postalCodeController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha o Logradouro, Número e CEP para buscar a localização.')));
        return;
    }
    
    setState(() => _isGeocodingLoading = true);

    try {
        final String fullAddress = '${_addressController.text}, ${_numberController.text} - ${_postalCodeController.text}, ${_cityController.text}';
        final locations = await locationFromAddress(fullAddress);

        if (locations.isEmpty) {
          throw Exception('Endereço não encontrado. Verifique os dados.');
        }

        final initialCoords = {
          'latitude': locations.first.latitude,
          'longitude': locations.first.longitude,
        };

        if (!mounted) return;

        final finalCoords = await Navigator.of(context).push<Map<String, double>>(
            MaterialPageRoute(
                builder: (context) => MapConfirmationScreen(
                    initialLatitude: initialCoords['latitude']!,
                    initialLongitude: initialCoords['longitude']!,
                ),
            ),
        );

        if (finalCoords != null) {
            setState(() { _confirmedCoordinates = finalCoords; });
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Localização confirmada!')));
        }
    } catch (e) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao buscar endereço: ${e.toString().replaceAll("Exception: ", "")}')));
        }
    } finally {
        if (mounted) setState(() => _isGeocodingLoading = false);
    }
  }

  Future<void> _submitPromotion() async {
    if (!_formKey.currentState!.validate() || _confirmedCoordinates == null || _selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, preencha todos os campos, adicione imagens e confirme a localização.')));
        return;
    }

    setState(() => _isLoading = true);
    
    String? cookie;
    String? newPromotionId;

    try {
        // ETAPA 1: Obter o cookie de autenticação
        final prefs = await SharedPreferences.getInstance();
        cookie = prefs.getString('session_cookie');
        if (cookie == null) throw Exception('Sessão expirada. Faça o login novamente.');

        // ETAPA 2: Montar o payload (flag 'free' é controlada pelo backend agora)
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
        
        // ETAPA 3: Criar a promoção (retorna a promoção com ID)
        final createResponse = await _apiService.createPromotion(promotionData, cookie);
        newPromotionId = createResponse['id']?.toString();
        if (newPromotionId == null) throw Exception('Não foi possível obter o ID da promoção criada.');
        
        // ETAPA 4: Fazer o upload das imagens
        if (_selectedImages.isNotEmpty) {
          await _apiService.uploadPromotionImages(newPromotionId, _selectedImages, cookie);
        }
        
        // ETAPA 5: Finalizar o cadastro (atualizar a flag 'free' para true)
        await _apiService.completePromotionRegistration(newPromotionId, cookie);

        if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seu rolê foi cadastrado com sucesso!')));
            Navigator.of(context).pop();
        }
    } catch (e) {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao cadastrar: ${e.toString().replaceAll("Exception: ", "")}')));
        }
    } finally {
         if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastre seu Rolê', style: TextStyle(color: darkTextColor)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: darkTextColor),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageGrid(),
              const SizedBox(height: 16),
              _buildTextField(controller: _titleController, label: 'Nome do Rolê *'),
              const SizedBox(height: 16),
              
              Text('Qual o tipo desse rolê? *', style: const TextStyle(fontWeight: FontWeight.bold, color: darkTextColor)),
              const SizedBox(height: 8),
              DropdownButtonFormField<PromotionType>(
                value: _selectedPromotionType,
                items: PromotionType.values.map((type) {
                  return DropdownMenuItem<PromotionType>(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (PromotionType? newValue) {
                  setState(() { _selectedPromotionType = newValue; });
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: fieldBackgroundColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                validator: (value) => value == null ? 'Campo obrigatório' : null,
              ),

              const SizedBox(height: 16),
              _buildTextField(controller: _descriptionController, label: 'Descrição do rolê *', maxLines: 3),
              const SizedBox(height: 16),
              _buildTextField(controller: _obsController, label: 'Alguma observação?', maxLines: 2),
              const SizedBox(height: 24),

              const Text("Endereço do Rolê", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkTextColor)),
              const Divider(),
              const SizedBox(height: 16),

              _buildTextField(controller: _addressController, label: 'Logradouro *'),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(child: _buildTextField(controller: _numberController, label: 'Nº *', keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(controller: _postalCodeController, label: 'CEP *', keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(controller: _complementController, label: 'Complemento'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField(controller: _cityController, label: 'Cidade *')),
                  const SizedBox(width: 16),
                  SizedBox(width: 100, child: _buildTextField(controller: _ufController, label: 'Estado *')),
                ],
              ),
              const SizedBox(height: 16),
               _buildTextField(controller: _referenceController, label: 'Ponto de referência'),
              const SizedBox(height: 16),
              _buildTextField(controller: _addressObsController, label: 'Observações sobre o endereço?', maxLines: 2),
              const SizedBox(height: 24),
              
              if (_confirmedCoordinates != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('Localização confirmada no mapa!', style: TextStyle(color: Colors.green))),
                      TextButton(onPressed: _geocodeAddressAndShowMap, child: const Text('Ajustar'))
                    ],
                  ),
                )
              else 
                OutlinedButton.icon(
                  icon: _isGeocodingLoading ? const SizedBox.shrink() : const Icon(Icons.map_outlined),
                  label: _isGeocodingLoading ? const CircularProgressIndicator() : const Text('Buscar e confirmar no mapa'),
                  onPressed: _isGeocodingLoading || _isLoading ? null : _geocodeAddressAndShowMap,
                  style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
                
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading || _isGeocodingLoading ? null : _submitPromotion,
                style: ElevatedButton.styleFrom(backgroundColor: primaryButtonColor, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Salvar Rolê', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

   Widget _buildImageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _selectedImages.length + 1,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
      itemBuilder: (context, index) {
        if (index == _selectedImages.length) {
          return _buildAddImageButton();
        }
        return Stack(
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_selectedImages[index], width: double.infinity, height: double.infinity, fit: BoxFit.cover)),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeImage(index),
                child: const CircleAvatar(radius: 12, backgroundColor: Colors.black54, child: Icon(Icons.close, color: Colors.white, size: 16)),
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
            color: Colors.grey.shade400,
            strokeWidth: 1,
            dashPattern: const [6, 6],
            borderType: BorderType.RRect,
            radius: const Radius.circular(12),
            child: InkWell(
              onTap: _pickImages,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(color: fieldBackgroundColor, borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Icon(Icons.add_a_photo_outlined, color: Colors.grey)),
              ),
            ),
          )
        : const SizedBox.shrink();
  }
  
  Widget _buildTextField({required TextEditingController controller, required String label, int? maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: darkTextColor)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: (value) {
            if (label.trim().endsWith('*') && (value == null || value.isEmpty)) {
              return 'Campo obrigatório';
            }
            return null;
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: fieldBackgroundColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}