// lib/tabs/home_tab.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wtg_front/models/promotion_type.dart';
import 'package:wtg_front/services/api_service.dart';
import 'package:wtg_front/services/location_service.dart';

// Paleta de Cores
const Color darkTextColor = Color(0xFF1F2937);
const Color lightTextColor = Color(0xFF6B7280);
const Color screenBackgroundColor = Color(0xFFF9FAFB);
const Color cardBackgroundColor = Color(0xFFF7F1E3); // CORREÇÃO 4: Cor do card alterada
const Color primaryAppColor = Color(0xFF6A00FF);
const Color tagColor = Color(0xFF10B981);

// Cores para os ícones, conforme solicitado
const Color iconColorLocation = Color(0xFF214886);
const Color iconColorComplement = Color(0xFFec9b28);
const Color iconColorDescription = Color(0xFFd74533);
const Color iconColorReference = Color(0xFF214886); // Reutilizando a primeira cor
const Color iconColorTitle = Color(0xFFec9b28); // Reutilizando a segunda cor


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
      if (mounted) setState(() {
        _error = "Sessão inválida.";
        _isLoading = false;
      });
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
      print("### ERRO AO BUSCAR EVENTOS: $e");
      if (mounted) {
        setState(() {
          _error = "Não foi possível carregar os eventos.";
          _isLoading = false;
        });
      }
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filtrar Eventos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkTextColor)),
                  const SizedBox(height: 24),
                  Text('Distância: até ${_currentRadius.toInt()} km', style: const TextStyle(color: darkTextColor, fontSize: 16)),
                  Slider(
                    value: _currentRadius,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    activeColor: primaryAppColor,
                    label: '${_currentRadius.toInt()} km',
                    onChanged: (double value) => setModalState(() => _currentRadius = value),
                  ),
                  const Text('Tipo de Rolê', style: TextStyle(color: darkTextColor, fontSize: 16)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: PromotionType.values.map((type) {
                      final isSelected = _selectedType == type;
                      return FilterChip(
                        label: Text(type.displayName),
                        selected: isSelected,
                        onSelected: (bool selected) {
                          setModalState(() => _selectedType = selected ? type : null);
                        },
                        backgroundColor: Colors.grey[100],
                        selectedColor: primaryAppColor.withOpacity(0.2),
                        labelStyle: TextStyle(color: isSelected ? primaryAppColor : darkTextColor, fontWeight: FontWeight.w600),
                        shape: StadiumBorder(side: BorderSide(color: isSelected ? primaryAppColor : Colors.grey.shade300)),
                        showCheckmark: false,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _fetchData();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryAppColor,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Aplicar Filtros', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( 
      backgroundColor: screenBackgroundColor,
      body: Column(
        children: [
          _buildTopFiltersBar(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_promotions.length} rolês encontrados',
                style: const TextStyle(color: lightTextColor, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildTopFiltersBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildFilterButton(icon: Icons.sort, label: 'Ordenar', onPressed: () {}),
          _buildFilterButton(icon: Icons.filter_list, label: 'Filtrar', onPressed: _showFilterSheet),
          _buildFilterButton(icon: Icons.map_outlined, label: 'Mapa', onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildFilterButton({required IconData icon, required String label, required VoidCallback onPressed}) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: darkTextColor, size: 20),
      label: Text(label, style: const TextStyle(color: darkTextColor, fontWeight: FontWeight.bold)),
      style: TextButton.styleFrom(
        foregroundColor: primaryAppColor,
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }
    if (_promotions.isEmpty) {
      return const Center(child: Text("Nenhum evento encontrado."));
    }
    return RefreshIndicator(
      onRefresh: _fetchData,
      child: Center( 
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800), 
          child: ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: _promotions.length,
            itemBuilder: (context, index) {
              return _buildEventCard(_promotions[index]);
            },
            separatorBuilder: (context, index) => const SizedBox(height: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> promotion) {
    final addressInfo = promotion['address'];
    final isFree = promotion['free'] ?? false;
    final hasComments = promotion['commentsCount'] != null && promotion['commentsCount'] > 0;
    final images = promotion['images'] as List<dynamic>?;
    final imageUrl = (images != null && images.isNotEmpty) ? images[0]['presignedUrl'] : null;

    final title = promotion['title'] ?? 'Nome do Rolê';
    final description = promotion['description'] ?? 'Descrição não informada';
    final location = addressInfo != null
        ? '${addressInfo['address'] ?? 'Endereço'}, ${addressInfo['number'] ?? 'S/N'}'
        : 'Localização não informada';
    final complement = addressInfo?['complement'] ?? 'Não informado';
    final reference = addressInfo?['reference'] ?? 'Não informada';

    return Card(
      elevation: 0.5, // Sombra mais sutil
      shadowColor: Colors.black.withOpacity(0.1),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1), // Borda sutil
      ),
      color: cardBackgroundColor, // CORREÇÃO: Cor de fundo do card
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagem à Esquerda
            SizedBox(
              width: 120,
              child: Container(
                color: Colors.grey[200],
                child: imageUrl != null
                    ? Image.network(imageUrl, fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        errorBuilder: (context, error, stack) => const Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 40)),
                      )
                    : const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 40)),
              ),
            ),
            
            // Detalhes à Direita
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column( 
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isFree || hasComments) ...[
                      Row(
                        children: [
                          if (isFree)
                            _buildTag('Gratuito', Colors.green.shade700, Icons.local_offer_outlined),
                          if (isFree && hasComments)
                            const SizedBox(width: 8),
                          if (hasComments)
                            _buildTag('Comentários', Colors.blue.shade700, Icons.comment_outlined),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    // Detalhes com espaçamento fixo
                    _buildDetailRow(Icons.push_pin_outlined, 'Nome do rolê', title, iconColorTitle),
                    const Divider(height: 16), // CORREÇÃO: Divisores internos
                    _buildDetailRow(Icons.location_on_outlined, 'Localização', location, iconColorLocation),
                    const Divider(height: 16),
                    _buildDetailRow(Icons.segment_outlined, 'Complemento', complement, iconColorComplement),
                    const Divider(height: 16),
                    _buildDetailRow(Icons.description_outlined, 'Descrição', description, iconColorDescription),
                     const Divider(height: 16),
                    _buildDetailRow(Icons.assistant_photo_outlined, 'Referência', reference, iconColorReference),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 11, fontWeight: FontWeight.w500)),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: darkTextColor),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}