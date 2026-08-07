import 'package:flutter/foundation.dart';

class MainNavNotifier extends ChangeNotifier {
  int _index = 0;

  int get index => _index;

  void goTo(int index) {
    if (_index == index) return;
    _index = index;
    notifyListeners();
  }
}
