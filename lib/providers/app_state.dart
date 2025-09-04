import 'package:flutter/foundation.dart';

class AppState extends ChangeNotifier {
  int _currentTab = 0;
  bool _isOnline = true;

  int get currentTab => _currentTab;
  bool get isOnline => _isOnline;

  void setCurrentTab(int index) {
    _currentTab = index;
    notifyListeners();
  }

  void setOnlineStatus(bool status) {
    _isOnline = status;
    notifyListeners();
  }
}