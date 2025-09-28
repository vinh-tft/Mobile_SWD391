import 'package:flutter/material.dart';

class AppProvider extends ChangeNotifier {
  bool _isLoading = false;
  String _selectedLanguage = 'en';
  bool _isDarkMode = false;

  // Getters
  bool get isLoading => _isLoading;
  String get selectedLanguage => _selectedLanguage;
  bool get isDarkMode => _isDarkMode;

  // Methods
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setLanguage(String language) {
    _selectedLanguage = language;
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  // Navigation methods
  void navigateToMarketplace() {
    // TODO: Implement navigation
    print('Navigate to Marketplace');
  }

  void navigateToAbout() {
    // TODO: Implement navigation
    print('Navigate to About');
  }

  void navigateToContact() {
    // TODO: Implement navigation
    print('Navigate to Contact');
  }

  void navigateToLogin() {
    // TODO: Implement navigation
    print('Navigate to Login');
  }
}
