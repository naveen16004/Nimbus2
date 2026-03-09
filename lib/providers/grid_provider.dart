import 'package:flutter/material.dart';

class GridProvider extends ChangeNotifier {
  int _columns = 3; // Default starting grid (3x4 style)

  int get columns => _columns;

  // Your 4 flexible types
  void setGridType(int type) {
    switch (type) {
      case 1: _columns = 2; break; // Extra Large
      case 2: _columns = 3; break; // Standard
      case 3: _columns = 4; break; // Compact
      case 4: _columns = 5; break; // Micro
    }
    notifyListeners(); // This triggers the UI rebuild across the app
  }
}