// lib/screens/reset_password/reset_token_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wtg_front/screens/reset_password/reset_password_screen.dart';
import 'package:wtg_front/services/api_service.dart';

// --- CORES PADRONIZADAS (COPIADAS DE 2_token_screen.dart) ---
const Color primaryButtonColor = Color(0xFFd74533);
const Color messageTextColor = Color(0xFFec9724);
const Color darkTextColor = Color(0xFF002956);
const Color borderColor = Color(0xFFD1D5DB);

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

  // --- CORES DINÂMICAS PARA A BORDA (COPIADO DE 2_token_screen.dart) ---
  final List<Color> _borderColors = const [
    Color(0xFFee5253),
    Color(0xFF2e86de),
    Color(0xFFff9f43),
    Color(0xFF341f97),
  ];

  @override
  void initState() {
    super.initState();
    startTimer();
    // Adiciona listener para reconstruir a UI quando o foco mudar
    for (var node in _focusNodes) {
      node.addListener(() {
        setState(() {});
      });
    }
  }

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
    // Remove o listener para evitar memory leaks
    for (var focusNode in _focusNodes) {
      focusNode.removeListener(() {
        setState(() {});
      });
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String timerText =
        '${(_timerSeconds ~/ 60).toString().padLeft(2, '0')}:${(_timerSeconds % 60).toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: darkTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text('Digite o código de recuperação',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: darkTextColor,
                  )),
              const SizedBox(height: 8),
              // --- WIDGET DE TEXTO ATUALIZADO PARA RichText ---
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 12,
                    color: messageTextColor,
                  ),
                  children: [
                    const TextSpan(
                        text:
                            'Um código de recuperação foi enviado para o e-mail '),
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // --- INPUTS ATUALIZADOS COM ESTILO DINÂMICO ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (index) {
                  final bool isFocused = _focusNodes[index].hasFocus;
                  final Color focusedColor = _borderColors[index];

                  return SizedBox(
                    width: 60,
                    height: 60,
                    child: TextFormField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      decoration: InputDecoration(
                        counterText: '',
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: focusedColor, width: 2.0),
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
              Center(child: Text(timerText)),
              const SizedBox(height: 16),
              // --- BOTÃO ATUALIZADO ---
              ElevatedButton(
                onPressed: _isLoading ? null : _continue,
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryButtonColor,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Continuar',
                        style: TextStyle(
                            color: Colors.white,
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
                        color: _timerSeconds == 0
                            ? primaryButtonColor
                            : Colors.grey),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}