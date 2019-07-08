import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/services.dart';

final WalletInfoBloc walletInfoBloc = WalletInfoBloc();


class WalletInfoBloc {

  BehaviorSubject<String> _address = BehaviorSubject<String>();

  Stream<String> get outAddress =>
      _address.stream;
  Sink<String> get _inAddress =>
      _address.sink;


  WalletInfoBloc() {
   SharedPreferences.getInstance().then((prefs){
     _inAddress.add(prefs.getString('address'));
   });
  }

  static void copyAddressToClipboard(String address) {
    Clipboard.setData(new ClipboardData(text: address));
  }
}