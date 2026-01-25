class Budget {
  final String id;
  final String userId;
  final String categoryId;
  final String categoryName;
  final String emoji;
  final double limitAmount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Budget({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.categoryName,
    required this.emoji,
    required this.limitAmount,
    required this.createdAt,
    this.updatedAt,
  });

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      categoryId: map['categorie_id'] as String,
      categoryName: map['categorie_nom'] as String? ?? 'Autre',
      emoji: map['categorie_emoji'] as String? ?? '📁',
      limitAmount: (map['montant_limite'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt:
          map['updated_at'] != null
              ? DateTime.parse(map['updated_at'] as String)
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'categorie_id': categoryId,
      'categorie_nom': categoryName,
      'categorie_emoji': emoji,
      'montant_limite': limitAmount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
