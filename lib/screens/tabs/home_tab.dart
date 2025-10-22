// lib/tabs/home_tab.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wtg_front/models/promotion_type.dart';
import 'package:wtg_front/screens/promotion/promotion_detail_screen.dart';
import 'package:wtg_front/services/api_service.dart';
import 'package:wtg_front/services/location_service.dart';

// --- PALETA DE CORES PADRONIZADA (dark mode) ---
const Color darkBackgroundColor = Color(0xFF1A202C);
const Color primaryTextColor = Colors.white;
const Color secondaryTextColor = Color(0xFFA0AEC0);
const Color fieldBackgroundColor = Color(0xFF2D3748); // Cor dos cards
const Color fieldBorderColor = Color(0xFF4A5568);
const Color primaryButtonColor = Color(0xFFE53E3E);
const Color accentColor = Color(0xFF82589F); // Roxo para filtros e destaques
const Color commentsColor = Color(0xFF4299E1); // Azul para comentários
const Color mapIconColor = Color(0xFFF39C12);

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
  Position? _currentPosition;

  List<dynamic> _allPromotions = [];
  List<dynamic> _filteredPromotions = [];

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
      final promotions = await _apiService.filterPromotions(
        cookie: cookie,
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
        radius: 20000,
        promotionType: null,
      );

      if (mounted) {
        setState(() {
          _allPromotions = promotions;
          _isLoading = false;
          _error = null;
        });
        _applyFilters();
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

  void _applyFilters() {
    if (!mounted) return;

    List<dynamic> promotionsToShow = List.from(_allPromotions);

    if (_selectedType != null) {
      promotionsToShow = promotionsToShow.where((p) {
        // CORREÇÃO SUTIL: A chave no JSON da API de filtro é 'promotionType'
        final typeString = p['promotionType'] as String?;
        return typeString?.toLowerCase() == _selectedType!.name.toLowerCase();
      }).toList();
    }

    if (_currentPosition != null) {
      promotionsToShow = promotionsToShow.where((p) {
        final lat = p['latitude'] as double?;
        final lon = p['longitude'] as double?;

        if (lat == null || lon == null) return false;

        final distanceInMeters = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          lat,
          lon,
        );
        final distanceInKm = distanceInMeters / 1000;
        return distanceInKm <= _currentRadius;
      }).toList();
    }

    setState(() {
      _filteredPromotions = promotionsToShow;
    });
  }

  // NOVA FUNÇÃO DE NAVEGAÇÃO QUE CHAMA O ENDPOINT DE DETALHES
  void _navigateToDetail(int promotionId) async {
    final cookie = widget.loginResponse['cookie'] as String?;
    if (cookie == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator(color: primaryButtonColor));
      },
    );

    try {
      final promotionDetails = await _apiService.getPromotionDetail(promotionId, cookie);
      if (mounted) Navigator.pop(context);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PromotionDetailScreen(
              promotion: promotionDetails,
              currentUserId: widget.loginResponse['user']['id'],
              cookie: cookie,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar detalhes: ${e.toString()}')),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: _buildFiltersCard(),
            ),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

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
          Row(
            children: [
              const Icon(Icons.radar_outlined,
                  color: secondaryTextColor, size: 20),
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
                  color: mapIconColor,
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
              _applyFilters();
            },
          ),
          const Divider(color: fieldBorderColor, height: 1),
          const SizedBox(height: 12),
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
                      _applyFilters();
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
                        _applyFilters();
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
    if (_filteredPromotions.isEmpty) {
      return const Center(
          child: Text("Nenhum rolê encontrado com os filtros atuais.",
              style: TextStyle(color: secondaryTextColor, fontSize: 16)));
    }
    return RefreshIndicator(
      onRefresh: _fetchData,
      color: primaryButtonColor,
      backgroundColor: fieldBackgroundColor,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0),
        itemCount: _filteredPromotions.length,
        itemBuilder: (context, index) {
          return _buildEventCard(
              _filteredPromotions[index] as Map<String, dynamic>);
        },
      ),
    );
  }

  Widget _buildImageWidget(String? imageUrl) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
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
                  return Container(
                    color: fieldBorderColor.withOpacity(0.5),
                    child: const Center(
                      child: Icon(
                        Icons.error_outline,
                        color: secondaryTextColor,
                        size: 30,
                      ),
                    ),
                  );
                },
              )
            : Container(
                color: fieldBorderColor.withOpacity(0.5),
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: secondaryTextColor,
                    size: 30,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> promotion) {
    final addressInfo = promotion['address'];
    final isFree = promotion['free'] ?? false;
    final ticketValue = promotion['ticketValue'];

    final images = promotion['images'] as List<dynamic>? ?? [];
    final imageUrl1 = images.isNotEmpty ? images[0]['presignedUrl'] : null;
    final imageUrl2 = images.length > 1 ? images[1]['presignedUrl'] : null;

    final title = promotion['title'] ?? 'Nome do Rolê';
    final description = promotion['description'] ?? 'Descrição não informada';
    final location = addressInfo != null
        ? '${addressInfo['address'] ?? 'Endereço'}, ${addressInfo['number'] ?? 'S/N'}'
        : 'Localização não informada';
    final complement = addressInfo?['complement'] ?? 'Não informado';
    final reference = addressInfo?['reference'] ?? 'Não informada';

    final latitude = promotion['latitude'] as double?;
    final longitude = promotion['longitude'] as double?;

    String priceText;
    if (isFree) {
      priceText = 'Gratuito';
    } else if (ticketValue != null) {
      priceText =
          'R\$ ${double.parse(ticketValue.toString()).toStringAsFixed(2).replaceAll('.', ',')}';
    } else {
      priceText = 'Consulte';
    }

    return InkWell(
      // A ÚNICA ALTERAÇÃO ESTÁ AQUI:
      onTap: () {
        // A nova função de navegação é chamada aqui
        _navigateToDetail(promotion['id']);
      },
      child: Card(
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
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      _buildImageWidget(imageUrl1),
                      if (imageUrl2 != null) ...[
                        const SizedBox(height: 8),
                        _buildImageWidget(imageUrl2),
                      ]
                    ],
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
                      const Spacer(),
                      const Divider(color: fieldBorderColor, height: 8),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildDetailRow(Icons.location_on_outlined,
                                'Localização', location),
                          ),
                          if (latitude != null && longitude != null)
                            IconButton(
                              icon: const Icon(Icons.map,
                                  color: mapIconColor, size: 24),
                              onPressed: () =>
                                  _openInGoogleMaps(latitude, longitude),
                              tooltip: 'Ver no mapa',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            )
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.0),
                        child: Divider(color: fieldBorderColor, height: 1),
                      ),
                      _buildDetailRow(
                          Icons.segment_outlined, 'Complemento', complement),
                      _buildDetailRow(Icons.description_outlined, 'Descrição',
                          description),
                      _buildDetailRow(Icons.assistant_photo_outlined,
                          'Referência', reference),
                    ],
                  ),
                ),
              ),
            ],
          ),
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