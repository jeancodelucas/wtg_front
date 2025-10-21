// lib/screens/promotion/promotion_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

  const PromotionDetailScreen({super.key, required this.promotion});

  @override
  State<PromotionDetailScreen> createState() => _PromotionDetailScreenState();
}

class _PromotionDetailScreenState extends State<PromotionDetailScreen> {
  int _currentImageIndex = 0;

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

  @override
  Widget build(BuildContext context) {
    final title = widget.promotion['title'] ?? 'Detalhes do Rolê';

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
          child: _buildEventDetailsCard(),
        ),
      ),
    );
  }

  Widget _buildEventDetailsCard() {
    final isFree = widget.promotion['free'] ?? false;
    final ticketValue = widget.promotion['ticketValue'];
    final images = widget.promotion['images'] as List<dynamic>? ?? [];
    
    // --- MAPEAMENTO CORRETO DOS DADOS ---
    final description = widget.promotion['description'] ?? 'Descrição não informada.';
    final addressInfo = widget.promotion['address'];
    final location = addressInfo != null
        ? '${addressInfo['address'] ?? 'Endereço'}, ${addressInfo['number'] ?? 'S/N'}'
        : 'Localização não informada';
    final complement = addressInfo?['complement'] ?? 'Não informado';
    final reference = addressInfo?['reference'] ?? 'Não informada';
    // --- FIM DO MAPEAMENTO ---

    final latitude = widget.promotion['latitude'] as double?;
    final longitude = widget.promotion['longitude'] as double?;

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
                  widget.promotion['title'] ?? 'Nome do Rolê',
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
                
                // --- INFORMAÇÕES CORRIGIDAS ---
                _buildInfoRow(Icons.location_on_outlined, 'Localização', location,
                    latitude: latitude, longitude: longitude),
                _buildInfoRow(Icons.segment_outlined, 'Complemento', complement),
                _buildInfoRow(Icons.description_outlined, 'Descrição', description),
                _buildInfoRow(Icons.assistant_photo_outlined, 'Referência', reference),
                // --- FIM DAS CORREÇÕES ---
              ],
            ),
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
    
    // Não renderiza a linha se o valor for "Não informado" ou vazio
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