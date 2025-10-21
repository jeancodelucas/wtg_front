// lib/tabs/home_tab.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wtg_front/models/promotion_type.dart';
import 'package:wtg_front/services/api_service.dart';
import 'package:wtg_front/services/location_service.dart';

// --- PALETA DE CORES PADRONIZADA (dark mode) ---
const Color darkBackgroundColor = Color(0xFF1A202C);
const Color primaryTextColor = Colors.white;
const Color secondaryTextColor = Color(0xFFA0AEC0);
const Color fieldBackgroundColor = Color(0xFF2D3748); // Cor dos cards
const Color fieldBorderColor = Color(0xFF4A5568);
const Color primaryButtonColor = Color(0xFFE53E3E);
const Color accentColor = Color(0xFF6A00FF); // Roxo para filtros e destaques
const Color commentsColor = Color(0xFF4299E1); // Azul para comentários

class HomeTab extends StatefulWidget {
  final Map<String, dynamic> loginResponse;
  const HomeTab({super.key, required this.loginResponse});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();

  bool _isLoading = true;
  String? _error;
  List<dynamic> _promotions = [];
  Position? _currentPosition;

  // Filtros
  double _currentRadius = 10.0;
  PromotionType? _selectedType;

  @override
  void initState() {
    super.initState();
    _initializeAndFetch();
  }

  Future<void> _initializeAndFetch() async {
    if (mounted) setState(() => _isLoading = true);
    _currentPosition = await _locationService.getCurrentPosition();
    await _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final cookie = widget.loginResponse['cookie'] as String?;
    if (cookie == null) {
      if (mounted) {
        setState(() {
          _error = "Sessão inválida.";
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final allPromotions = await _apiService.filterPromotions(
        cookie: cookie,
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
        radius: _currentRadius,
        promotionType: _selectedType,
      );

      if (mounted) {
        setState(() {
          _promotions = allPromotions;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Não foi possível carregar os rolês.";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackgroundColor,
      // --- ESTRUTURA ATUALIZADA PARA FILTRO ESTÁTICO ---
      body: SafeArea(
        child: Column(
          children: [
            // Filtros ficam aqui, fora da área de rolagem
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: _buildFiltersCard(),
            ),
            // A lista de promoções ocupa o resto da tela e é rolável
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET DE FILTROS UNIFICADO EM UM CARD ---
  Widget _buildFiltersCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: fieldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- Seção do Raio ---
          Row(
            children: [
              const Icon(Icons.radar_outlined, color: secondaryTextColor, size: 20),
              const SizedBox(width: 12),
              const Text(
                'Raio de busca',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '${_currentRadius.toInt()} km',
                style: const TextStyle(
                  color: primaryButtonColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: _currentRadius,
            min: 1,
            max: 50,
            divisions: 49,
            activeColor: primaryButtonColor,
            inactiveColor: fieldBorderColor,
            label: '${_currentRadius.toInt()} km',
            onChanged: (double value) {
              setState(() => _currentRadius = value);
            },
            onChangeEnd: (double value) {
              _fetchData();
            },
          ),
          const Divider(color: fieldBorderColor, height: 1),
          const SizedBox(height: 12),
          // --- Seção das Categorias ---
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryChip(
                  label: "Todos",
                  isSelected: _selectedType == null,
                  onSelected: () {
                    setState(() {
                      _selectedType = null;
                      _fetchData();
                    });
                  },
                ),
                ...PromotionType.values.map((type) {
                  return _buildCategoryChip(
                    label: type.displayName,
                    isSelected: _selectedType == type,
                    onSelected: () {
                      setState(() {
                        _selectedType = (_selectedType == type) ? null : type;
                        _fetchData();
                      });
                    },
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET PARA OS CHIPS DE CATEGORIA (NOVO DESIGN) ---
  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: ActionChip(
        onPressed: onSelected,
        label: Text(label),
        avatar: isSelected
            ? const Icon(Icons.check_circle_outline,
                color: Colors.white, size: 18)
            : null,
        backgroundColor: isSelected ? accentColor : fieldBackgroundColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : secondaryTextColor,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? accentColor : fieldBorderColor,
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: primaryButtonColor));
    }
    if (_error != null) {
      return Center(
          child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }
    if (_promotions.isEmpty) {
      return const Center(
          child: Text("Nenhum rolê encontrado.",
              style: TextStyle(color: secondaryTextColor, fontSize: 16)));
    }
    return RefreshIndicator(
      onRefresh: _fetchData,
      color: primaryButtonColor,
      backgroundColor: fieldBackgroundColor,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0),
        itemCount: _promotions.length,
        itemBuilder: (context, index) {
          return _buildEventCard(_promotions[index] as Map<String, dynamic>);
        },
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> promotion) {
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

    return Card(
      color: fieldBackgroundColor,
      margin: const EdgeInsets.only(bottom: 20),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: primaryButtonColor,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print('Erro ao carregar imagem: $error');
                        return const Center(
                          child: Icon(
                            Icons.error_outline,
                            color: fieldBorderColor,
                            size: 40,
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: fieldBorderColor,
                        size: 40,
                      ),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // --- TAGS ATUALIZADAS ---
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
                    const SizedBox(height: 8),
                    const Divider(color: fieldBorderColor),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                        Icons.location_on_outlined, 'Localização', location),
                    _buildDetailRow(
                        Icons.segment_outlined, 'Complemento', complement),
                    _buildDetailRow(
                        Icons.description_outlined, 'Descrição', description),
                    _buildDetailRow(
                        Icons.assistant_photo_outlined, 'Referência', reference),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    if (value == 'Não informado' || value.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: secondaryTextColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: secondaryTextColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: primaryTextColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
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
          Text(text,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}