// lib/screens/reset_password/reset_token_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wtg_front/screens/reset_password/reset_password_screen.dart';
import 'package:wtg_front/services/api_service.dart';

// --- PALETA DE CORES PADRONIZADA ---
const Color darkBackgroundColor = Color(0xFF1A202C);
const Color primaryTextColor = Colors.white;
const Color secondaryTextColor = Color(0xFFA0AEC0);
const Color fieldBackgroundColor = Color(0xFF2D3748);
const Color fieldBorderColor = Color(0xFF4A5568);
const Color primaryButtonColor = Color(0xFFE53E3E);
const Color accentColor = Color(0xFF4299E1); // Azul para destaque nos inputs

class ResetTokenScreen extends StatefulWidget {
  final String email;

  const ResetTokenScreen({super.key, required this.email});

  @override
  State<ResetTokenScreen> createState() => _ResetTokenScreenState();
}

class _ResetTokenScreenState extends State<ResetTokenScreen> {
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final _apiService = ApiService();

  bool _isLoading = false;
  int _timerSeconds = 90;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    startTimer();
    for (var node in _focusNodes) {
      node.addListener(() {
        setState(() {});
      });
    }
  }

  // --- NENHUMA ALTERAÇÃO NA LÓGICA ABAIXO ---

  void startTimer() {
    setState(() {
      _timerSeconds = 90;
      _timer?.cancel();
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        setState(() => _timerSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _resendToken() async {
    if (_timerSeconds > 0) return;
    setState(() => _isLoading = true);
    try {
      await _apiService.forgotPassword(widget.email);
      startTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Um novo código foi enviado!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao reenviar código: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _continue() {
    final token = _controllers.map((c) => c.text).join();
    if (token.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor, preencha os 4 dígitos do código.')),
      );
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) =>
          ResetPasswordScreen(email: widget.email, token: token),
    ));
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.removeListener(() {
        setState(() {});
      });
      focusNode.dispose();
    }
    super.dispose();
  }

  // --- BUILD METHOD E WIDGETS DE UI ATUALIZADOS ---

  @override
  Widget build(BuildContext context) {
    String timerText =
        '${(_timerSeconds ~/ 60).toString().padLeft(2, '0')}:${(_timerSeconds % 60).toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: darkBackgroundColor,
      appBar: AppBar(
        backgroundColor: darkBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: secondaryTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              const Text('Código de recuperação',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  )),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  style:
                      const TextStyle(fontSize: 16, color: secondaryTextColor),
                  children: [
                    const TextSpan(text: 'Enviamos um código para o e-mail\n'),
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: primaryTextColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (index) {
                  return SizedBox(
                    width: 64,
                    height: 64,
                    child: TextFormField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: fieldBackgroundColor,
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: fieldBorderColor)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: accentColor, width: 2.0),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 3) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              Center(
                  child: Text(
                timerText,
                style: const TextStyle(
                    color: secondaryTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              )),
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoading ? null : _continue,
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryButtonColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 64),
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 3))
                    : const Text('Continuar',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _timerSeconds == 0 ? _resendToken : null,
                  child: Text(
                    'Reenviar código',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _timerSeconds == 0
                            ? primaryButtonColor
                            : secondaryTextColor.withOpacity(0.5)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}