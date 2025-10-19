// lib/screens/registration/2_token_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wtg_front/screens/registration/3_password_screen.dart';
import 'package:wtg_front/services/api_service.dart';

// --- PALETA DE CORES PADRONIZADA ---
const Color darkBackgroundColor = Color(0xFF1A202C);
const Color primaryTextColor = Colors.white;
const Color secondaryTextColor = Color(0xFFA0AEC0);
const Color fieldBackgroundColor = Color(0xFF2D3748);
const Color fieldBorderColor = Color(0xFF4A5568);
const Color primaryButtonColor = Color(0xFFE53E3E);

// Cores dos ícones e etapas do Breadcrumb
const Color verificationStepColor = Color(0xFF4299E1);
const Color passwordStepColor = Color(0xFFF6AD55);
const Color infoStepColor = Color(0xFFF56565);

class TokenScreen extends StatefulWidget {
  final String email;
  final double? latitude;
  final double? longitude;

  const TokenScreen({
    super.key,
    required this.email,
    this.latitude,
    this.longitude,
  });

  @override
  State<TokenScreen> createState() => _TokenScreenState();
}

class _TokenScreenState extends State<TokenScreen> {
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
    _timerSeconds = 90;
    _timer?.cancel();
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
      await _apiService.initiateRegistration(widget.email);
      startTimer();
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Novo código enviado!')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao reenviar token: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _validateToken() async {
    final token = _controllers.map((c) => c.text).join();
    if (token.length < 4) return;

    setState(() => _isLoading = true);
    try {
      await _apiService.validateToken(widget.email, token);
      if (mounted) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => PasswordScreen(
            email: widget.email,
            latitude: widget.latitude,
            longitude: widget.longitude,
          ),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
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
            onPressed: () => Navigator.of(context).pop()),
        actions: [
          _buildBreadcrumbs(),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              const Text('Digite o código',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor)),
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: fieldBorderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: fieldBorderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: verificationStepColor, width: 2),
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
              _buildPrimaryButton(
                'Continuar',
                _validateToken,
                _isLoading,
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
  
  Widget _buildBreadcrumbs() {
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.4,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildStep(
              icon: Icons.mark_email_read_outlined,
              stepColor: verificationStepColor,
              isActive: true,
            ),
            _buildConnector(isComplete: false, color: passwordStepColor),
            _buildStep(
              icon: Icons.lock_open_outlined,
              stepColor: passwordStepColor,
            ),
            _buildConnector(isComplete: false, color: infoStepColor),
            _buildStep(
              icon: Icons.person_add_alt_1_outlined,
              stepColor: infoStepColor,
            ),
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
}

Widget _buildPrimaryButton(
    String text, VoidCallback onPressed, bool isLoading) {
  return ElevatedButton(
    onPressed: isLoading ? null : onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryButtonColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      minimumSize: const Size(double.infinity, 64),
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