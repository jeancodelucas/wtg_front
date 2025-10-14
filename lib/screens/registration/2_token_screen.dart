// lib/screens/registration/2_token_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wtg_front/screens/registration/3_password_screen.dart';
import 'package:wtg_front/services/api_service.dart';

const Color primaryColor = Color(0xFF214886);
const Color darkTextColor = Color(0xFF1F2937);
const Color borderColor = Color(0xFFD1D5DB);
// --- MUDANÇA DE COR APLICADA ---
const Color breadcrumbActiveColor = Color(0xFFff4757);

class TokenScreen extends StatefulWidget {
  final String email;
  final double? latitude;
  final double? longitude;

  const TokenScreen({super.key, required this.email,this.latitude,this.longitude,});

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
      // Tratar erro
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
          builder: (context) => PasswordScreen(email: widget.email),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(e.toString().replaceAll("Exception: ", ""))),
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
                      const SizedBox(height: 24),
                      const Text('Digite o código de verificação',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: darkTextColor)),
                      const SizedBox(height: 8),
                      Text(
                          'Um código de verificação foi enviado para o e-mail ${widget.email}',
                          style: const TextStyle(
                              fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(4, (index) {
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
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(12))),
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
                      ElevatedButton(
                        onPressed: _isLoading ? null : _validateToken,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Continuar',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: _timerSeconds == 0 ? _resendToken : null,
                          child: Text(
                            'Reenviar código',
                            style: TextStyle(
                                color: _timerSeconds == 0
                                    ? primaryColor
                                    : Colors.grey),
                          ),
                        ),
                      )
                    ]))));
  }
  
  Widget _buildBreadcrumbs({required int currentStep}) {
    return Row(
      children: [
        _buildDot(isActive: currentStep >= 1),
        _buildConnector(isActive: currentStep >= 2),
        _buildDot(isActive: currentStep >= 2),
        _buildConnector(isActive: currentStep >= 3),
        _buildDot(isActive: currentStep >= 3),
      ],
    );
  }

  Widget _buildDot({required bool isActive}) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: isActive ? breadcrumbActiveColor : borderColor,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildConnector({required bool isActive}) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? breadcrumbActiveColor : borderColor,
      ),
    );
  }
}