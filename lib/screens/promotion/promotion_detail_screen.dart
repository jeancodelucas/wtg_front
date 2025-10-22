// lib/screens/promotion/promotion_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wtg_front/services/api_service.dart';

// --- PALETA DE CORES (Consistente com o resto do app) ---
const Color darkBackgroundColor = Color(0xFF1A202C);
const Color primaryTextColor = Colors.white;
const Color secondaryTextColor = Color(0xFFA0AEC0);
const Color fieldBackgroundColor = Color(0xFF2D3748);
const Color accentColor = Color(0xFF82589F);
const Color commentsColor = Color(0xFF4299E1);
const Color fieldBorderColor = Color(0xFF4A5568);

class PromotionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> promotion;
  // NOVOS: ID do usuário logado e cookie para fazer requisições
  final int currentUserId;
  final String cookie;

  const PromotionDetailScreen({
    super.key,
    required this.promotion,
    required this.currentUserId,
    required this.cookie,
  });

  @override
  State<PromotionDetailScreen> createState() => _PromotionDetailScreenState();
}

class _PromotionDetailScreenState extends State<PromotionDetailScreen> {
  late Map<String, dynamic> _promotionData;
  final ApiService _apiService = ApiService();

  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _promotionData = widget.promotion;
  }

  Future<void> _openInGoogleMaps(double latitude, double longitude) async {
    final Uri googleMapsUrl =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o Google Maps.'),
          ),
        );
      }
    }
  }

  // NOVO: Função para deletar comentário
  Future<void> _deleteComment(int commentId) async {
    // Exibe um diálogo de confirmação
    final bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar Exclusão'),
            content: const Text('Você tem certeza que quer deletar este comentário?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Deletar'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        await _apiService.deleteComment(commentId, widget.cookie);

        // Atualiza a UI removendo o comentário da lista local
        setState(() {
          (_promotionData['comments'] as List)
              .removeWhere((comment) => comment['id'] == commentId);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Comentário deletado com sucesso!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao deletar comentário: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _promotionData['title'] ?? 'Detalhes do Rolê';

    return Scaffold(
      backgroundColor: darkBackgroundColor,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: primaryTextColor)),
        backgroundColor: fieldBackgroundColor,
        iconTheme: const IconThemeData(color: primaryTextColor),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildEventDetailsCard(),
              const SizedBox(height: 20),
              // NOVO: Seção de comentários
              _buildCommentsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventDetailsCard() {
    final isFree = _promotionData['free'] ?? false;
    final ticketValue = _promotionData['ticketValue'];
    final images = _promotionData['images'] as List<dynamic>? ?? [];

    final description =
        _promotionData['description'] ?? 'Descrição não informada.';
    final addressInfo = _promotionData['address'];
    final location = addressInfo != null
        ? '${addressInfo['address'] ?? 'Endereço'}, ${addressInfo['number'] ?? 'S/N'}'
        : 'Localização não informada';
    final complement = addressInfo?['complement'] ?? 'Não informado';
    final reference = addressInfo?['reference'] ?? 'Não informada';

    final latitude = _promotionData['latitude'] as double?;
    final longitude = _promotionData['longitude'] as double?;

    String priceText;
    if (isFree) {
      priceText = 'Gratuito';
    } else if (ticketValue != null) {
      priceText =
          'R\$ ${double.parse(ticketValue.toString()).toStringAsFixed(2).replaceAll('.', ',')}';
    } else {
      priceText = 'Consulte';
    }

    return Container(
      decoration: BoxDecoration(
        color: fieldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (images.isNotEmpty) _buildImageCarousel(images),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _promotionData['title'] ?? 'Nome do Rolê',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTag(
                      text: priceText,
                      color: isFree ? Colors.green : accentColor,
                      icon: Icons.local_offer_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: fieldBorderColor),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.location_on_outlined, 'Localização', location,
                    latitude: latitude, longitude: longitude),
                _buildInfoRow(Icons.segment_outlined, 'Complemento', complement),
                _buildInfoRow(
                    Icons.description_outlined, 'Descrição', description),
                _buildInfoRow(
                    Icons.assistant_photo_outlined, 'Referência', reference),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // NOVO: Widget para a seção de comentários
  Widget _buildCommentsSection() {
    final comments = _promotionData['comments'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fieldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comentários',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryTextColor),
          ),
          const SizedBox(height: 16),
          if (comments.isEmpty)
            const Center(
              child: Text(
                'Ainda não há comentários. Seja o primeiro a comentar!',
                style: TextStyle(color: secondaryTextColor),
              ),
            ),
          if (comments.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: fieldBorderColor),
              itemBuilder: (context, index) {
                final comment = comments[index];
                final bool isOwner = comment['userId'] == widget.currentUserId;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: accentColor,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    comment['userFirstName'] ?? 'Usuário',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                  subtitle: Text(
                    comment['comment'] ?? '',
                    style: const TextStyle(color: secondaryTextColor),
                  ),
                  trailing: isOwner
                      ? IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          onPressed: () => _deleteComment(comment['id']),
                        )
                      : null,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel(List<dynamic> images) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: SizedBox(
            height: 250,
            child: PageView.builder(
              itemCount: images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final imageUrl = images[index]['presignedUrl'];
                return Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stack) {
                    return const Center(
                        child: Icon(Icons.error, color: Colors.red));
                  },
                );
              },
            ),
          ),
        ),
        if (images.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (index) {
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
          ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {double? latitude, double? longitude}) {
    if (value == 'Não informado' || value.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: secondaryTextColor, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        const TextStyle(color: secondaryTextColor, fontSize: 14)),
                const SizedBox(height: 4),
                Text(value,
                    style:
                        const TextStyle(color: primaryTextColor, fontSize: 16)),
              ],
            ),
          ),
          if (latitude != null && longitude != null)
            IconButton(
              icon: const Icon(Icons.map, color: commentsColor),
              onPressed: () => _openInGoogleMaps(latitude, longitude),
              tooltip: 'Ver no mapa',
            )
        ],
      ),
    );
  }

  Widget _buildTag(
      {required String text, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}