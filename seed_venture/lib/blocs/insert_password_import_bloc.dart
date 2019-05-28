import 'package:rxdart/rxdart.dart';
import 'package:seed_venture/blocs/bloc_provider.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:seed_venture/utils/mnemonic.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/conversions.dart';
import 'package:bip32/bip32.dart' as bip32;
import 'package:hex/hex.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:seed_venture/blocs/mnemonic_logic_bloc.dart';

class InsertPasswordImportBloc implements BlocBase {
  PublishSubject wrongPasswordSubject = PublishSubject();

  static const int fromJSONFile = 0;
  static const int fromPrivateKey = 1;
  static const int fromMnemonicWords = 2;

  final int importMode;
  final Credentials credentials;
  final String privateKey;
  final String jsonPath;
  final String mnemonic;

  InsertPasswordImportBloc({this.importMode, this.credentials, this.privateKey, this.jsonPath, this.mnemonic});

  Future import(String password) async {
    switch(importMode){
      case fromJSONFile:
        List<String> checkPasswordParams = List(2);
        checkPasswordParams[0] = jsonPath;
        checkPasswordParams[1] = password;
        Credentials credentials = await compute(checkPasswordFromJson, checkPasswordParams); // uso la password di sblocco del json anche per cifrare il file di configuration

        if(credentials == null){
          wrongPasswordSubject.add("wrong_pass");
        }
        else{
          print('address from json: ' + credentials.address.hex);
        }
        break;
      case fromPrivateKey:
        Credentials credentials = Credentials.fromPrivateKeyHex(privateKey);
        print('address from raw priv key; ' + credentials.address.hex);
        break;
      case fromMnemonicWords:
        final MnemonicLogicBloc mnemonicLogicBloc = MnemonicLogicBloc();
        Credentials credentials = await mnemonicLogicBloc.deriveKeysFromMnemonic(mnemonic, password);
        print('address from credentials: ' + credentials.address.hex);
        break;

    }
  }

  static Credentials checkPasswordFromJson(List<String> params) {
    File walletFile = File(params[0]);
    String password = params[1];

    try {
      Wallet wallet = Wallet.fromJson(walletFile.readAsStringSync(), password);
      return wallet.credentials;
    } catch (e) {

      return null;
    }
  }

  void dispose() {
    wrongPasswordSubject.close();
  }
}
