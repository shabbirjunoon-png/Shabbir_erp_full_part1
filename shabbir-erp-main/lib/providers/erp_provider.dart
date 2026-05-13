import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/party.dart';
import '../models/stock_item.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../services/backup_service.dart';
import '../utils/format.dart';

class ERPProvider extends ChangeNotifier {
  bool _ready = false;
  List<Party> _parties = [];
  List<StockItem> _inventory = [];
  List<Transaction> _transactions = [];

  bool get ready => _ready;
  List<Party> get parties => List.unmodifiable(_parties);
  List<StockItem> get inventory => List.unmodifiable(_inventory);
  List<Transaction> get transactions => List.unmodifiable(_transactions);

  final _uuid = const Uuid();
  final _db = DatabaseService.instance;

  Future<void> load() async {
    _parties = await _db.getParties();
    _inventory = await _db.getStockItems();
    _transactions = await _db.getTransactions();
    _ready = true;
    notifyListeners();
    BackupService.instance.autoBackupNative();
  }

  Future<void> _afterMutation() async {
    await BackupService.instance.recordDataChange();
    BackupService.instance.autoBackupNative();
  }

  // ── Computed ──────────────────────────────────────────────────────────────
  List<PartyWithBalance> get partiesWithBalance =>
      _parties.map((p) => PartyWithBalance.fromParty(p, getPartyBalance(p.id))).toList();

  double get totalReceivable => partiesWithBalance
      .where((p) => p.balance > 0)
      .fold(0.0, (s, p) => s + p.balance);

  double get totalPayable => partiesWithBalance
      .where((p) => p.balance < 0)
      .fold(0.0, (s, p) => s + p.balance.abs());

  double getPartyBalance(String partyId) {
    final party = _parties.firstWhere((p) => p.id == partyId, orElse: () => const Party(id: '', name: '', type: '', openingBal: 0, createdAt: 0));
    double bal = party.openingBal;
    for (final tx in _transactions) {
      if (tx.partyId != partyId) continue;
      if (tx.type == 'Sale') bal += tx.total;
      else if (tx.type == 'Receipt') bal -= tx.total;
      else if (tx.type == 'Purchase') bal -= tx.total;
      else if (tx.type == 'Payment') bal += tx.total;
    }
    return bal;
  }

