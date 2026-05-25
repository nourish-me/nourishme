// A product looked up from Open Food Facts, reduced to the few fields we need
// to prefill a meal. Nutriments are stored per 100 g/ml (OFF's canonical
// basis); the confirm screen scales them to the amount the user enters.
class OffProduct {
  final String name;
  final String? brand;
  final double kcalPer100;
  final double proteinPer100;
  final double carbsPer100;
  final double fatPer100;
  // Manufacturer serving size in [unit], when OFF provides one. Used as the
  // default amount so a scan lands on "1 serving" rather than a flat 100 g.
  final double? servingQuantity;
  final String unit; // 'g' for solids, 'ml' for drinks

  const OffProduct({
    required this.name,
    required this.brand,
    required this.kcalPer100,
    required this.proteinPer100,
    required this.carbsPer100,
    required this.fatPer100,
    required this.servingQuantity,
    required this.unit,
  });

  double get defaultAmount =>
      (servingQuantity != null && servingQuantity! > 0) ? servingQuantity! : 100;

  // Short label for the meal summary: "Nutella (Ferrero)", capped at 80 chars
  // to match what the parser produces. Skips the brand when the name already
  // contains it.
  String get displaySummary {
    final hasBrand = brand != null && brand!.isNotEmpty;
    final base = hasBrand && !name.toLowerCase().contains(brand!.toLowerCase())
        ? '$name ($brand)'
        : name;
    return base.length > 80 ? base.substring(0, 80) : base;
  }

  // Builds an OffProduct from the OFF `product` object. Returns null when the
  // payload lacks a usable name or energy value, so the caller treats it like
  // a miss and falls back to manual entry.
  static OffProduct? fromOffJson(Map<String, dynamic> product) {
    final nutriments = product['nutriments'];
    if (nutriments is! Map<String, dynamic>) return null;

    double? per100(String key) {
      final v = nutriments[key];
      return v is num ? v.toDouble() : null;
    }

    var kcal = per100('energy-kcal_100g');
    if (kcal == null) {
      final kj = per100('energy_100g'); // kJ, when kcal isn't given directly
      if (kj != null) kcal = kj / 4.184;
    }
    if (kcal == null) return null;

    final nameDe = (product['product_name_de'] as String?)?.trim();
    final nameGeneric = (product['product_name'] as String?)?.trim();
    final name = (nameDe != null && nameDe.isNotEmpty) ? nameDe : (nameGeneric ?? '');
    if (name.isEmpty) return null;

    final brands = (product['brands'] as String?)?.trim();
    final brand = (brands != null && brands.isNotEmpty)
        ? brands.split(',').first.trim()
        : null;

    final blob =
        '${(product['serving_size'] as String?) ?? ''} ${(product['quantity'] as String?) ?? ''}'
            .toLowerCase();
    final unit = (blob.contains('ml') ||
            blob.contains('cl') ||
            RegExp(r'\bl\b').hasMatch(blob))
        ? 'ml'
        : 'g';

    return OffProduct(
      name: name.length > 70 ? name.substring(0, 70) : name,
      brand: brand,
      kcalPer100: kcal,
      proteinPer100: per100('proteins_100g') ?? 0,
      carbsPer100: per100('carbohydrates_100g') ?? 0,
      fatPer100: per100('fat_100g') ?? 0,
      servingQuantity: (product['serving_quantity'] as num?)?.toDouble(),
      unit: unit,
    );
  }
}
