class Transaction {
  final String id;
  final String partyId;
  final String? itemId;
  final double qty;
  final double rate;
  final double total;
  final String type;
  final String date;
  final String remarks;
  final int createdAt;

  const Transaction({
    required this.id,
    required this.partyId,
    this.itemId,
    required this.qty,
    required this.rate,
    required this.total,
    required this.type,
    required this.date,
    required this.remarks,
    required this.createdAt,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
        id: map['id'] as String,
        partyId: map['party_id'] as String,
        itemId: map['item_id'] as String?,
        qty: (map['qty'] as num).toDouble(),
        rate: (map['rate'] as num).toDouble(),
        total: (map['total'] as num).toDouble(),
        type: map['type'] as String,
        date: map['date'] as String,
        remarks: map['remarks'] as String? ?? '',
        createdAt: map['created_at'] as int,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'party_id': partyId,
        'item_id': itemId,
        'qty': qty,
        'rate': rate,
        'total': total,
        'type': type,
        'date': date,
        'remarks': remarks,
        'created_at': createdAt,
      };

  Transaction copyWith({
    String? id,
    String? partyId,
    String? itemId,
    double? qty,
    double? rate,
    double? total,
    String? type,
    String? date,
    String? remarks,
    int? createdAt,
  }) =>
      Transaction(
        id: id ?? this.id,
        partyId: partyId ?? this.partyId,
        itemId: itemId ?? this.itemId,
        qty: qty ?? this.qty,
        rate: rate ?? this.rate,
        total: total ?? this.total,
        type: type ?? this.type,
        date: date ?? this.date,
        remarks: remarks ?? this.remarks,
        createdAt: createdAt ?? this.createdAt,
      );

  bool get isMoneyOnly => type == 'Receipt' || type == 'Payment';
}

const List<String> txTypes = ['Sale', 'Purchase', 'Receipt', 'Payment'];
