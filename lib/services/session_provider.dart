import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/store_model.dart';
import '../models/session_model.dart';
import '../models/payment_model.dart';
import '../models/receipt_model.dart';

class SessionProvider extends ChangeNotifier {
  UserModel? _currentUser;
  StoreModel? _currentStore;
  SessionModel? _currentSession;
  PaymentModel? _lastPayment;
  ReceiptModel? _lastReceipt;

  UserModel? get currentUser => _currentUser;
  StoreModel? get currentStore => _currentStore;
  SessionModel? get currentSession => _currentSession;
  PaymentModel? get lastPayment => _lastPayment;
  ReceiptModel? get lastReceipt => _lastReceipt;

  void setUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  void setStore(StoreModel store) {
    _currentStore = store;
    notifyListeners();
  }

  void setSession(SessionModel session) {
    _currentSession = session;
    notifyListeners();
  }

  void setPayment(PaymentModel payment) {
    _lastPayment = payment;
    notifyListeners();
  }

  void setReceipt(ReceiptModel receipt) {
    _lastReceipt = receipt;
    notifyListeners();
  }

  void clearSession() {
    _currentStore = null;
    _currentSession = null;
    _lastPayment = null;
    _lastReceipt = null;
    notifyListeners();
  }

  void clearAll() {
    _currentUser = null;
    clearSession();
  }
}
