import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wtg_front/models/promotion_type.dart';
import 'package:wtg_front/screens/home_screen.dart';
import 'package:wtg_front/services/api_service.dart';

// --- Paleta de Cores ---
const Color primaryAppColor = Color(0xFF6A00FF);
const Color backgroundColor = Color(0xFFF8F8FA);
const Color darkTextColor = Color(0xFF2D3748);
const Color lightTextColor = Color(0xFF718096);

class CreatePromotionStep3Screen extends StatefulWidget {
  final Map<String, dynamic> promotionData;
  final Map<String, dynamic> loginResponse;

  const CreatePromotionStep3Screen({
    super.key,
    required this.promotionData,
    required this.loginResponse,
  });

  @override
  State<CreatePromotionStep3Screen> createState() =>
      _CreatePromotionStep3ScreenState();
}

class _CreatePromotionStep3ScreenState
    extends State<CreatePromotionStep3Screen> {
  final _apiService = ApiService();
  bool _isLoading = false;
  bool _isVisible = true; // O switch começa ligado

Future<void> _submitFinalPromotion() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cookie = prefs.getString('session_cookie');
      if (cookie == null) throw Exception('Sessão expirada. Faça o login novamente.');

      final LatLng coordinates = widget.promotionData['coordinates'];
      final Map<String, dynamic> addressData = widget.promotionData['addressData'];
      final bool isFree = widget.promotionData['free'] as bool;

      final Map<String, dynamic> promotionDataPayload = {
        "title": widget.promotionData['title'],
        "description": widget.promotionData['description'],
        "obs": widget.promotionData['obs'],
        "promotionType": (widget.promotionData['promotionType'] as String).toUpperCase(),
        "active": _isVisible,
        "completeRegistration": false, // Será completado no passo seguinte
        "address": addressData,
        "free": isFree,
        
        // --- CORREÇÃO ADICIONADA AQUI ---
        "latitude": coordinates.latitude,
        "longitude": coordinates.longitude,
        // --- FIM DA CORREÇÃO ---
      };

      if (!isFree) {
        final String? ticketValueString = widget.promotionData['ticketValue'];
        final double? ticketValue = ticketValueString != null ? double.tryParse(ticketValueString) : null;
        
        if (ticketValue == null || ticketValue <= 0) {
          throw Exception('Valor do ingresso é inválido para uma promoção paga.');
        }
        promotionDataPayload['ticketValue'] = ticketValue;
      }
      
      final createResponse = await _apiService.createPromotion(promotionDataPayload, cookie);
      final newPromotionId = createResponse['id']?.toString();
      if (newPromotionId == null) throw Exception('Não foi possível obter o ID da promoção criada.');
      
      final List<File> images = widget.promotionData['images'];
      if (images.isNotEmpty) await _apiService.uploadPromotionImages(newPromotionId, images, cookie);
      
      await _apiService.completePromotionRegistration(newPromotionId, cookie);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seu rolê foi cadastrado com sucesso!')));
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => HomeScreen(loginResponse: widget.loginResponse),
          ),
          (route) => false
        );
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
        automaticallyImplyLeading: false, // Remove o botão de voltar padrão
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  const SizedBox(height: 40),
                  const Text('🎉', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 24),
                  const Text(
                    'Seu rolê foi cadastrado\ncom sucesso',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: darkTextColor,
                    ),
                  ),
                ],
              ),
              
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: -5,
                      blurRadius: 20,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          child: Text(
                            'Deseja tornar seu rolê visível para todos?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: darkTextColor,
                            ),
                          ),
                        ),
                        Switch(
                          value: _isVisible,
                          onChanged: (value) {
                            setState(() {
                              _isVisible = value;
                            });
                          },
                          activeColor: primaryAppColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'A partir do momento que o evento fica visível, dentro do plano normal, você só poderá ter controle dessa visibilidade durante 24hrs, após isso só será possível controlar novamente a visibilidade do seu evento daqui a 7 dias e apenas durante 24hrs. Para que você possa ter controle total de visibilidade do seu evento adquira o plano mensal!',
                      style: TextStyle(
                        fontSize: 14,
                        color: lightTextColor,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitFinalPromotion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAppColor,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Finalizar',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}