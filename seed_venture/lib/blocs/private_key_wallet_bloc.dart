import 'package:rxdart/rxdart.dart';
import 'package:seed_venture/blocs/bloc_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:web3dart/web3dart.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';

class PrivateKeyWalletBloc implements BlocBase {
  PublishSubject subject = PublishSubject();

  Future<void> importWalletFromRawPrivKey(
      String walletName, String password, String privateKeyHex) async {
    Credentials credentials = Credentials.fromPrivateKeyHex(privateKeyHex);
    String address = credentials.address.hex;
    print('address from private key: ' + address);
    /*final documentDirectory = await getApplicationDocumentsDirectory();
    String documentPath = documentDirectory.path;
    String importedWalletPath = "$documentPath/wallets/$address";
    var random = new Random.secure();
    Wallet newWallet = Wallet.createNew(credentials, password, random);
    String jsonV3 = await compute(toJson, newWallet);

    File walletFile = new File(importedWalletPath);
    walletFile.writeAsStringSync(jsonV3);*/


  }

  void dispose() {
    subject.close();
  }
}
