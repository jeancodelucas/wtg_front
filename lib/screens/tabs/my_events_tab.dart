// lib/tabs/my_events_tab.dart

import 'package:flutter/material.dart';
import 'package:wtg_front/services/api_service.dart';

// Paleta de Cores
const Color darkTextColor = Color(0xFF1F2937);
const Color lightTextColor = Color(0xFF6B7280);
const Color primaryColor = Color(0xFF214886);
const Color editButtonColor = Color(0xFF2563EB);
const Color visibleColor = Color(0xFF10ac84);
const Color invisibleColor = Color(0xFF6B7280);
const Color freeColor = Color(0xFF10B981);
const Color paidColor = Color(0xFFF59E0B);
// --- NOVA COR PARA O INDICADOR DE COMENTÁRIOS ---
const Color commentsColor = Color(0xFF3B82F6); // Um azul para "Comentários"

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

  @override
  void initState() {
    super.initState();
    _fetchMyPromotion();
  }

  Future<void> _fetchMyPromotion() async {
    final cookie = widget.loginResponse['cookie'] as String?;
    if (cookie == null) {
      setState(() {
        _error = "Sessão inválida. Por favor, faça login novamente.";
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, color: Colors.grey[400], size: 60),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: lightTextColor, fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    if (_promotion == null) {
      return const Center(child: Text("Nenhum evento encontrado."));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageGallery(),
            const SizedBox(height: 16),
            _buildStatusRow(), // Linha com os 3 status
            const SizedBox(height: 16),
            _buildDetailsCard(),
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
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child:
                Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _imageUrls.length > 6 ? 6 : _imageUrls.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _buildImage(_imageUrls[index]),
        );
      },
    );
  }

  Widget _buildImage(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[200],
          child: const Icon(Icons.error_outline, color: Colors.red),
        );
      },
    );
  }

  Widget _buildStatusRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildVisibilityStatus(),
        _buildPriceStatus(),
        _buildCommentsButton(),
      ],
    );
  }

  Widget _buildVisibilityStatus() {
    final bool isActive = _promotion?['active'] ?? false;
    final Color statusColor = isActive ? visibleColor : invisibleColor;
    final String statusText = isActive ? 'Visível' : 'Invisível';
    final IconData statusIcon =
        isActive ? Icons.visibility_outlined : Icons.visibility_off_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 16),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceStatus() {
    final bool isFree = _promotion?['free'] ?? true;
    final Color statusColor = isFree ? freeColor : paidColor;
    final String statusText = isFree ? 'Gratuito' : 'Pago';
    final IconData statusIcon = isFree
        ? Icons.local_activity_outlined
        : Icons.attach_money_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 16),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET DE COMENTÁRIOS ATUALIZADO PARA SEGUIR O PADRÃO ---
  Widget _buildCommentsButton() {
    const Color statusColor = commentsColor;
    const String statusText = 'Comentários';
    const IconData statusIcon = Icons.chat_bubble_outline;

    return GestureDetector(
      onTap: () {
        // TODO: Implementar navegação para a tela de comentários
        print('Botão de comentários clicado!');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(statusIcon, color: statusColor, size: 16),
            SizedBox(width: 8),
            Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    final address = _promotion!['address'];
    final addressLine1 = address != null
        ? '${address['address']}, ${address['number']}'
        : 'Não informado';
    final addressLine2 = address != null
        ? '${address['postalCode']} - ${address['reference']}'
        : ' ';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
            icon: Icons.push_pin_outlined,
            title: 'Nome do rolê',
            content: _promotion!['title'] ?? 'Não informado',
          ),
          const Divider(height: 32),
          _buildDetailRow(
            icon: Icons.location_on_outlined,
            title: 'Localização',
            contentWidget: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(addressLine1,
                    style:
                        const TextStyle(color: darkTextColor, fontSize: 16)),
                Text(addressLine2,
                    style:
                        const TextStyle(color: lightTextColor, fontSize: 14)),
              ],
            ),
          ),
          const Divider(height: 32),
          _buildDetailRow(
            icon: Icons.notes_outlined,
            title: 'Descrição',
            content: _promotion!['description'] ?? 'Não informado',
          ),
          const Divider(height: 32),
          _buildDetailRow(
            icon: Icons.add_comment_outlined,
            title: 'Complemento',
            content: address?['complement'] ?? 'Não informado',
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // TODO: Implementar navegação para a tela de edição
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: editButtonColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Editar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: primaryColor, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, color: lightTextColor),
              ),
              const SizedBox(height: 4),
              contentWidget ??
                  Text(
                    content ?? '',
                    style: const TextStyle(
                        fontSize: 16,
                        color: darkTextColor,
                        fontWeight: FontWeight.w500),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}