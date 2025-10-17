// lib/screens/registration_success_screen.dart

import 'package:flutter/material.dart';
import 'package:wtg_front/screens/home_screen.dart';
import 'package:wtg_front/screens/promotion/create_promotion_step1_screen.dart'; // 1. Importe a nova tela

// Cores primárias do seu app
const Color primaryColor = Color(0xFF214886);
const Color darkTextColor = Color(0xFF1F2937);
const Color lightTextColor = Color(0xFF6B7280);

class RegistrationSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const RegistrationSuccessScreen({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Image.asset(
                'assets/images/Celebration.png',
                height: MediaQuery.of(context).size.height * 0.3,
              ),
              const SizedBox(height: 40),
              const Text(
                'Bora descobrir uns eventos?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: darkTextColor,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Parabéns! Tá tudo certo, agora só achar os melhores rolê ou criar um e divulgar por aqui. \nE aí, bora começar?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: lightTextColor,
                  height: 1.5,
                ),
              ),
              const Spacer(flex: 3),
              _buildPrimaryButton(
                text: 'Cadastrar evento',
                onPressed: () {
                  // --- 2. CORREÇÃO APLICADA AQUI ---
                  // Navega para a primeira etapa do cadastro de promoção
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CreatePromotionStep1Screen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildSecondaryButton(
                text: 'Ir para a Home',
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => HomeScreen(loginResponse: userData),
                    ),
                    (route) => false,
                  );
                },
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({required String text, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(double.infinity, 50),
        elevation: 0,
      ),
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSecondaryButton({required String text, required VoidCallback onPressed}) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(double.infinity, 50),
        side: const BorderSide(color: primaryColor, width: 2),
      ),
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}