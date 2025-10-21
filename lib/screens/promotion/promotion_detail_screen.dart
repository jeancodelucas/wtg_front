// lib/screens/promotion/promotion_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// --- PALETA DE CORES ---
const Color darkBackgroundColor = Color(0xFF1A202C);
const Color primaryTextColor = Colors.white;
const Color secondaryTextColor = Color(0xFFA0AEC0);
const Color fieldBackgroundColor = Color(0xFF2D3748);
const Color accentColor = Color(0xFF6A00FF);
const Color commentsColor = Color(0xFF4299E1);
const Color fieldBorderColor = Color(0xFF4A5568);

class PromotionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> promotion;

  const PromotionDetailScreen({super.key, required this.promotion});

  // Função para abrir o mapa
  Future<void> _launchMaps(String address) async {
    final query = Uri.encodeComponent(address);
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Não foi possível abrir o mapa para $address';
    }
  }

  @override
  Widget build(BuildContext context) {
    final addressInfo = promotion['address'];
    final isFree = promotion['free'] ?? false;
    final ticketValue = promotion['ticketValue'];
    final images = promotion['images'] as List<dynamic>?;
    final imageUrl =
        (images != null && images.isNotEmpty) ? images[0]['presignedUrl'] : null;

    final title = promotion['title'] ?? 'Nome do Rolê';
    final description = promotion['description'] ?? 'Descrição não informada';
    final location = addressInfo != null
        ? '${addressInfo['address'] ?? 'Endereço'}, ${addressInfo['number'] ?? 'S/N'}'
        : 'Localização não informada';
    final neighborhood = addressInfo?['neighborhood'] ?? 'Não informado';
    final complement = addressInfo?['complement'] ?? 'Não informado';
    final reference = addressInfo?['reference'] ?? 'Não informada';

    String priceText;
    if (isFree) {
      priceText = 'Gratuito';
    } else if (ticketValue != null) {
      priceText =
          'R\$ ${double.parse(ticketValue.toString()).toStringAsFixed(2).replaceAll('.', ',')}';
    } else {
      priceText = 'Consulte';
    }

    return Scaffold(
      backgroundColor: darkBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            backgroundColor: fieldBackgroundColor,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.start,
              ),
              background: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      color: Colors.black.withOpacity(0.4),
                      colorBlendMode: BlendMode.darken,
                    )
                  : Container(color: fieldBackgroundColor),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildTag(
                        text: priceText,
                        color: isFree ? Colors.green : accentColor,
                        icon: Icons.local_offer_outlined,
                      ),
                      _buildTag(
                        text: 'Comentários',
                        color: commentsColor,
                        icon: Icons.chat_bubble_outline,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Descrição',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      color: secondaryTextColor,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: fieldBorderColor),
                  const SizedBox(height: 16),
                  _buildDetailRow(Icons.location_on_outlined, 'Localização', location),
                  _buildDetailRow(Icons.explore_outlined, 'Bairro', neighborhood),
                  _buildDetailRow(Icons.segment_outlined, 'Complemento', complement),
                  _buildDetailRow(Icons.assistant_photo_outlined, 'Referência', reference),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
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
                Text(
                  label,
                  style: const TextStyle(
                      color: secondaryTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: primaryTextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag({required String text, required Color color, required IconData icon}) {
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
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}