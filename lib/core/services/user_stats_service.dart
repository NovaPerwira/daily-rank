import 'dart:io' if (dart.library.html) 'dart:html';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_models.dart';
import '../models/category_models.dart';
import '../constants/rank_config.dart';
import 'supabase_service.dart';

class UserStatsService {
  static SupabaseClient get _client => SupabaseService.client;

  static const bool useMock = false;

  static UserProfile? _mockProfile = UserProfile(
    id: 'mock-profile-id',
    userId: 'mock-user-id',
    username: 'Legendary Hero',
    avatarUrl: null,
    createdAt: DateTime.now(),
  );

  static UserStats? _mockStats = UserStats(
    id: 'mock-stats-id',
    userId: 'mock-user-id',
    financialXp: 1200,
    careerXp: 800,
    habitXp: 1500,
    knowledgeXp: 2200,
    healthXp: 900,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  static final List<QuestModel> _mockQuests = [];
  static final List<TransactionModel> _mockTransactions = [];
  static final List<CareerEntry> _mockCareerEntries = [];
  static final List<KnowledgeEntry> _mockKnowledgeEntries = [];
  static final List<HealthEntry> _mockHealthEntries = [];
  static final List<AchievementModel> _mockAchievements = [];

  // ── Profile ─────────────────────────────────────────────
  static Future<UserProfile?> getProfile(String userId) async {
    if (useMock) return _mockProfile;
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (data == null) return null;
      return UserProfile.fromJson(data);
    } catch (e) {
      debugPrint('Error getting profile: $e');
      return null;
    }
  }

  static Future<void> createProfile(String userId, String username) async {
    if (useMock) {
      _mockProfile = UserProfile(
        id: 'mock-profile-id',
        userId: userId,
        username: username,
        avatarUrl: null,
        createdAt: DateTime.now(),
      );
      return;
    }
    try {
      await _client.from('profiles').upsert(
        {'user_id': userId, 'username': username},
        onConflict: 'user_id',
        ignoreDuplicates: true,
      );
    } catch (e) {
      debugPrint('createProfile error (may already exist): $e');
    }
  }

  static Future<void> updateUsername(String userId, String username) async {
    if (useMock) {
      if (_mockProfile != null) {
        _mockProfile = UserProfile(
          id: _mockProfile!.id,
          userId: _mockProfile!.userId,
          username: username,
          avatarUrl: _mockProfile!.avatarUrl,
          createdAt: _mockProfile!.createdAt,
        );
      }
      return;
    }
    await _client
        .from('profiles')
        .update({'username': username})
        .eq('user_id', userId);
  }

