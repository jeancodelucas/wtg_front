// lib/screens/registration_success_screen.dart

import 'package:flutter/material.dart';

// Asumindo que as cores primárias do seu app são estas
const Color primaryColor = Color(0xFF214886);
const Color darkTextColor = Color(0xFF1F2937);

class RegistrationSuccessScreen extends StatelessWidget {
  const RegistrationSuccessScreen({super.key});

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
              // Imagem de celebração
              Image.asset(
                'assets/images/Celebration.png',
                height: MediaQuery.of(context).size.height * 0.3,
              ),
              const SizedBox(height: 40),
              // Textos
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
              // Botões
              _buildPrimaryButton(
                text: 'Cadastrar evento',
                onPressed: () {
                  // TODO: Adicionar navegação para a tela de cadastro de eventos
                },
              ),
              const SizedBox(height: 16),
              _buildSecondaryButton(
                text: 'Ir para a Home',
                onPressed: () {
                  // TODO: Adicionar navegação para a tela Home
                  // Ex: Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (c) => HomeScreen()), (route) => false);
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

// Recriando a constante de cor que pode não estar neste escopo
const Color lightTextColor = Color(0xFF6B7280);