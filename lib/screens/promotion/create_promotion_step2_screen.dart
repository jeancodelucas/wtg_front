// lib/screens/promotion/create_promotion_step2_screen.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:wtg_front/services/location_service.dart';
import 'create_promotion_step3_screen.dart';

// --- PALETA DE CORES (sem alterações) ---
const Color darkBackgroundColor = Color(0xFF1A202C);
const Color primaryTextColor = Colors.white;
const Color secondaryTextColor = Color(0xFFA0AEC0);
const Color fieldBackgroundColor = Color(0xFF2D3748);
const Color fieldBorderColor = Color(0xFF4A5568);
const Color primaryButtonColor = Color(0xFFE53E3E);
const Color step1Color = Color(0xFF218c74);
const Color step2Color = Color(0xFFF6AD55);
const Color accentColor = Color(0xFFF6AD55);
const Color step3Color = Color(0xFFF56565);

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
  final _locationService = LocationService();
  bool _isLoading = false;
  bool _isFetchingCep = false;

  final _cepController = TextEditingController();
  final _cepFocusNode = FocusNode();
  final _ufController = TextEditingController();
  final _logradouroController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _numeroController = TextEditingController();
  final _complementoController = TextEditingController();
  final _pontoReferenciaController = TextEditingController();
  final _observacoesController = TextEditingController();
  final _numeroFocusNode = FocusNode();

  GoogleMapController? _mapController;
  LatLng? _currentLatLng;
  final Set<Marker> _markers = {};
  bool _mapIsLoading = true;

  bool get _isEditing => widget.promotionData['promotion'] != null;

  @override
  void initState() {
    super.initState();
    _cepFocusNode.addListener(() {
      if (!_cepFocusNode.hasFocus) {
        _fetchAddressFromCep();
      }
    });

    if (_isEditing) {
      _loadDataForEditing();
    } else {
      _fetchCurrentUserLocation();
    }
  }

  void _loadDataForEditing() {
    final Map<String, dynamic> promo = widget.promotionData['promotion'];
    final Map<String, dynamic>? address = promo['address'];

    if (address != null) {
      _cepController.text = address['postalCode'] ?? '';
      _ufController.text = address['state'] ?? '';
      _logradouroController.text = address['address'] ?? '';
      _neighborhoodController.text = address['neighborhood'] ?? '';
      _cidadeController.text = address['city'] ?? '';
      _numeroController.text = address['number']?.toString() ?? '';
      _complementoController.text = address['complement'] ?? '';
      _pontoReferenciaController.text = address['reference'] ?? '';
    }

    final lat = promo['latitude'] as double?;
    final lon = promo['longitude'] as double?;
    if (lat != null && lon != null) {
      _updateMapLocation(LatLng(lat, lon));
    } else {
      _fetchCurrentUserLocation();
    }
    setState(() => _mapIsLoading = false);
  }

  @override
  void dispose() {
    _cepController.dispose();
    _cepFocusNode.dispose();
    _ufController.dispose();
    _logradouroController.dispose();
    _neighborhoodController.dispose();
    _cidadeController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    _pontoReferenciaController.dispose();
    _observacoesController.dispose();
    _numeroFocusNode.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentUserLocation() async {
    setState(() => _mapIsLoading = true);
    final position = await _locationService.getCurrentPosition();
    if (position != null) {
      _updateMapLocation(LatLng(position.latitude, position.longitude));
    } else {
      _updateMapLocation(const LatLng(-8.057838, -34.870639));
    }
    setState(() => _mapIsLoading = false);
  }

  Future<void> _fetchAddressFromCep() async {
    final cep = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cep.length != 8) return;

    setState(() => _isFetchingCep = true);
    try {
      final uri = Uri.parse('https://viacep.com.br/ws/$cep/json/');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['erro'] == true) throw Exception('CEP não encontrado.');

        setState(() {
          _logradouroController.text = data['logradouro'] ?? '';
          _neighborhoodController.text = data['bairro'] ?? '';
          _cidadeController.text = data['localidade'] ?? '';
          _ufController.text = data['uf'] ?? '';
        });

        FocusScope.of(context).requestFocus(_numeroFocusNode);
        await _geocodeAndCenterMap();
      } else {
        throw Exception('Não foi possível buscar o CEP.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))));
      }
    } finally {
      if (mounted) setState(() => _isFetchingCep = false);
    }
  }

  Future<void> _geocodeAndCenterMap() async {
    try {
      final String fullAddress =
          '${_logradouroController.text}, ${_cidadeController.text}, ${_ufController.text}';
      final locations = await locationFromAddress(fullAddress);
      if (locations.isNotEmpty) {
        final newLatLng =
            LatLng(locations.first.latitude, locations.first.longitude);
        _updateMapLocation(newLatLng);
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(newLatLng, 16),
        );
      }
    } catch (e) {
      print("Erro no geocoding: $e");
    }
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

  void _continueToNextStep() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Aguarde o mapa carregar ou confirme a localização.')));
      return;
    }

    final fullPromotionData = {
      ...widget.promotionData, // Isso já inclui 'removedImages' da tela anterior
      'addressData': {
        "address": _logradouroController.text,
        "number": _numeroController.text,
        "complement": _complementoController.text,
        "neighborhood": _neighborhoodController.text,
        "city": _cidadeController.text,
        "state": _ufController.text,
        "postalCode": _cepController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        "reference": _pontoReferenciaController.text,
        "obs": _observacoesController.text,
      },
      'coordinates': _currentLatLng,
    };

    final result = await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => CreatePromotionStep3Screen(
        promotionData: fullPromotionData,
        loginResponse: widget.promotionData['loginResponse'],
      ),
    ));

    if (result == true) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... O resto do build method permanece o mesmo
    return Scaffold(
      backgroundColor: darkBackgroundColor,
      appBar: AppBar(
        backgroundColor: darkBackgroundColor,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: secondaryTextColor),
            onPressed: () => Navigator.of(context).pop()),
        title: const Text('Endereço do Rolê',
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
                _buildSectionTitle("Localização no Mapa",
                    "Arraste o marcador para ajustar a posição exata do seu evento."),
                _buildInteractiveMap(),
                const SizedBox(height: 32),
                _buildSectionTitle(
                    "Detalhes do Endereço", "Preencha os campos abaixo."),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        flex: 3,
                        child: _buildTextField(
                          label: 'CEP *',
                          controller: _cepController,
                          keyboardType: TextInputType.number,
                          focusNode: _cepFocusNode,
                          icon: Icons.local_post_office_outlined,
                          hint: '00000-000',
                          validator: (v) =>
                              v!.isEmpty ? 'Obrigatório' : null,
                          suffixIcon: _isFetchingCep
                              ? const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: accentColor)))
                              : null,
                        )),
                    const SizedBox(width: 16),
                    Expanded(
                        flex: 2,
                        child: _buildTextField(
                            label: 'UF *',
                            controller: _ufController,
                            icon: Icons.public_outlined,
                            hint: 'PE',
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(2)
                            ],
                            validator: (v) =>
                                v!.isEmpty ? 'Obrigatório' : null)),
                  ],
                ),
                const SizedBox(height: 24),
                _buildTextField(
                    label: 'Logradouro *',
                    controller: _logradouroController,
                    icon: Icons.location_on_outlined,
                    hint: 'Ex: Av. Boa Viagem',
                    validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
                const SizedBox(height: 24),
                _buildTextField(
                    label: 'Bairro *',
                    controller: _neighborhoodController,
                    icon: Icons.holiday_village_outlined,
                    hint: 'Ex: Boa Viagem',
                    validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                        width: 100,
                        child: _buildTextField(
                            label: 'Número *',
                            controller: _numeroController,
                            focusNode: _numeroFocusNode,
                            icon: Icons.pin,
                            hint: '123',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(5)
                            ],
                            validator: (v) =>
                                v!.isEmpty ? 'Obrigatório' : null)),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _buildTextField(
                            label: 'Cidade *',
                            controller: _cidadeController,
                            icon: Icons.location_city_outlined,
                            hint: 'Recife',
                            validator: (v) =>
                                v!.isEmpty ? 'Obrigatório' : null)),
                  ],
                ),
                const SizedBox(height: 24),
                _buildTextField(
                    label: 'Complemento',
                    controller: _complementoController,
                    icon: Icons.add_road_outlined,
                    hint: 'Ex: Apto 101',
                    isOptional: true),
                const SizedBox(height: 24),
                _buildTextField(
                    label: 'Ponto de referência',
                    controller: _pontoReferenciaController,
                    icon: Icons.assistant_photo_outlined,
                    hint: 'Ex: Próximo à padaria',
                    isOptional: true),
                const SizedBox(height: 24),
                _buildTextField(
                    label: 'Observações',
                    controller: _observacoesController,
                    icon: Icons.speaker_notes_outlined,
                    hint: 'Ex: Entrada pelo portão lateral',
                    isOptional: true,
                    maxLines: 3),
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

  Widget _buildInteractiveMap() {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
              color: fieldBackgroundColor,
              borderRadius: BorderRadius.circular(16)),
          child: _mapIsLoading
              ? const Center(
                  child: CircularProgressIndicator(color: accentColor))
              : _currentLatLng == null
                  ? const Center(
                      child: Text('Não foi possível obter a localização.',
                          style: TextStyle(color: secondaryTextColor)))
                  : GoogleMap(
                      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                        Factory<EagerGestureRecognizer>(
                            () => EagerGestureRecognizer()),
                      },
                      mapType: MapType.normal,
                      initialCameraPosition:
                          CameraPosition(target: _currentLatLng!, zoom: 16),
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
  
  Widget _buildBreadcrumbs() {
  return Align(
    alignment: Alignment.centerRight,
    child: SizedBox(
      width: MediaQuery.of(context).size.width * 0.4,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildStep(
              icon: Icons.storefront,
              stepColor: step1Color,
              isComplete: true),
          _buildConnector(isComplete: true, color: accentColor),
          _buildStep(
              icon: Icons.location_on_outlined,
              stepColor: accentColor,
              isActive: true),
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

  Widget _buildTextField(
      {required String label,
      required TextEditingController controller,
      required IconData icon,
      String? hint,
      TextInputType? keyboardType,
      List<TextInputFormatter>? inputFormatters,
      FocusNode? focusNode,
      bool isOptional = false,
      int maxLines = 1,
      String? Function(String?)? validator,
      Widget? suffixIcon}) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      style: const TextStyle(color: primaryTextColor),
      validator: validator ??
          (value) {
            if (!isOptional && (value == null || value.isEmpty)) {
              return 'Campo obrigatório';
            }
            return null;
          },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: fieldBorderColor),
        labelStyle: const TextStyle(color: secondaryTextColor),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: Icon(icon, color: accentColor, size: 20),
        suffixIcon: suffixIcon,
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