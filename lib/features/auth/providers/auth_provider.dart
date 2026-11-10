import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider(this._repository) {
    // Không tự động đăng nhập - Khi khởi động ứng dụng sẽ yêu cầu vào màn hình Đăng ký / Đăng nhập trước
    _currentUser = null;
  }

  void switchDemoRole(String role) {
    if (role == 'staff') {
      _currentUser = const UserModel(
        id: 'usr_stf_008',
        phone: '0909000888',
        fullName: 'Lê Minh Trí (Barista)',
        role: 'staff',
        points: 0,
        membershipTier: 'Bronze',
        totalSpent: 0,
        avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80',
      );
    } else if (role == 'admin') {
      _currentUser = const UserModel(
        id: 'usr_adm_001',
        phone: '0999999999',
        fullName: 'Ban Quản Trị BrewPoint',
        role: 'admin',
        points: 0,
        membershipTier: 'Platinum',
        totalSpent: 0,
        avatarUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=400&q=80',
      );
    } else {
      _currentUser = const UserModel(
        id: 'usr_gold_001',
        phone: '0901234567',
        fullName: 'Nguyễn Văn An',
        role: 'customer',
        points: 350,
        membershipTier: 'Gold',
        totalSpent: 4200000.0,
        avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=400&q=80',
      );
    }
    notifyListeners();
  }

  void continueAsGuest() {
    _currentUser = const UserModel(
      id: 'guest',
      phone: '',
      fullName: 'Khách hàng',
      role: 'customer',
      points: 0,
      membershipTier: 'Bronze',
      totalSpent: 0,
    );
    notifyListeners();
  }

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null && !_currentUser!.isGuest;
  bool get isGuest => _currentUser == null || _currentUser!.isGuest;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> login(String phone, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _repository.loginWithPhone(phone, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String phone, String fullName, String password, [String? email]) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _repository.registerWithPhone(phone, fullName, password, email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void addPoints(int delta) {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      points: _currentUser!.points + delta,
    );
    notifyListeners();
  }

  void updatePointsAndTier(int points, String tier, double addedSpent) {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      points: points,
      membershipTier: tier,
      totalSpent: _currentUser!.totalSpent + addedSpent,
    );
    notifyListeners();
  }
  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _repository.loginWithGoogle();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String phone, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _repository.resetPassword(phone, newPassword);
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    _currentUser = null;
    notifyListeners();
  }
}
