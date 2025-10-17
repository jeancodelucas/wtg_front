import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wtg_front/models/promotion_type.dart';
import 'package:wtg_front/services/api_service.dart';
import 'package:wtg_front/services/location_service.dart';

// --- Paleta de Cores ---
const Color primaryAppColor = Color(0xFF6A00FF);
const Color step2ActiveColor = Color(0xFF227093);
const Color backgroundColor = Color(0xFFF8F8FA);
const Color textFieldBackgroundColor = Colors.white;
const Color placeholderColor = Color(0xFFE0E0E0);
const Color darkTextColor = Color(0xFF2D3748);

class CreatePromotionStep2Screen extends StatefulWidget {
  final Map<String, dynamic> promotionData;
  const CreatePromotionStep2Screen({super.key, required this.promotionData});

  @override
  State<CreatePromotionStep2Screen> createState() => _CreatePromotionStep2ScreenState();
}

class _CreatePromotionStep2ScreenState extends State<CreatePromotionStep2Screen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _locationService = LocationService();
  bool _isLoading = false;

  // Controladores e FocusNode para o CEP
  final _cepController = TextEditingController();
  final _cepFocusNode = FocusNode();
  final _ufController = TextEditingController();
  final _logradouroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _numeroController = TextEditingController();
  final _pontoReferenciaController = TextEditingController();
  final _observacoesController = TextEditingController();

  // Variáveis de estado para o mapa
  GoogleMapController? _mapController;
  LatLng? _currentLatLng;
  final Set<Marker> _markers = {};
  bool _mapIsLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserLocation();
    // Adiciona o listener para o foco do CEP
    _cepFocusNode.addListener(() {
      if (!_cepFocusNode.hasFocus) {
        _fetchAddressFromCep();
      }
    });
  }

  @override
  void dispose() {
    _cepController.dispose();
    _cepFocusNode.dispose();
    _ufController.dispose();
    _logradouroController.dispose();
    _cidadeController.dispose();
    _numeroController.dispose();
    _pontoReferenciaController.dispose();
    _observacoesController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentUserLocation() async {
    setState(() => _mapIsLoading = true);
    final position = await _locationService.getCurrentPosition();
    if (position != null) {
      _updateMapLocation(LatLng(position.latitude, position.longitude));
    }
    setState(() => _mapIsLoading = false);
  }

  Future<void> _fetchAddressFromCep() async {
    FocusScope.of(context).unfocus();
    final cep = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cep.length != 8) return;

    setState(() => _isLoading = true);
    try {
      final uri = Uri.parse('https://viacep.com.br/ws/$cep/json/');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['erro'] == true) throw Exception('CEP não encontrado.');
        
        _logradouroController.text = data['logradouro'] ?? '';
        _cidadeController.text = data['localidade'] ?? '';
        _ufController.text = data['uf'] ?? '';
        await _geocodeAndCenterMap();
      } else {
        throw Exception('Não foi possível buscar o CEP.');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Future<void> _geocodeAndCenterMap() async {
    try {
      final String fullAddress = '${_logradouroController.text}, ${_cidadeController.text}, ${_ufController.text}';
      final locations = await locationFromAddress(fullAddress);
      if (locations.isNotEmpty) {
        _updateMapLocation(LatLng(locations.first.latitude, locations.first.longitude));
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(locations.first.latitude, locations.first.longitude), 16),
        );
      }
    } catch (e) { /* Ignora erro */ }
  }

  void _updateMapLocation(LatLng latLng) {
    setState(() {
      _currentLatLng = latLng;
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: latLng,
          draggable: true,
          onDragEnd: (newPosition) {
            setState(() {
              _currentLatLng = newPosition;
            });
          },
        ),
      );
    });
  }

  Future<void> _submitFinalPromotion() async {
    if (!_formKey.currentState!.validate() || _currentLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, preencha todos os campos e confirme a localização.')));
      return;
    }
    
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cookie = prefs.getString('session_cookie');
      if (cookie == null) throw Exception('Sessão expirada. Faça o login novamente.');

      final addressData = {
        "address": _logradouroController.text, "number": int.tryParse(_numeroController.text) ?? 0,
        "postalCode": _cepController.text.replaceAll(RegExp(r'[^0-9]'), ''), "reference": _pontoReferenciaController.text,
        "obs": _observacoesController.text, "complement": "", 
      };

      final promotionData = {
        "title": widget.promotionData['title'], "description": widget.promotionData['description'],
        "obs": widget.promotionData['obs'], "promotionType": (widget.promotionData['promotionType'] as PromotionType).name.toUpperCase(),
        "active": true, "free": widget.promotionData['isFree'],
        "latitude": _currentLatLng!.latitude, "longitude": _currentLatLng!.longitude,
        "address": addressData,
      };
      
      final createResponse = await _apiService.createPromotion(promotionData, cookie);
      final newPromotionId = createResponse['id']?.toString();
      if (newPromotionId == null) throw Exception('Não foi possível obter o ID da promoção criada.');
      
      final List<File> images = widget.promotionData['images'];
      if (images.isNotEmpty) await _apiService.uploadPromotionImages(newPromotionId, images, cookie);
      
      await _apiService.completePromotionRegistration(newPromotionId, cookie);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seu rolê foi cadastrado com sucesso!')));
        int count = 0;
        Navigator.of(context).popUntil((_) => count++ >= 2);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao cadastrar: ${e.toString().replaceAll("Exception: ", "")}')));
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
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: darkTextColor), onPressed: () => Navigator.of(context).pop()),
        title: const Text('cadastre seu endereço', style: TextStyle(color: darkTextColor, fontWeight: FontWeight.bold, fontSize: 22)),
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
                _buildInteractiveMap(),
                const SizedBox(height: 32),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildTextField(label: 'CEP', controller: _cepController, keyboardType: TextInputType.number, focusNode: _cepFocusNode)),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: _buildTextField(label: 'UF', controller: _ufController, inputFormatters: [LengthLimitingTextInputFormatter(2)])),
                  ],
                ),
                const SizedBox(height: 24),
                _buildTextField(label: 'Logradouro', controller: _logradouroController),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 100, child: _buildTextField(label: 'Número', controller: _numeroController, keyboardType: TextInputType.number, inputFormatters: [LengthLimitingTextInputFormatter(4)])),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField(label: 'Cidade', controller: _cidadeController)),
                  ],
                ),
                const SizedBox(height: 24),
                _buildTextField(label: 'Ponto de referência', controller: _pontoReferenciaController),
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
                      : const Text('Continuar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildInteractiveMap() {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(color: placeholderColor, borderRadius: BorderRadius.circular(16)),
          child: _mapIsLoading
              ? const Center(child: CircularProgressIndicator(color: step2ActiveColor))
              : _currentLatLng == null
                  ? const Center(child: Text('Não foi possível obter a localização.'))
                  : GoogleMap(
                      mapType: MapType.normal,
                      initialCameraPosition: CameraPosition(target: _currentLatLng!, zoom: 16),
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                      },
                      markers: _markers,
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
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

  Widget _buildTextField({required String label, required TextEditingController controller, TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters, FocusNode? focusNode}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: darkTextColor, fontSize: 16)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
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