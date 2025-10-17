import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wtg_front/models/promotion_type.dart';
import 'package:wtg_front/services/api_service.dart';

// --- Paleta de Cores Baseada no seu Design ---
const Color primaryAppColor = Color(0xFF6A00FF); // Roxo principal
const Color step2ActiveColor = Color(0xFF227093); // Azul para a etapa 2
const Color backgroundColor = Color(0xFFF8F8FA);
const Color textFieldBackgroundColor = Colors.white;
const Color placeholderColor = Color(0xFFE0E0E0);
const Color darkTextColor = Color(0xFF2D3748);

class CreatePromotionStep2Screen extends StatefulWidget {
  final Map<String, dynamic> promotionData;

  const CreatePromotionStep2Screen({super.key, required this.promotionData});

  @override
  State<CreatePromotionStep2Screen> createState() =>
      _CreatePromotionStep2ScreenState();
}

class _CreatePromotionStep2ScreenState
    extends State<CreatePromotionStep2Screen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  bool _isLoading = false;

  // Controladores para os campos de endereço
  final _cepController = TextEditingController();
  final _logradouroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _numeroController = TextEditingController();
  final _pontoReferenciaController = TextEditingController();
  final _observacoesController = TextEditingController();

  Map<String, double>? _confirmedCoordinates; // Para guardar as coordenadas

  @override
  void dispose() {
    _cepController.dispose();
    _logradouroController.dispose();
    _cidadeController.dispose();
    _numeroController.dispose();
    _pontoReferenciaController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  // Lógica de submissão final (adaptada da implementação anterior)
  Future<void> _submitFinalPromotion() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Simulação de confirmação de mapa para a funcionalidade
    // Em um caso real, você teria um botão para abrir um mapa e retornar as coordenadas
    _confirmedCoordinates = {
      'latitude': -8.0699,
      'longitude': -34.8792,
    };
    
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cookie = prefs.getString('session_cookie');
      if (cookie == null) throw Exception('Sessão expirada. Faça o login novamente.');

      final addressData = {
        "address": _logradouroController.text,
        "number": int.tryParse(_numeroController.text) ?? 0,
        "postalCode": _cepController.text,
        "reference": _pontoReferenciaController.text,
        "obs": _observacoesController.text,
        "complement": "", // Adicione um controller se precisar deste campo
      };

      final promotionData = {
        "title": widget.promotionData['title'],
        "description": widget.promotionData['description'],
        "obs": widget.promotionData['obs'],
        "promotionType": (widget.promotionData['promotionType'] as PromotionType).name.toUpperCase(),
        "active": true,
        "free": widget.promotionData['isFree'],
        "latitude": _confirmedCoordinates!['latitude'],
        "longitude": _confirmedCoordinates!['longitude'],
        "address": addressData,
      };
      
      final createResponse = await _apiService.createPromotion(promotionData, cookie);
      final newPromotionId = createResponse['id']?.toString();
      if (newPromotionId == null) throw Exception('Não foi possível obter o ID da promoção criada.');
      
      final List<File> images = widget.promotionData['images'];
      if (images.isNotEmpty) {
        await _apiService.uploadPromotionImages(newPromotionId, images, cookie);
      }
      
      await _apiService.completePromotionRegistration(newPromotionId, cookie);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seu rolê foi cadastrado com sucesso!')));
        // Volta 2 telas para sair do fluxo de criação
        int count = 0;
        Navigator.of(context).popUntil((_) => count++ >= 2);
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
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: darkTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'cadastre seu endereço',
          style: TextStyle(
            color: darkTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
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
                _buildBreadcrumbs(currentStep: 2),
                const SizedBox(height: 32),

                // Placeholder do Mapa
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      color: placeholderColor,
                      borderRadius: BorderRadius.circular(16),
                      image: const DecorationImage(
                        image: NetworkImage("https://maps.googleapis.com/maps/api/staticmap?center=-8.057838,-34.870639&zoom=15&size=600x300&maptype=roadmap&markers=color:red%7Clabel:P%7C-8.057838,-34.870639&key=YOUR_API_KEY"),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: const Icon(Icons.location_pin, color: Colors.red, size: 50),
                  ),
                ),
                const SizedBox(height: 32),

                _buildTextField(label: 'CEP', controller: _cepController, keyboardType: TextInputType.number),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _buildTextField(label: 'Logradouro', controller: _logradouroController)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField(label: 'Cidade', controller: _cidadeController)),
                  ],
                ),
                const SizedBox(height: 24),
                 Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildTextField(label: 'Ponto de referência', controller: _pontoReferenciaController)),
                    const SizedBox(width: 16),
                    SizedBox(width: 80, child: _buildTextField(label: 'Número', controller: _numeroController, keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 24),
                _buildTextField(label: 'Observações', controller: _observacoesController),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitFinalPromotion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryAppColor,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Continuar',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBreadcrumbs({required int currentStep}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepIndicator(step: 1, currentStep: currentStep, icon: Icons.storefront, activeColor: step2ActiveColor),
        _buildConnector(isComplete: currentStep > 1, color: step2ActiveColor),
        _buildStepIndicator(step: 2, currentStep: currentStep, icon: Icons.location_on_outlined, activeColor: step2ActiveColor),
        _buildConnector(isComplete: currentStep > 2, color: step2ActiveColor),
        _buildStepIndicator(step: 3, currentStep: currentStep, icon: Icons.check, activeColor: step2ActiveColor),
      ],
    );
  }

  Widget _buildStepIndicator({required int step, required int currentStep, required IconData icon, required Color activeColor}) {
    final bool isActive = step == currentStep;
    final bool isComplete = step < currentStep;
    final Color color = isActive || isComplete ? activeColor : Colors.grey[400]!;

    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(step.toString(), style: TextStyle(color: color, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildConnector({required bool isComplete, required Color color}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 28, left: 8, right: 8),
        color: isComplete ? color : Colors.grey[300],
      ),
    );
  }

  Widget _buildTextField({required String label, required TextEditingController controller, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: darkTextColor, fontSize: 16)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: (value) => (value == null || value.isEmpty) ? 'Campo obrigatório' : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: textFieldBackgroundColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: placeholderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: placeholderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: step2ActiveColor, width: 2)),
          ),
        ),
      ],
    );
  }
}