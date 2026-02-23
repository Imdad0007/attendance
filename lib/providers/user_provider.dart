import 'package:flutter/foundation.dart';
import 'package:attendance/models/surveillant_model.dart';

class UserProvider extends ChangeNotifier {
  Surveillant? _user;

  Surveillant? get user => _user;

  void setUser(Surveillant user) {
    _user = user;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }
}
