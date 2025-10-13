// lib/screens/registration/1_email_screen.dart

import 'package:flutter/material.dart';
import 'package:wtg_front/screens/registration/2_token_screen.dart';
import 'package:wtg_front/services/api_service.dart';

// Constantes de cor para manter a consistência do design
const Color primaryColor = Color(0xFF214886);
const Color darkTextColor = Color(0xFF1F2937);
const Color lightTextColor = Color(0xFF6B7280);
const Color togglerBackgroundColor = Color(0xFFF3F4F6); // Um cinza mais claro
const Color borderColor = Color(0xFFD1D5DB);

class EmailScreen extends StatefulWidget {
  const EmailScreen({super.key});

  @override
  State<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      await _apiService.initiateRegistration(_emailController.text);
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TokenScreen(email: _emailController.text),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${e.toString().replaceAll("Exception: ", "")} Volte para a tela de login para continuar.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset('assets/images/LaRuaLogo.png', height: 140),
                  const SizedBox(height: 16),
                  Image.asset('assets/images/LaRuaNameLogo.png', height: 40),
                  const SizedBox(height: 40),
                  _buildToggler(),
                  const SizedBox(height: 32),
                  const Text(
                    'Digite seu e-mail',
                    style: TextStyle(
                      color: darkTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira um e-mail.';
                      }
                      final emailRegex =
                          RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(value)) {
                        return 'Por favor, insira um e-mail válido.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildPrimaryButton('Continuar', _submitEmail),
                  const SizedBox(height: 32),
                  _buildDivider(),
                  const SizedBox(height: 32),
                  _buildSocialLoginRow(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggler() {
    return Container(
      decoration: BoxDecoration(
        color: togglerBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Botão "Entrar" (inativo)
          Expanded(
            child: GestureDetector(
              onTap: () {
                // Ao clicar em "Entrar", simplesmente volta para a tela anterior
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Entrar',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: lightTextColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Botão "Cadastre-se" (ativo)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                  )
                ],
              ),
              child: const Center(
                child: Text(
                  'Cadastre-se',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: darkTextColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        minimumSize: const Size(double.infinity, 50),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continuar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward),
              ],
            ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: borderColor)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('Ou', style: TextStyle(color: lightTextColor)),
        ),
        Expanded(child: Divider(color: borderColor)),
      ],
    );
  }

  Widget _buildSocialLoginRow() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Implementar lógica de login com Google
            },
            icon: Image.asset('assets/images/google_logo.png', height: 24),
            label: const Text(''),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: const BorderSide(color: borderColor),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Implementar lógica de login com Apple
            },
            icon: const Icon(Icons.apple, color: Colors.black, size: 28),
            label: const Text(''),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: const BorderSide(color: borderColor),
            ),
          ),
        ),
      ],
    );
  }
}