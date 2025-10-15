// lib/screens/registration/2_token_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wtg_front/screens/registration/3_password_screen.dart';
import 'package:wtg_front/services/api_service.dart';

// --- CORES ATUALIZADAS ---
const Color primaryButtonColor = Color(0xFFd74533);
const Color messageTextColor = Color(0xFFec9724);
const Color darkTextColor = Color(0xFF002956);
const Color borderColor = Color(0xFFD1D5DB);

// --- CORES DO BREADCRUMB ---
const Color verificationStepColor = Color(0xFF214886);
const Color passwordStepColor = Color(0xFF10ac84);
const Color infoStepColor = Color(0xFF1F73F8);

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
    for (var node in _focusNodes) {
      node.addListener(() {
        setState(() {});
      });
    }
  }

  void startTimer() {
    _timerSeconds = 90;
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
                onPressed: () => Navigator.of(context).pop())),
        body: SafeArea(
            child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBreadcrumbs(currentStep: 1),
                      const SizedBox(height: 32),
                      const Text('Digite o código de verificação',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: darkTextColor)),
                      const SizedBox(height: 8),
                      // --- WIDGET DE TEXTO ATUALIZADO ---
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 12,
                            color: messageTextColor, // Cor do texto
                          ),
                          children: [
                            const TextSpan(
                                text:
                                    'Um novo código de verificação foi enviado para o e-mail '),
                            TextSpan(
                              text: widget.email,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold, // Negrito
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
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
                                    borderSide:
                                        const BorderSide(color: borderColor)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: focusedColor, width: 2.0),
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
                        onPressed: _isLoading ? null : _validateToken,
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                primaryButtonColor, // Cor do botão
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
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
                    ]))));
  }
  
  Widget _buildBreadcrumbs({required int currentStep}) {
    return Row(
      children: [
        _buildStep(
          icon: Icons.mark_email_read_outlined,
          label: 'Verificação',
          stepColor: verificationStepColor,
          isComplete: currentStep > 1,
          isActive: currentStep == 1,
        ),
        _buildConnector(isComplete: currentStep > 1, color: passwordStepColor),
        _buildStep(
          icon: Icons.lock_outline,
          label: 'Senha',
          stepColor: passwordStepColor,
          isComplete: currentStep > 2,
          isActive: currentStep == 2,
        ),
        _buildConnector(isComplete: currentStep > 2, color: infoStepColor),
        _buildStep(
          icon: Icons.person_outline,
          label: 'Dados',
          stepColor: infoStepColor,
          isComplete: false, 
          isActive: currentStep == 3,
        ),
      ],
    );
  }

  Widget _buildStep({required IconData icon, required String label, required Color stepColor, required bool isActive, required bool isComplete}) {
    final color = isActive || isComplete ? stepColor : Colors.grey[400];
    
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isActive || isComplete ? stepColor : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: color!, width: 2),
          ),
          child: Icon(
            icon,
            color: isActive || isComplete ? Colors.white : Colors.grey[400],
            size: 22,
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: darkTextColor, fontSize: 12, fontWeight: isActive || isComplete ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildConnector({required bool isComplete, required Color color}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        color: isComplete ? color : Colors.grey[300],
      ),
    );
  }
}