// lib/screens/promotion/create_promotion_step3_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wtg_front/screens/home_screen.dart';
import 'package:wtg_front/services/api_service.dart';

// --- PALETA DE CORES PADRONIZADA ---
const Color darkBackgroundColor = Color(0xFF1A202C);
const Color primaryTextColor = Colors.white;
const Color secondaryTextColor = Color(0xFFA0AEC0);
const Color fieldBackgroundColor = Color(0xFF2D3748);
const Color fieldBorderColor = Color(0xFF4A5568);
const Color primaryButtonColor = Color(0xFFE53E3E);

// Cores do Breadcrumb
const Color step1Color = Color(0xFF218c74); // Verde
const Color step2Color = Color(0xFFF6AD55); // Laranja
const Color accentColor = Color(0xFFF56565); // Vermelho para a etapa 3

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
  bool _isVisible = true;

  // --- NENHUMA ALTERAÇÃO NA LÓGICA ABAIXO ---
  Future<void> _submitFinalPromotion() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cookie = prefs.getString('session_cookie');
      if (cookie == null)
        throw Exception('Sessão expirada. Faça o login novamente.');

      final LatLng coordinates = widget.promotionData['coordinates'];
      final Map<String, dynamic> addressData =
          widget.promotionData['addressData'];
      final bool isFree = widget.promotionData['free'] as bool;

      final Map<String, dynamic> promotionDataPayload = {
        "title": widget.promotionData['title'],
        "description": widget.promotionData['description'],
        "obs": widget.promotionData['obs'],
        "promotionType":
            (widget.promotionData['promotionType'] as String).toUpperCase(),
        "active": _isVisible,
        "completeRegistration": false,
        "address": addressData,
        "free": isFree,
        "latitude": coordinates.latitude,
        "longitude": coordinates.longitude,
      };

      if (!isFree) {
        final String? ticketValueString = widget.promotionData['ticketValue'];
        final double? ticketValue =
            ticketValueString != null ? double.tryParse(ticketValueString) : null;

        if (ticketValue == null || ticketValue <= 0) {
          throw Exception('Valor do ingresso é inválido para uma promoção paga.');
        }
        promotionDataPayload['ticketValue'] = ticketValue;
      }

      final createResponse =
          await _apiService.createPromotion(promotionDataPayload, cookie);
      final newPromotionId = createResponse['id']?.toString();
      if (newPromotionId == null)
        throw Exception('Não foi possível obter o ID da promoção criada.');

      // --- LINHA DE CÓDIGO RESTAURADA ---
      final List<File> images = widget.promotionData['images'];
      if (images.isNotEmpty) {
        await _apiService.uploadPromotionImages(newPromotionId, images, cookie);
      }
      
      await _apiService.completePromotionRegistration(newPromotionId, cookie);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Seu rolê foi cadastrado com sucesso!')));
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => HomeScreen(loginResponse: widget.loginResponse),
          ),
          (route) => false,
        );
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
      backgroundColor: darkBackgroundColor,
      appBar: AppBar(
        backgroundColor: darkBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          _buildBreadcrumbs(),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withOpacity(0.1),
                ),
                child: const Icon(Icons.celebration_outlined,
                    color: accentColor, size: 64),
              ),
              const SizedBox(height: 24),
              const Text(
                'Seu rolê foi cadastrado\ncom sucesso!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
              const Spacer(flex: 3),
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: fieldBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
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
                              color: primaryTextColor,
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
                          activeColor: accentColor,
                          trackOutlineColor:
                              MaterialStateProperty.all(fieldBorderColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'A partir do momento que o evento fica visível, dentro do plano normal, você só poderá ter controle dessa visibilidade durante 24hrs, após isso só será possível controlar novamente a visibilidade do seu evento daqui a 7 dias e apenas durante 24hrs. Para que você possa ter controle total de visibilidade do seu evento adquira o plano mensal!',
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryTextColor,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildPrimaryButton(
                        'Finalizar', _submitFinalPromotion, _isLoading),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreadcrumbs() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.4,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildStep(
              icon: Icons.storefront, stepColor: step1Color, isComplete: true),
          _buildConnector(isComplete: true, color: step2Color),
          _buildStep(
              icon: Icons.location_on_outlined,
              stepColor: step2Color,
              isComplete: true),
          _buildConnector(isComplete: true, color: accentColor),
          _buildStep(icon: Icons.check, stepColor: accentColor, isActive: true),
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