// lib/tabs/my_events_tab.dart

import 'package:flutter/material.dart';
import 'package:wtg_front/services/api_service.dart';
import 'package:wtg_front/screens/promotion/create_promotion_step1_screen.dart';

// --- PALETA DE CORES (sem alterações) ---
const Color darkBackgroundColor = Color(0xFF1A202C);
const Color primaryTextColor = Colors.white;
const Color secondaryTextColor = Color(0xFFA0AEC0);
const Color fieldBackgroundColor = Color(0xFF2D3748);
const Color fieldBorderColor = Color(0xFF4A5568);
const Color primaryButtonColor = Color(0xFFE53E3E);
const Color visibleColor = Color(0xFF48BB78);
const Color invisibleColor = Color(0xFFA0AEC0);
const Color freeColor = Color(0xFF38B2AC);
const Color paidColor = Color(0xFFF6AD55);
const Color commentsColor = Color(0xFF4299E1);

class MyEventsTab extends StatefulWidget {
  final Map<String, dynamic> loginResponse;

  const MyEventsTab({super.key, required this.loginResponse});

  @override
  State<MyEventsTab> createState() => _MyEventsTabState();
}

class _MyEventsTabState extends State<MyEventsTab> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _promotion;
  List<String> _imageUrls = [];
  String? _error;
  int _currentImageIndex = 0;

  // *** NOVO: Estado de loading para a exclusão ***
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _fetchMyPromotion();
  }

  Future<void> _fetchMyPromotion() async {
    // ... (lógica inalterada)
    setState(() {
      _isLoading = true;
      _error = null;
      _promotion = null;
    });

    final cookie = widget.loginResponse['cookie'] as String?;
    if (cookie == null) {
      if (mounted) {
        setState(() {
          _error = "Sessão inválida. Por favor, faça login novamente.";
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final promotionData = await _apiService.getMyPromotion(cookie);
      final promotionId = promotionData['id'];

      if (promotionId != null) {
        final imageUrlsData =
            await _apiService.getPromotionImageViews(promotionId, cookie);
        _imageUrls = List<String>.from(imageUrlsData);
      }

      if (mounted) {
        setState(() {
          _promotion = promotionData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (e.toString().contains("Nenhuma promoção encontrada")) {
            _error = "Você ainda não possui um evento cadastrado.";
          } else {
            _error = e.toString().replaceAll("Exception: ", "");
          }
          _isLoading = false;
        });
      }
    }
  }

  // *** NOVO MÉTODO PARA EXIBIR DIÁLOGO DE CONFIRMAÇÃO E DELETAR ***
  Future<void> _deletePromotion() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: fieldBackgroundColor,
          title: const Text('Confirmar Exclusão', style: TextStyle(color: primaryTextColor)),
          content: const Text('Tem certeza de que deseja excluir seu rolê? Esta ação não pode ser desfeita.', style: TextStyle(color: secondaryTextColor)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar', style: TextStyle(color: secondaryTextColor)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Excluir', style: TextStyle(color: primaryButtonColor)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() => _isDeleting = true);
      try {
        final cookie = widget.loginResponse['cookie'] as String?;
        final promotionId = _promotion?['id']?.toString();

        if (cookie == null || promotionId == null) {
          throw Exception('Não foi possível excluir o evento. Tente fazer login novamente.');
        }

        await _apiService.deletePromotion(promotionId, cookie);

        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Seu rolê foi excluído com sucesso!')),
          );
          // Atualiza a tela para mostrar que não há mais evento
          _fetchMyPromotion();
        }
      } catch (e) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir: ${e.toString().replaceAll("Exception: ", "")}')),
          );
        }
      } finally {
        if(mounted) {
          setState(() => _isDeleting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackgroundColor,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: primaryButtonColor))
        : _buildContent(), // Exibe o conteúdo ou a tela de "nenhum evento"
    );
  }

  Widget _buildContent() {
    // ... (lógica de _buildContent inalterada, exceto pela adição do botão de excluir)
    if (_isDeleting) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryButtonColor),
            SizedBox(height: 16),
            Text('Excluindo seu rolê...', style: TextStyle(color: secondaryTextColor)),
          ],
        ),
      );
    }
    if (_error != null) {
      if (_error == "Você ainda não possui um evento cadastrado.") {
        return _buildNoEventRegistered();
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: secondaryTextColor, size: 60),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: secondaryTextColor, fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    if (_promotion == null) {
      return _buildNoEventRegistered();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Meu Rolê',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
            ),
          ),
          const SizedBox(height: 24),
          _buildImageGallery(),
          const SizedBox(height: 24),
          _buildStatusRow(),
          const SizedBox(height: 24),
          _buildDetailsCard(),
          const SizedBox(height: 24),
          _buildPrimaryButton('Editar Evento', () async {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CreatePromotionStep1Screen(
                  loginResponse: widget.loginResponse,
                  promotion: _promotion,
                ),
              ),
            );
            if (result == true) {
              _fetchMyPromotion();
            }
          }),
          const SizedBox(height: 16),
          // *** NOVO BOTÃO DE EXCLUIR ADICIONADO AQUI ***
          _buildDeleteButton(),
        ],
      ),
    );
  }

  // *** NOVO WIDGET PARA O BOTÃO DE EXCLUIR ***
  Widget _buildDeleteButton() {
    return OutlinedButton(
      onPressed: _deletePromotion,
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryButtonColor,
        minimumSize: const Size(double.infinity, 56),
        side: const BorderSide(color: primaryButtonColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_outline, size: 20),
          SizedBox(width: 8),
          Text(
            'Excluir Evento',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ... (restante dos widgets de build inalterados)
   Widget _buildNoEventRegistered() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.celebration_outlined, color: secondaryTextColor, size: 80),
            const SizedBox(height: 24),
            const Text(
              'Você ainda não tem nenhum rolê cadastrado.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Não quer divulgar um barzinho? Uma festinha pra geral??',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CreatePromotionStep1Screen(
                      loginResponse: widget.loginResponse,
                    ),
                  ),
                );
                if (result == true) {
                  _fetchMyPromotion();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryButtonColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                shadowColor: primaryButtonColor.withOpacity(0.4),
              ),
              child: const Text(
                'Cadastra um rolê aqui!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery() {
    if (_imageUrls.isEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: fieldBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: fieldBorderColor),
          ),
          child: const Center(
            child: Icon(Icons.image_not_supported_outlined, color: secondaryTextColor, size: 40),
          ),
        ),
      );
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 10,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: PageView.builder(
              itemCount: _imageUrls.length,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return _buildImage(_imageUrls[index]);
              },
            ),
          ),
        ),
        if (_imageUrls.length > 1) const SizedBox(height: 12),
        if (_imageUrls.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_imageUrls.length, (index) {
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentImageIndex == index
                      ? primaryTextColor
                      : secondaryTextColor,
                ),
              );
            }),
          ),
      ],
    );
  }

  Widget _buildImage(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: fieldBackgroundColor,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: primaryButtonColor)),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: fieldBackgroundColor,
          child: const Icon(Icons.error_outline, color: secondaryTextColor),
        );
      },
    );
  }

  Widget _buildStatusRow() {
    return Wrap(
      spacing: 12.0,
      runSpacing: 12.0,
      children: [
        _buildVisibilityStatus(),
        _buildPriceStatus(),
        _buildCommentsButton(),
      ],
    );
  }

  Widget _buildTag({required String text, required Color color, required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilityStatus() {
    final bool isActive = _promotion?['active'] ?? false;
    return _buildTag(
      text: isActive ? 'Visível' : 'Invisível',
      color: isActive ? visibleColor : invisibleColor,
      icon: isActive ? Icons.visibility_outlined : Icons.visibility_off_outlined,
    );
  }

  Widget _buildPriceStatus() {
    final bool isFree = _promotion?['free'] ?? true;
    return _buildTag(
      text: isFree ? 'Gratuito' : 'Pago',
      color: isFree ? freeColor : paidColor,
      icon: isFree ? Icons.local_activity_outlined : Icons.attach_money_outlined,
    );
  }

  Widget _buildCommentsButton() {
    return _buildTag(
      text: 'Comentários',
      color: commentsColor,
      icon: Icons.chat_bubble_outline,
      onTap: () {
        print('Botão de comentários clicado!');
      },
    );
  }

  Widget _buildDetailsCard() {
    final address = _promotion!['address'];
    final addressLine1 = address != null ? '${address['address']}, ${address['number']}' : 'Não informado';
    final addressLine2 = address != null ? '${address['postalCode']} - ${address['reference']}' : ' ';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: fieldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
            icon: Icons.push_pin_outlined,
            title: 'Nome do rolê',
            content: _promotion!['title'] ?? 'Não informado',
          ),
          const Divider(height: 32, color: fieldBorderColor),
          _buildDetailRow(
            icon: Icons.location_on_outlined,
            title: 'Localização',
            contentWidget: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(addressLine1, style: const TextStyle(color: primaryTextColor, fontSize: 16)),
                if (addressLine2.trim().isNotEmpty) const SizedBox(height: 4),
                if (addressLine2.trim().isNotEmpty) Text(addressLine2, style: const TextStyle(color: secondaryTextColor, fontSize: 14)),
              ],
            ),
          ),
          const Divider(height: 32, color: fieldBorderColor),
          _buildDetailRow(
            icon: Icons.notes_outlined,
            title: 'Descrição',
            content: _promotion!['description'] ?? 'Não informado',
          ),
          const Divider(height: 32, color: fieldBorderColor),
          _buildDetailRow(
            icon: Icons.add_comment_outlined,
            title: 'Complemento',
            content: address?['complement'] ?? 'Não informado',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    String? content,
    Widget? contentWidget,
  }) {
    if ((content == null || content == 'Não informado') && contentWidget == null) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: secondaryTextColor, size: 22),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, color: secondaryTextColor),
              ),
              const SizedBox(height: 6),
              contentWidget ??
                  Text(
                    content ?? '',
                    style: const TextStyle(
                        fontSize: 16,
                        color: primaryTextColor,
                        fontWeight: FontWeight.w500,
                        height: 1.4),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback onPressed) {
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
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}