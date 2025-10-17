// lib/models/promotion_type.dart

// Representa o enum PromotionType do backend.
enum PromotionType {
  PARTY('Festa'),
  SHOW('Show'),
  FOOD('Comida'),
  BIGEVENT('Grande Evento'),
  CULTURAL('Cultural'),
  OTHER('Outro');

  const PromotionType(this.displayName);
  final String displayName;
}