  static Future<String?> uploadAvatar(String userId, dynamic imageFile) async {
    if (useMock) {
      const url = 'https://picsum.photos/200';
      if (_mockProfile != null) {
        _mockProfile = UserProfile(
          id: _mockProfile!.id,
          userId: _mockProfile!.userId,
          username: _mockProfile!.username,
          avatarUrl: url,
          createdAt: _mockProfile!.createdAt,
        );
      }
      return url;
    }
    try {
      final path = 'avatars/$userId.jpg';
      if (kIsWeb) {
        // On web, imageFile is XFile — read as bytes
        final xfile = imageFile as XFile;
        final bytes = await xfile.readAsBytes();
        await _client.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );
      } else {
        // On native, imageFile is dart:io File
        await _client.storage.from('avatars').upload(
          path,
          imageFile as File,
          fileOptions: const FileOptions(upsert: true),
        );
      }
      final url = _client.storage.from('avatars').getPublicUrl(path);
      await _client
          .from('profiles')
          .update({'avatar_url': url})
          .eq('user_id', userId);
      return url;
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      return null;
    }
  }

  // ── User Stats ────────────────────────────────────────────
  static Future<UserStats?> getUserStats(String userId) async {
    if (useMock) return _mockStats;
    try {
      final data = await _client
          .from('user_stats')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (data == null) return null;
      return UserStats.fromJson(data);
    } catch (e) {
      debugPrint('Error getting user stats: $e');
      return null;
    }
  }

  static Future<void> createUserStats(String userId) async {
    if (useMock) {
      _mockStats = UserStats(
        id: 'mock-stats-id',
        userId: userId,
        financialXp: 0,
        careerXp: 0,
        habitXp: 0,
        knowledgeXp: 0,
        healthXp: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      return;
    }
    try {
      await _client.from('user_stats').upsert(
        {
          'user_id': userId,
          'financial_xp': 0,
          'career_xp': 0,
          'habit_xp': 0,
          'knowledge_xp': 0,
          'health_xp': 0,
        },
        onConflict: 'user_id',
        ignoreDuplicates: true,
      );
    } catch (e) {
      debugPrint('createUserStats error (may already exist): $e');
    }
  }

  static Future<UserStats?> updateCategoryXp(
    String userId,
    String category,
    int xpToAdd,
  ) async {
    if (useMock) {
      if (_mockStats == null) return null;
      int financialXp = _mockStats!.financialXp;
      int careerXp = _mockStats!.careerXp;
      int habitXp = _mockStats!.habitXp;
      int knowledgeXp = _mockStats!.knowledgeXp;
      int healthXp = _mockStats!.healthXp;

      switch (category) {
        case 'financial':
          financialXp += xpToAdd;
          break;
        case 'career':
          careerXp += xpToAdd;
          break;
        case 'habit':
          habitXp += xpToAdd;
          break;
        case 'knowledge':
          knowledgeXp += xpToAdd;
          break;
        case 'health':
          healthXp += xpToAdd;
          break;
      }

      _mockStats = UserStats(
        id: _mockStats!.id,
        userId: _mockStats!.userId,
        financialXp: financialXp,
        careerXp: careerXp,
        habitXp: habitXp,
        knowledgeXp: knowledgeXp,
        healthXp: healthXp,
        createdAt: _mockStats!.createdAt,
        updatedAt: DateTime.now(),
      );
      return _mockStats;
    }

    try {
      final current = await getUserStats(userId);
      if (current == null) return null;

      final Map<String, dynamic> update = {'updated_at': DateTime.now().toIso8601String()};
      switch (category) {
        case 'financial':
          update['financial_xp'] = current.financialXp + xpToAdd;
          break;
        case 'career':
          update['career_xp'] = current.careerXp + xpToAdd;
          break;
        case 'habit':
          update['habit_xp'] = current.habitXp + xpToAdd;
          break;
        case 'knowledge':
          update['knowledge_xp'] = current.knowledgeXp + xpToAdd;
          break;
        case 'health':
          update['health_xp'] = current.healthXp + xpToAdd;
          break;
      }

      final result = await _client
          .from('user_stats')
          .update(update)
          .eq('user_id', userId)
          .select()
          .single();

      return UserStats.fromJson(result);
    } catch (e) {
      debugPrint('Error updating XP: $e');
      return null;
    }
  }

  // ── Quests ─────────────────────────────────────────────────
  static Future<List<QuestModel>> getTodayQuests(String userId) async {
    if (useMock) {
      if (_mockQuests.isEmpty) {
        await seedDailyQuests(userId);
      }
      return _mockQuests;
    }
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final data = await _client
          .from('quests')
          .select()
          .eq('user_id', userId)
          .eq('date', today)
          .order('completed', ascending: true);
      return (data as List).map((e) => QuestModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error getting quests: $e');
      return [];
    }
  }

  static Future<void> seedDailyQuests(String userId) async {
    if (useMock) {
      if (_mockQuests.isNotEmpty) return;
      int idCounter = 1;
      for (final entry in RankConfig.habitXp.entries) {
        _mockQuests.add(QuestModel(
          id: 'mock-q-$idCounter',
          userId: userId,
          category: 'habit',
          title: entry.key,
          xpReward: entry.value,
          completed: false,
          date: DateTime.now(),
        ));
        idCounter++;
      }
      return;
    }
    final today = DateTime.now().toIso8601String().split('T')[0];
    // Check if already seeded
    final existing = await _client
        .from('quests')
        .select('id')
        .eq('user_id', userId)
        .eq('date', today)
        .limit(1);
    if ((existing as List).isNotEmpty) return;

    final defaultQuests = RankConfig.habitXp.entries.map((e) {
      return {
        'user_id': userId,
        'category': 'habit',
        'title': e.key,
        'xp_reward': e.value,
        'completed': false,
        'date': today,
      };
    }).toList();

    await _client.from('quests').insert(defaultQuests);
  }

  static Future<void> completeQuest(String questId) async {
    if (useMock) {
      final index = _mockQuests.indexWhere((q) => q.id == questId);
      if (index != -1) {
        _mockQuests[index] = _mockQuests[index].copyWith(completed: true);
      }
      return;
    }
    await _client
        .from('quests')
        .update({'completed': true})
        .eq('id', questId);
  }

  // ── Transactions ─────────────────────────────────────────────
  static Future<List<TransactionModel>> getTransactions(String userId) async {
    if (useMock) {
      if (_mockTransactions.isEmpty) {
        _mockTransactions.addAll([
          TransactionModel(
            id: 'mock-tx-1',
            userId: userId,
            type: 'income',
            amount: 15000000,
            category: 'Gaji Pokok',
            date: DateTime.now().subtract(const Duration(days: 2)),
            incomeType: 'fixed',
          ),
          TransactionModel(
            id: 'mock-tx-1b',
            userId: userId,
            type: 'income',
            amount: 4000000,
            category: 'Freelance',
            date: DateTime.now().subtract(const Duration(days: 1)),
            incomeType: 'side',
          ),
          TransactionModel(
            id: 'mock-tx-2',
            userId: userId,
            type: 'expense',
            amount: 1500000,
            category: 'Belanja Bulanan',
            date: DateTime.now().subtract(const Duration(days: 1)),
          ),
          TransactionModel(
            id: 'mock-tx-3',
            userId: userId,
            type: 'saving',
            amount: 3000000,
            category: 'Dana Darurat',
            date: DateTime.now(),
          ),
          // Previous months for chart
          TransactionModel(
            id: 'mock-tx-4',
            userId: userId,
            type: 'saving',
            amount: 2500000,
            category: 'Dana Darurat',
            date: DateTime.now().subtract(const Duration(days: 35)),
          ),
          TransactionModel(
            id: 'mock-tx-5',
            userId: userId,
            type: 'saving',
            amount: 2000000,
            category: 'Dana Darurat',
            date: DateTime.now().subtract(const Duration(days: 65)),
          ),
          TransactionModel(
            id: 'mock-tx-6',
            userId: userId,
            type: 'saving',
            amount: 3500000,
            category: 'Tabungan Rumah',
            date: DateTime.now().subtract(const Duration(days: 95)),
          ),
          TransactionModel(
            id: 'mock-tx-7',
            userId: userId,
            type: 'saving',
            amount: 1500000,
            category: 'Dana Darurat',
            date: DateTime.now().subtract(const Duration(days: 125)),
          ),
          TransactionModel(
            id: 'mock-tx-8',
            userId: userId,
            type: 'saving',
            amount: 4000000,
            category: 'Tabungan Rumah',
            date: DateTime.now().subtract(const Duration(days: 155)),
          ),
        ]);
      }
      return _mockTransactions;
    }
    try {
      final data = await _client
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false)
          .limit(100); // show all recent transactions
      return (data as List).map((e) => TransactionModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error getting transactions: $e');
      return [];
    }
  }

  static Future<void> addTransaction(TransactionModel tx) async {
    if (useMock) {
      _mockTransactions.insert(0, tx);
      return;
    }
    await _client.from('transactions').insert(tx.toJson());
  }

  static Future<void> deleteTransaction(String txId) async {
    if (useMock) {
      _mockTransactions.removeWhere((t) => t.id == txId);
      return;
    }
    await _client.from('transactions').delete().eq('id', txId);
  }

  static Future<void> updateTransaction(TransactionModel tx) async {
    if (useMock) {
      final idx = _mockTransactions.indexWhere((t) => t.id == tx.id);
      if (idx != -1) _mockTransactions[idx] = tx;
      return;
    }
    try {
      await _client
          .from('transactions')
          .update(tx.toUpdateJson())
          .eq('id', tx.id);
    } catch (e) {
      debugPrint('Error updating transaction: $e');
      rethrow;
    }
  }

  // ── Monthly Savings History (for chart) ──────────────────────────────────
  /// Returns a list of {month: DateTime, amount: double} for last 6 months
  static Future<List<Map<String, dynamic>>> getMonthlySavingsHistory(
      String userId, {List<TransactionModel>? preloadedTxs}) async {
    final txs = preloadedTxs ?? (useMock
        ? _mockTransactions
        : await getTransactions(userId));

    final now = DateTime.now();
    final result = <Map<String, dynamic>>[];
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final total = txs
          .where((t) =>
              (t.type == 'saving' || t.type == 'investment') &&
              t.date.month == month.month &&
              t.date.year == month.year)
          .fold(0.0, (sum, t) => sum + t.amount);
      result.add({'month': month, 'amount': total});
    }
    return result;
  }

  // ── Monthly Streak (active days with any transaction) ────────────────────
  /// Returns set of day numbers that have at least 1 transaction this month
  static Future<Set<int>> getMonthlyActivedays(
      String userId, {List<TransactionModel>? preloadedTxs}) async {
    final txs = preloadedTxs ?? (useMock
        ? _mockTransactions
        : await getTransactions(userId));

    final now = DateTime.now();
    return txs
        .where((t) => t.date.month == now.month && t.date.year == now.year)
        .map((t) => t.date.day)
        .toSet();
  }

  // ── Career Entries ─────────────────────────────────────────────
  static Future<List<CareerEntry>> getCareerEntries(String userId) async {
    if (useMock) {
      if (_mockCareerEntries.isEmpty) {
        _mockCareerEntries.addAll([
          CareerEntry(
            id: 'mock-cr-1',
            userId: userId,
            type: 'skill',
            title: 'Flutter',
            xpEarned: 400,
            addedAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
          CareerEntry(
            id: 'mock-cr-2',
            userId: userId,
            type: 'project',
            title: 'SaaS Dashboard',
            xpEarned: 2000,
            addedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ]);
      }
      return _mockCareerEntries;
    }
    try {
      final data = await _client
          .from('career_entries')
          .select()
          .eq('user_id', userId)
          .order('added_at', ascending: false);
      return (data as List).map((e) => CareerEntry.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error getting career entries: $e');
      return [];
    }
  }

  static Future<void> addCareerEntry(CareerEntry entry) async {
    if (useMock) {
      _mockCareerEntries.insert(0, entry);
      return;
    }
    await _client.from('career_entries').insert(entry.toJson());
  }

  // ── Knowledge Entries ─────────────────────────────────────────────
  static Future<List<KnowledgeEntry>> getKnowledgeEntries(
      String userId) async {
    if (useMock) {
      if (_mockKnowledgeEntries.isEmpty) {
        _mockKnowledgeEntries.addAll([
          KnowledgeEntry(
            id: 'mock-kn-1',
            userId: userId,
            type: 'book',
            title: 'Clean Code',
            xpEarned: 100,
            addedAt: DateTime.now().subtract(const Duration(days: 4)),
          ),
          KnowledgeEntry(
            id: 'mock-kn-2',
            userId: userId,
            type: 'online course',
            title: 'Supabase Mastery',
            xpEarned: 300,
            addedAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ]);
      }
      return _mockKnowledgeEntries;
    }
    try {
      final data = await _client
          .from('knowledge_entries')
          .select()
          .eq('user_id', userId)
          .order('added_at', ascending: false);
      return (data as List).map((e) => KnowledgeEntry.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error getting knowledge entries: $e');
      return [];
    }
  }

  static Future<void> addKnowledgeEntry(KnowledgeEntry entry) async {
    if (useMock) {
      _mockKnowledgeEntries.insert(0, entry);
      return;
    }
    await _client.from('knowledge_entries').insert(entry.toJson());
  }

  // ── Health Entries ─────────────────────────────────────────────
  static Future<List<HealthEntry>> getHealthEntries(String userId) async {
    if (useMock) {
      if (_mockHealthEntries.isEmpty) {
        _mockHealthEntries.addAll([
          HealthEntry(
            id: 'mock-he-1',
            userId: userId,
            type: 'workout',
            note: 'Morning Jogging',
            xpEarned: 20,
            date: DateTime.now().subtract(const Duration(days: 2)),
          ),
          HealthEntry(
            id: 'mock-he-2',
            userId: userId,
            type: 'weight',
            note: 'Weight Log',
            value: 72.5,
            xpEarned: 50,
            date: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ]);
      }
      return _mockHealthEntries;
    }
    try {
      final data = await _client
          .from('health_entries')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false)
          .limit(30);
      return (data as List).map((e) => HealthEntry.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error getting health entries: $e');
      return [];
    }
  }

  static Future<void> addHealthEntry(HealthEntry entry) async {
    if (useMock) {
      _mockHealthEntries.insert(0, entry);
      return;
    }
    await _client.from('health_entries').insert(entry.toJson());
  }

  // ── Achievements ──────────────────────────────────────────────
  static Future<List<AchievementModel>> getAchievements(String userId) async {
    if (useMock) {
      if (_mockAchievements.isEmpty) {
        _mockAchievements.addAll([
          AchievementModel(
            id: 'mock-ac-1',
            userId: userId,
            title: 'First Step',
            description: 'Start your journey in Life Rank',
            xpReward: 100,
            unlockedAt: DateTime.now().subtract(const Duration(days: 6)),
          ),
          AchievementModel(
            id: 'mock-ac-2',
            userId: userId,
            title: 'Financial Aware',
            description: 'Add your first transaction',
            xpReward: 150,
            unlockedAt: DateTime.now().subtract(const Duration(days: 3)),
          ),
        ]);
      }
      return _mockAchievements;
    }
    try {
      final data = await _client
          .from('achievements')
          .select()
          .eq('user_id', userId)
          .order('unlocked_at', ascending: false);
      return (data as List)
          .map((e) => AchievementModel.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('Error getting achievements: $e');
      return [];
    }
  }

  static Future<void> unlockAchievement({
    required String userId,
    required String title,
    required String description,
    required int xpReward,
  }) async {
    if (useMock) {
      _mockAchievements.insert(
        0,
        AchievementModel(
          id: 'mock-ac-${_mockAchievements.length + 1}',
          userId: userId,
          title: title,
          description: description,
          xpReward: xpReward,
          unlockedAt: DateTime.now(),
        ),
      );
      return;
    }
    await _client.from('achievements').insert({
      'user_id': userId,
      'title': title,
      'description': description,
      'xp_reward': xpReward,
    });
  }

  // ── Net Worth Entries ─────────────────────────────────────────────
  static Future<NetWorthEntry?> getLatestNetWorth(String userId) async {
    if (useMock) return null;
    try {
      final data = await _client
          .from('v_net_worth_current')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (data == null) return null;
      return NetWorthEntry.fromJson(data);
    } catch (e) {
      debugPrint('Error getting latest net worth: $e');
      return null;
    }
  }

  static Future<void> addNetWorthEntry(NetWorthEntry entry) async {
    if (useMock) return;
    await _client.from('net_worth_entries').insert(entry.toJson());
  }

  static Future<void> deleteNetWorthEntries(String userId) async {
     if (useMock) return;
     await _client.from('net_worth_entries').delete().eq('user_id', userId);
  }

  // ── Financial Todos ───────────────────────────────────────────────
  static Future<List<FinancialTodo>> getTodayFinancialTodos(String userId) async {
    if (useMock) return [];
    try {
      // First ensure seeded
      await _client.rpc('seed_daily_financial_todos', params: {'p_user_id': userId});

      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // Get today's preset todos OR custom todos
      final data = await _client
          .from('financial_todos')
          .select()
          .eq('user_id', userId)
          .or('todo_date.eq.$today,todo_type.eq.custom')
          .order('completed', ascending: true)
          .order('created_at', ascending: false);
          
      return (data as List).map((e) => FinancialTodo.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error getting financial todos: $e');
      return [];
    }
  }

  static Future<void> completeFinancialTodo(String todoId) async {
    if (useMock) return;
    await _client.from('financial_todos').update({
      'completed': true,
      'completed_at': DateTime.now().toIso8601String()
    }).eq('id', todoId);
  }

  static Future<void> addCustomFinancialTodo(FinancialTodo todo) async {
    if (useMock) return;
    final json = todo.toJson();
    // Supabase will generate the uuid and updated_at
    json.remove('id');
    json.remove('todo_date'); // Custom has no date
    await _client.from('financial_todos').insert(json);
  }

  static Future<void> deleteFinancialTodo(String todoId) async {
    if (useMock) return;
    await _client.from('financial_todos').delete().eq('id', todoId);
  }
}