  List<Transaction> getPartyTransactions(String partyId) =>
      _transactions.where((t) => t.partyId == partyId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Party? getPartyById(String id) =>
      _parties.where((p) => p.id == id).firstOrNull;

  StockItem? getItemById(String id) =>
      _inventory.where((i) => i.id == id).firstOrNull;

  // ── Parties ───────────────────────────────────────────────────────────────
  Future<void> addParty({required String name, required String type, required double openingBal}) async {
    final party = Party(
      id: _uuid.v4(),
      name: name.trim(),
      type: type,
      openingBal: openingBal,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _db.insertParty(party);
    _parties = [party, ..._parties];
    notifyListeners();
    await _afterMutation();
  }

  Future<void> updateParty(String id, {required String name, required String type, required double openingBal}) async {
    final idx = _parties.indexWhere((p) => p.id == id);
    if (idx < 0) return;
    final updated = _parties[idx].copyWith(name: name.trim(), type: type, openingBal: openingBal);
    await _db.updateParty(updated);
    _parties = [..._parties.sublist(0, idx), updated, ..._parties.sublist(idx + 1)];
    notifyListeners();
    await _afterMutation();
  }

  Future<void> deleteParty(String id) async {
    await _db.deleteParty(id);
    _parties = _parties.where((p) => p.id != id).toList();
    _transactions = _transactions.where((t) => t.partyId != id).toList();
    notifyListeners();
    await _afterMutation();
  }

  // ── Inventory ─────────────────────────────────────────────────────────────
  Future<void> addItem({required String name, required String unit, required double openingQty}) async {
    final item = StockItem(
      id: _uuid.v4(),
      name: name.trim(),
      unit: unit.trim().isEmpty ? 'Pcs' : unit.trim(),
      currentQty: openingQty,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _db.insertStockItem(item);
    _inventory = [item, ..._inventory];
    notifyListeners();
    await _afterMutation();
  }

  Future<void> updateItem(String id, {required String name, required String unit, required double currentQty}) async {
    final idx = _inventory.indexWhere((i) => i.id == id);
    if (idx < 0) return;
    final updated = _inventory[idx].copyWith(
      name: name.trim(),
      unit: unit.trim().isEmpty ? 'Pcs' : unit.trim(),
      currentQty: currentQty,
    );
    await _db.updateStockItem(updated);
    _inventory = [..._inventory.sublist(0, idx), updated, ..._inventory.sublist(idx + 1)];
    notifyListeners();
    await _afterMutation();
  }

  Future<void> deleteItem(String id) async {
    await _db.deleteStockItem(id);
    _inventory = _inventory.where((i) => i.id != id).toList();
    notifyListeners();
    await _afterMutation();
  }

  // ── Transactions ──────────────────────────────────────────────────────────
  Future<void> addTransaction({
    required String partyId,
    String? itemId,
    required double qty,
    required double rate,
    required String type,
    required String remarks,
    DateTime? date,
  }) async {
    final isMoneyOnly = type == 'Receipt' || type == 'Payment';
    final total = isMoneyOnly ? rate : qty * rate;
    final tx = Transaction(
      id: _uuid.v4(),
      partyId: partyId,
      itemId: isMoneyOnly ? null : itemId,
      qty: isMoneyOnly ? 0 : qty,
      rate: rate,
      total: total,
      type: type,
      date: formatDate(date ?? DateTime.now()),
      remarks: remarks.trim(),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _db.insertTransaction(tx);
    _transactions = [tx, ..._transactions];

    if (itemId != null && (type == 'Sale' || type == 'Purchase')) {
      final delta = type == 'Sale' ? -qty : qty;
      final idx = _inventory.indexWhere((i) => i.id == itemId);
      if (idx >= 0) {
        final updated = _inventory[idx].copyWith(currentQty: _inventory[idx].currentQty + delta);
        await _db.updateStockItem(updated);
        _inventory = [..._inventory.sublist(0, idx), updated, ..._inventory.sublist(idx + 1)];
      }
    }
    notifyListeners();
    await _afterMutation();
  }

  Future<void> updateTransaction(
    String id, {
    required String partyId,
    String? itemId,
    required double qty,
    required double rate,
    required String type,
    required String remarks,
    DateTime? date,
  }) async {
    final old = _transactions.firstWhere((t) => t.id == id, orElse: () => throw Exception('TX not found'));
    final isMoneyOnly = type == 'Receipt' || type == 'Payment';
    final newItemId = isMoneyOnly ? null : itemId;
    final newQty = isMoneyOnly ? 0.0 : qty;
    final newTotal = isMoneyOnly ? rate : qty * rate;

    final updated = Transaction(
      id: id,
      partyId: partyId,
      itemId: newItemId,
      qty: newQty,
      rate: rate,
      total: newTotal,
      type: type,
      date: date != null ? formatDate(date) : old.date,
      remarks: remarks.trim(),
      createdAt: old.createdAt,
    );

    await _db.updateTransaction(updated);
    final idx = _transactions.indexWhere((t) => t.id == id);
    _transactions = [..._transactions.sublist(0, idx), updated, ..._transactions.sublist(idx + 1)];

    final Map<String, double> deltas = {};
    if (old.itemId != null && (old.type == 'Sale' || old.type == 'Purchase')) {
      final reverse = old.type == 'Sale' ? old.qty : -old.qty;
      deltas[old.itemId!] = (deltas[old.itemId] ?? 0) + reverse;
    }
    if (newItemId != null && (type == 'Sale' || type == 'Purchase')) {
      final apply = type == 'Sale' ? -newQty : newQty;
      deltas[newItemId] = (deltas[newItemId] ?? 0) + apply;
    }
    if (deltas.isNotEmpty) {
      for (final entry in deltas.entries) {
        final iIdx = _inventory.indexWhere((i) => i.id == entry.key);
        if (iIdx >= 0) {
          final updatedItem = _inventory[iIdx].copyWith(currentQty: _inventory[iIdx].currentQty + entry.value);
          await _db.updateStockItem(updatedItem);
          _inventory = [..._inventory.sublist(0, iIdx), updatedItem, ..._inventory.sublist(iIdx + 1)];
        }
      }
    }
    notifyListeners();
    await _afterMutation();
  }

  Future<void> deleteTransaction(String id) async {
    final tx = _transactions.firstWhere((t) => t.id == id, orElse: () => throw Exception('TX not found'));
    await _db.deleteTransaction(id);
    _transactions = _transactions.where((t) => t.id != id).toList();
    if (tx.itemId != null && (tx.type == 'Sale' || tx.type == 'Purchase')) {
      final reverse = tx.type == 'Sale' ? tx.qty : -tx.qty;
      final idx = _inventory.indexWhere((i) => i.id == tx.itemId);
      if (idx >= 0) {
        final updatedItem = _inventory[idx].copyWith(currentQty: _inventory[idx].currentQty + reverse);
        await _db.updateStockItem(updatedItem);
        _inventory = [..._inventory.sublist(0, idx), updatedItem, ..._inventory.sublist(idx + 1)];
      }
    }
    notifyListeners();
    await _afterMutation();
  }

  Future<void> reload() async {
    _parties = await _db.getParties();
    _inventory = await _db.getStockItems();
    _transactions = await _db.getTransactions();
    notifyListeners();
  }

  Future<void> importFromSupabase(Map<String, dynamic> data) async {
    final parties = (data['parties'] as List).cast<Party>();
    final items = (data['stock_items'] as List).cast<StockItem>();
    final txs = (data['transactions'] as List).cast<Transaction>();
    final exportMap = {
      'version': 1,
      'parties': parties.map((p) => p.toMap()).toList(),
      'stock_items': items.map((i) => i.toMap()).toList(),
      'transactions': txs.map((t) => t.toMap()).toList(),
    };
    await _db.importData(exportMap);
  }

  Future<void> mergeFromSupabase(Map<String, dynamic> data) async {
    final parties = (data['parties'] as List).cast<Party>();
    final items = (data['stock_items'] as List).cast<StockItem>();
    final txs = (data['transactions'] as List).cast<Transaction>();
    final exportMap = {
      'version': 1,
      'parties': parties.map((p) => p.toMap()).toList(),
      'stock_items': items.map((i) => i.toMap()).toList(),
      'transactions': txs.map((t) => t.toMap()).toList(),
    };
    await _db.mergeData(exportMap);
  }
}
