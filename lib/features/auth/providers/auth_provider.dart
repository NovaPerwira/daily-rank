import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:life_rank/core/models/user_models.dart';
import 'package:life_rank/core/services/supabase_service.dart';
import 'package:life_rank/core/services/user_stats_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  User? _supabaseUser;
  UserProfile? _profile;
  UserStats? _stats;
  String? _errorMessage;

  AuthStatus get status => _status;
  User? get supabaseUser => _supabaseUser;
  UserProfile? get profile => _profile;
  UserStats? get stats => _stats;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _init();
  }

  void _init() {
    if (UserStatsService.useMock) {
      _status = AuthStatus.authenticated;
      _loadUserData();
      return;
    }

    _supabaseUser = SupabaseService.client.auth.currentUser;
    if (_supabaseUser != null) {
      _status = AuthStatus.authenticated;
      _loadUserData();
    } else {
      _status = AuthStatus.unauthenticated;
    }

    SupabaseService.client.auth.onAuthStateChange.listen((event) {
      _supabaseUser = event.session?.user;
      if (_supabaseUser != null) {
        _status = AuthStatus.authenticated;
        _loadUserData();
      } else {
        _status = AuthStatus.unauthenticated;
        _profile = null;
        _stats = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserData() async {
    if (UserStatsService.useMock) {
      _profile = await UserStatsService.getProfile('mock-user-id');
      _stats = await UserStatsService.getUserStats('mock-user-id');
      notifyListeners();
      return;
    }

    if (_supabaseUser == null) return;
    _profile = await UserStatsService.getProfile(_supabaseUser!.id);
    _stats = await UserStatsService.getUserStats(_supabaseUser!.id);
    notifyListeners();
  }

  Future<void> refreshStats() async {
    if (UserStatsService.useMock) {
      _stats = await UserStatsService.getUserStats('mock-user-id');
      notifyListeners();
      return;
    }

    if (_supabaseUser == null) return;
    _stats = await UserStatsService.getUserStats(_supabaseUser!.id);
    notifyListeners();
  }

  Future<bool> register({
    required String email,
    required String password,
    required String username,
  }) async {
    if (UserStatsService.useMock) {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 500));
      await UserStatsService.createProfile('mock-user-id', username);
      await UserStatsService.createUserStats('mock-user-id');
      await _loadUserData();
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    }

    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final response = await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await UserStatsService.createProfile(response.user!.id, username);
        await UserStatsService.createUserStats(response.user!.id);
        await _loadUserData();
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    if (UserStatsService.useMock) {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 500));
      await _loadUserData();
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    }

    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    if (UserStatsService.useMock) {
      _profile = null;
      _stats = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    await SupabaseService.client.auth.signOut();
    _profile = null;
    _stats = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> updateStats(UserStats newStats) async {
    _stats = newStats;
    notifyListeners();
  }
}
