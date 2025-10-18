import 'package:flutter/material.dart';
import 'package:wtg_front/models/promotion_type.dart';
import 'package:wtg_front/widgets/event_card.dart';
import 'package:wtg_front/widgets/highlight_circle.dart';

// Cores
const Color backgroundColor = Color(0xFFF8F8FA);
const Color darkTextColor = Color(0xFF2D3748);
const Color primaryAppColor = Color(0xFF6A00FF);

class HomeTab extends StatefulWidget {
  final Map<String, dynamic> loginResponse;
  const HomeTab({super.key, required this.loginResponse});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  double _currentRadius = 10.0; // Raio inicial em km
  PromotionType? _selectedType;

  @override
  Widget build(BuildContext context) {
    String userFirstName = widget.loginResponse['user']?['firstName'] ?? 'Usuário';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text('Olá, $userFirstName', style: const TextStyle(color: darkTextColor, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: darkTextColor),
            onPressed: () {
              // TODO: Implementar navegação para tela de notificações
            },
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          _buildHighlightsSection(),
          _buildFiltersSection(),
          _buildEventsList(),
        ],
      ),
    );
  }

  Widget _buildHighlightsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: 8, // Exemplo de 8 destaques
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(left: index == 0 ? 24.0 : 16.0, right: index == 7 ? 24.0 : 0),
              child: HighlightCircle(
                // O ideal é que a imageUrl e o label venham da sua API no futuro
                imageUrl: 'https://picsum.photos/id/${index + 20}/200', // Imagem de exemplo
                label: 'Evento ${index + 1}',
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Eventos a até ${_currentRadius.toInt()} km de distância',
            style: const TextStyle(color: darkTextColor, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Slider(
            value: _currentRadius,
            min: 1,
            max: 50,
            divisions: 49,
            activeColor: primaryAppColor,
            label: '${_currentRadius.toInt()} km',
            onChanged: (double value) {
              setState(() {
                _currentRadius = value;
              });
              // TODO: Adicionar lógica para refazer a busca na API com o novo raio
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: PromotionType.values.map((type) {
                final isSelected = _selectedType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(type.displayName),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedType = selected ? type : null;
                      });
                      // TODO: Adicionar lógica para refazer a busca na API com o novo tipo
                    },
                    backgroundColor: Colors.white,
                    selectedColor: primaryAppColor.withOpacity(0.2),
                    labelStyle: TextStyle(color: isSelected ? primaryAppColor : darkTextColor, fontWeight: FontWeight.bold),
                    shape: StadiumBorder(side: BorderSide(color: isSelected ? primaryAppColor : Colors.grey.shade300)),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    // TODO: Aqui você faria a chamada à API para buscar os eventos com os filtros.
    // Por enquanto, é uma lista de exemplo para montar a UI.
    return ListView.builder(
      padding: const EdgeInsets.all(24.0),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5, // Exemplo de 5 eventos
      itemBuilder: (context, index) {
        return EventCard(
          imageUrl: 'https://picsum.photos/id/${index + 50}/400/200',
          title: 'Nome do Evento ${index + 1}',
          distance: '${(index * 1.5 + 2).toStringAsFixed(1)} km',
          date: 'Sáb, ${18 + index} Out',
        );
      },
    );
  }
}