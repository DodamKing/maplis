import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  bool _isPrototypeUser = false;

  User? get user => _user;
  bool get isPrototypeUser => _isPrototypeUser;

  void setUser(User user) {
    _user = user;
    _isPrototypeUser = false;
    notifyListeners();
  }

  void setPrototypeUser() {
    _user = null;
    _isPrototypeUser = true;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    _isPrototypeUser = false;
    notifyListeners();
  }
}