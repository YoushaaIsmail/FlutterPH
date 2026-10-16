class Medicine {
  final String id; // UUID as String
  final String name;
  final String? brand;
  final String? image;
  final double price; // parsed from string
  final bool prescriptionRequired;
  final bool isAvailable; // derive from total_quantity > 0?
  final String? strength;
  final String? form;
  final Category? category;
  final List<Ingredient> activeIngredients;

  // Additional fields from JSON (optional)
  final int totalQuantity;
  final String? nearestExpirationDate;
  final String? dosage;
  final String? warnings;
  final String? sideEffects;
  final String? instructions;
  final String? barcode;
  final int lowStockThreshold;
  final int addpiont;

  Medicine({
    required this.id,
    required this.name,
    this.brand,
    this.image,
    required this.price,
    required this.prescriptionRequired,
    required this.isAvailable,
    this.strength,
    this.form,
    this.category,
    required this.activeIngredients,
    required this.totalQuantity,
    this.nearestExpirationDate,
    this.dosage,
    this.warnings,
    this.sideEffects,
    this.instructions,
    this.barcode,
    required this.lowStockThreshold,
    required this.addpiont,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      image: json['image'] as String?,
      price: double.parse(json['price'].toString()), // handle string or number
      prescriptionRequired: json['prescription_required'] as bool? ?? false,
      // Use total_quantity > 0 to determine availability
      isAvailable: (json['total_quantity'] as int? ?? 0) > 0,
      strength: json['strength'] as String?,
      form: json['form'] as String?,
      category: json['category'] != null
          ? Category.fromJson(json['category'])
          : null,
      activeIngredients:
          (json['active_ingredients'] as List?)
              ?.map((i) => Ingredient.fromJson(i))
              .toList() ??
          [],
      totalQuantity: json['total_quantity'] as int? ?? 0,
      nearestExpirationDate: json['nearest_expiration_date'] as String?,
      dosage: json['dosage'] as String?,
      warnings: json['warnings'] as String?,
      sideEffects: json['side_effects'] as String?,
      instructions: json['instructions'] as String?,
      barcode: json['barcode'] as String?,
      lowStockThreshold: json['low_stock_threshold'] as int? ?? 0,
      addpiont: json['Addpiont'] as int? ?? 0, // note capital A
    );
  }
}

class Category {
  final String id; // UUID as String
  final String name;
  final String slug;

  Category({required this.id, required this.name, required this.slug});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
    );
  }
}

class Ingredient {
  final String id; // UUID as String
  final String name;

  Ingredient({required this.id, required this.name});

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(id: json['id'] as String, name: json['name'] as String);
  }
}
