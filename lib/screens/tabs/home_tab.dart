// lib/tabs/home_tab.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wtg_front/models/promotion_type.dart';
import 'package:wtg_front/services/api_service.dart';
import 'package:wtg_front/services/location_service.dart';

// Paleta de Cores
const Color darkTextColor = Color(0xFF1F2937);
const Color lightTextColor = Color(0xFF6B7280);
const Color screenBackgroundColor = Colors.white; // Fundo branco como na referência
const Color cardBackgroundColor = Colors.white;
const Color primaryAppColor = Color(0xFF6A00FF);
const Color tagColor = Color(0xFF10B981);

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

  // Abre o painel de filtros
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // StatefulBuilder permite que o conteúdo do modal se atualize
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
                      Navigator.pop(context); // Fecha o modal
                      _fetchData(); // Aplica os filtros
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
    return Container(
      color: screenBackgroundColor,
      child: Column(
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
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _promotions.length,
        itemBuilder: (context, index) {
          return _buildEventCard(_promotions[index]);
        },
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> promotion) {
    final address = promotion['address'];
    final imageUrl = promotion['images']?.isNotEmpty == true ? promotion['images'][0]['presignedUrl'] : null;
    final isFree = promotion['free'] ?? false;

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.05),
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: IntrinsicHeight(
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: Container(
                color: Colors.grey[200],
                child: imageUrl != null
                    ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Center(child: Icon(Icons.error_outline)))
                    : const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("EVENTO", style: TextStyle(color: primaryAppColor, fontWeight: FontWeight.bold, fontSize: 10)),
                        IconButton(
                          icon: const Icon(Icons.favorite_border, color: lightTextColor, size: 20),
                          onPressed: () {},
                        )
                      ],
                    ),
                    Text(
                      promotion['title'] ?? 'Nome do Rolê',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkTextColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    if (address != null)
                      _buildInfoRow(Icons.location_on_outlined, '${address['address']}, ${address['number']}'),
                    
                    const Spacer(),
                    
                    if (isFree)
                      const Text('Grátis', style: TextStyle(color: tagColor, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: lightTextColor, size: 14),
        const SizedBox(width: 4),
        Expanded(
          child: Text(text, style: const TextStyle(color: lightTextColor, fontSize: 12), overflow: TextOverflow.ellipsis, maxLines: 1),
        ),
      ],
    );
  }
}