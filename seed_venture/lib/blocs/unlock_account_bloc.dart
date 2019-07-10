import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'dart:convert';

final UnlockAccountBloc unlockAccountBloc = UnlockAccountBloc();

class UnlockAccountBloc {
  String _hashPass;

  PublishSubject<bool> _passwordCheck = PublishSubject<bool>();

  Stream get outPasswordCheck => _passwordCheck.stream;
  Sink get _inPasswordCheck => _passwordCheck.sink;


  UnlockAccountBloc() {
    SharedPreferences.getInstance().then((prefs){
      this._hashPass = prefs.getString('sha256_pass');
    });
  }

  void isPasswordCorrect(String password){
    if(crypto.sha256
        .convert(utf8.encode(password)).toString() == _hashPass){
      _inPasswordCheck.add(true);
    }
    else{
      _inPasswordCheck.add(false);
    }
  }
}