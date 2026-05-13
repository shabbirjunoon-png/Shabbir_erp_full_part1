class StockItem {
  final String id;
  final String name;
  final String unit;
  final double currentQty;
  final int createdAt;

  const StockItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.currentQty,
    required this.createdAt,
  });

  factory StockItem.fromMap(Map<String, dynamic> map) => StockItem(
        id: map['id'] as String,
        name: map['name'] as String,
        unit: map['unit'] as String,
        currentQty: (map['current_qty'] as num).toDouble(),
        createdAt: map['created_at'] as int,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'unit': unit,
        'current_qty': currentQty,
        'created_at': createdAt,
      };

  StockItem copyWith({
    String? id,
    String? name,
    String? unit,
    double? currentQty,
    int? createdAt,
  }) =>
      StockItem(
        id: id ?? this.id,
        name: name ?? this.name,
        unit: unit ?? this.unit,
        currentQty: currentQty ?? this.currentQty,
        createdAt: createdAt ?? this.createdAt,
      );
}
