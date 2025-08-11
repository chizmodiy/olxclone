import 'package:flutter/material.dart';

class ProfileNotifier extends ChangeNotifier {
  static final ProfileNotifier _instance = ProfileNotifier._internal();

  factory ProfileNotifier() {
    return _instance;
  }

  ProfileNotifier._internal();

  void notifyProfileUpdate() {
    notifyListeners();
  }
} 