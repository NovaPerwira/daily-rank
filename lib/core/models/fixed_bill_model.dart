class FixedBill {
  final String id;
  final String name;
  final double amount;
  final DateTime dueDate;
  String status; // 'pending', 'defeated', 'overdue'
  String? bossName;
  String? bossIcon;
  String? bossTaunt;

  FixedBill({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
    this.status = 'pending',
    this.bossName,
    this.bossIcon,
    this.bossTaunt,
  });

  FixedBill copyWith({
    String? id,
    String? name,
    double? amount,
    DateTime? dueDate,
    String? status,
    String? bossName,
    String? bossIcon,
    String? bossTaunt,
  }) {
    return FixedBill(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      bossName: bossName ?? this.bossName,
      bossIcon: bossIcon ?? this.bossIcon,
      bossTaunt: bossTaunt ?? this.bossTaunt,
    );
  }
}
