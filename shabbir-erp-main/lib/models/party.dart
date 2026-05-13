class Party {
  final String id;
  final String name;
  final String type;
  final double openingBal;
  final int createdAt;

  const Party({
    required this.id,
    required this.name,
    required this.type,
    required this.openingBal,
    required this.createdAt,
  });

  factory Party.fromMap(Map<String, dynamic> map) => Party(
        id: map['id'] as String,
        name: map['name'] as String,
        type: map['type'] as String,
        openingBal: (map['opening_bal'] as num).toDouble(),
        createdAt: map['created_at'] as int,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'opening_bal': openingBal,
        'created_at': createdAt,
      };

  Party copyWith({
    String? id,
    String? name,
    String? type,
    double? openingBal,
    int? createdAt,
  }) =>
      Party(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        openingBal: openingBal ?? this.openingBal,
        createdAt: createdAt ?? this.createdAt,
      );
}

class PartyWithBalance extends Party {
  final double balance;

  const PartyWithBalance({
    required super.id,
    required super.name,
    required super.type,
    required super.openingBal,
    required super.createdAt,
    required this.balance,
  });

  factory PartyWithBalance.fromParty(Party p, double balance) =>
      PartyWithBalance(
        id: p.id,
        name: p.name,
        type: p.type,
        openingBal: p.openingBal,
        createdAt: p.createdAt,
        balance: balance,
      );
}
