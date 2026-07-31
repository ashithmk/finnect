class GoalModel {
  final String id;
  final String title;
  final double targetPrice;
  final String? imageUrl;
  final String? description;
  final DateTime createdAt;
  final bool isPurchased;
  final bool isArchived;
  final bool notified;

  const GoalModel({
    required this.id,
    required this.title,
    required this.targetPrice,
    this.imageUrl,
    this.description,
    required this.createdAt,
    this.isPurchased = false,
    this.isArchived = false,
    this.notified = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'targetPrice': targetPrice,
      'imageUrl': imageUrl,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'isPurchased': isPurchased,
      'isArchived': isArchived,
      'notified': notified,
    };
  }

  factory GoalModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    final rawPrice = map['targetPrice'];
    double parsedPrice = 0.0;
    if (rawPrice is num) {
      parsedPrice = rawPrice.toDouble();
    } else if (rawPrice is String) {
      parsedPrice = double.tryParse(rawPrice) ?? 0.0;
    }

    return GoalModel(
      id: docId ?? map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      targetPrice: parsedPrice,
      imageUrl: map['imageUrl'] as String?,
      description: map['description'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isPurchased: map['isPurchased'] as bool? ?? false,
      isArchived: map['isArchived'] as bool? ?? false,
      notified: map['notified'] as bool? ?? false,
    );
  }

  GoalModel copyWith({
    String? id,
    String? title,
    double? targetPrice,
    String? imageUrl,
    String? description,
    DateTime? createdAt,
    bool? isPurchased,
    bool? isArchived,
    bool? notified,
  }) {
    return GoalModel(
      id: id ?? this.id,
      title: title ?? this.title,
      targetPrice: targetPrice ?? this.targetPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      isPurchased: isPurchased ?? this.isPurchased,
      isArchived: isArchived ?? this.isArchived,
      notified: notified ?? this.notified,
    );
  }
}
