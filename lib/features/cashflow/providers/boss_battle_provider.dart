import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:life_rank/core/models/fixed_bill_model.dart';
import 'package:life_rank/core/models/category_models.dart';
import 'package:life_rank/core/services/user_stats_service.dart';
import 'package:life_rank/features/auth/providers/auth_provider.dart';

class BossBattleProvider extends ChangeNotifier {
  List<FixedBill> _bosses = [];

  List<FixedBill> get bosses => _bosses;

  // Initialize with some dummy bosses for presentation
  BossBattleProvider() {
    _bosses = [
      FixedBill(
        id: const Uuid().v4(),
        name: 'Internet Provider',
        amount: 350000,
        dueDate: DateTime.now().add(const Duration(days: 3)),
      ),
      FixedBill(
        id: const Uuid().v4(),
        name: 'Listrik (PLN)',
        amount: 500000,
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        status: 'overdue',
      ),
    ];
    // Check initial penalties
    _applyBossAttacks();
  }

  void _applyBossAttacks() {
    bool changed = false;
    final now = DateTime.now();
    for (int i = 0; i < _bosses.length; i++) {
      if (_bosses[i].status == 'pending' && _bosses[i].dueDate.isBefore(now)) {
        _bosses[i].status = 'overdue';
        changed = true;
        // In a real app, this would also deduct HP or subtract daily money
      }
    }
    if (changed) notifyListeners();
  }

  Future<void> defeatBoss(FixedBill boss, AuthProvider auth) async {
    final user = auth.supabaseUser;
    if (user == null) return;

    // Create an expense transaction for paying the bill
    final transaction = TransactionModel(
      id: const Uuid().v4(),
      userId: user.id,
      amount: boss.amount,
      type: 'expense',
      date: DateTime.now(),
      category: 'Tagihan - ${boss.name}',
    );

    // Record the transaction
    await UserStatsService.addTransaction(transaction);

    // Give the user +150 Financial XP as a reward for defeating the boss
    await UserStatsService.updateCategoryXp(user.id, 'financial', 150);

    // Update state
    final index = _bosses.indexWhere((b) => b.id == boss.id);
    if (index != -1) {
      _bosses[index].status = 'defeated';
      notifyListeners();
    }
    
    // Refresh global stats so UI updates
    await auth.refreshStats();
  }
}
