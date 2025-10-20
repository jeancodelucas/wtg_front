// lib/screens/registration_success_screen.dart

import 'package:flutter/material.dart';
import 'package:wtg_front/screens/promotion/create_promotion_step1_screen.dart';
import 'package:wtg_front/screens/main_screen.dart';


// --- PALETA DE CORES PADRONIZADA (dark mode) ---
const Color darkBackgroundColor = Color(0xFF1A202C);
const Color primaryTextColor = Colors.white;
const Color secondaryTextColor = Color(0xFFA0AEC0);
const Color primaryButtonColor = Color(0xFFE53E3E);
const Color accentColor = Color(0xFF218c74); // Verde para destaque, como no Step 1

class RegistrationSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const RegistrationSuccessScreen({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              // Ícone de celebração alinhado com o novo design
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withOpacity(0.1),
                ),
                child: const Icon(
                  Icons.celebration_outlined,
                  color: accentColor,
                  size: 80,
                ),
              ),
              const SizedBox(height: 40),
              // Textos com a nova tipografia e cores
              const Text(
                'Bora descobrir uns rolês?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Parabéns! Tá tudo certo, agora só achar os melhores rolês ou criar um e divulgar por aqui.\nE aí, bora começar?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: secondaryTextColor,
                  height: 1.5,
                ),
              ),
              const Spacer(flex: 3),
              // Botões padronizados
              _buildPrimaryButton(
                text: 'Cadastrar um Rolê',
                onPressed: () {
                  // Funcionalidade original mantida
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CreatePromotionStep1Screen(loginResponse: userData),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildSecondaryButton(
                text: 'Ir para a Home',
                onPressed: () {
                  // Funcionalidade original mantida
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => MainScreen(loginResponse: userData),
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

  // Widget para o botão primário, seguindo o padrão de create_promotion_screens
  Widget _buildPrimaryButton({required String text, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryButtonColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        shadowColor: primaryButtonColor.withOpacity(0.4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Widget para o botão secundário (Outlined), com o novo padrão visual
  Widget _buildSecondaryButton({required String text, required VoidCallback onPressed}) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryTextColor,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(double.infinity, 56),
        side: const BorderSide(color: Color(0xFF4A5568), width: 2), // Cor da borda dos campos
      ),
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}