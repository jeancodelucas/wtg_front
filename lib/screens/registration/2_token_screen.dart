import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wtg_front/screens/registration/3_password_screen.dart';
import 'package:wtg_front/services/api_service.dart';

// --- CORES ---
const Color primaryButtonColor = Color(0xFFd74533);
const Color messageTextColor = Color(0xFFec9724);
const Color darkTextColor = Color(0xFF002956);
const Color placeholderColor = Color(0xFFE0E0E0); // Cor da borda padrão

// Cores do Breadcrumb
const Color verificationStepColor = Color(0xFF214886);
const Color passwordStepColor = Color(0xFFec9b28);
const Color infoStepColor = Color(0xFFd74533);

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
        setState(() {}); // Redesenha para atualizar a cor da borda ao focar
      });
    }
  }

  void startTimer() {
    _timerSeconds = 90;
    _timer?.cancel(); // Cancela timer anterior se existir
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
       if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Novo código enviado!')));
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
                      _buildBreadcrumbs(),
                      const SizedBox(height: 32),
                      const Text('Digite o código de verificação',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: darkTextColor)),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 12, color: messageTextColor),
                          children: [
                            const TextSpan(text: 'Um novo código de verificação foi enviado para o e-mail '),
                            TextSpan(
                              text: widget.email,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      // --- INPUTS COM NOVO ESTILO ---
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
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: placeholderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: placeholderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: verificationStepColor, width: 2),
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
                      ElevatedButton(
                        onPressed: _isLoading ? null : _validateToken,
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
                    ]))));
  }
  
  // O breadcrumb permanece o mesmo
  Widget _buildBreadcrumbs() {
    const int currentStep = 1;
    return Row(
      children: [
        _buildStepIndicator(step: 1, currentStep: currentStep, icon: Icons.mark_email_read_outlined, activeColor: verificationStepColor),
        _buildConnector(isComplete: currentStep > 1, color: passwordStepColor),
        _buildStepIndicator(step: 2, currentStep: currentStep, icon: Icons.lock_outline, activeColor: passwordStepColor),
        _buildConnector(isComplete: currentStep > 2, color: infoStepColor),
        _buildStepIndicator(step: 3, currentStep: currentStep, icon: Icons.person_outline, activeColor: infoStepColor),
      ],
    );
  }

  Widget _buildStepIndicator({required int step, required int currentStep, required IconData icon, required Color activeColor}) {
    final bool isActive = step == currentStep;
    final bool isComplete = step < currentStep;
    final Color color = isActive || isComplete ? activeColor : Colors.grey[400]!;

    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(step.toString(), style: TextStyle(color: color, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildConnector({required bool isComplete, required Color color}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 32, left: 4, right: 4),
        color: isComplete ? color : Colors.grey[300],
      ),
    );
  }
}