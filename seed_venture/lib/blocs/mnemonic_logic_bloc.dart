import 'package:rxdart/rxdart.dart';
import 'package:seed_venture/blocs/bloc_provider.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:seed_venture/utils/mnemonic.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/conversions.dart';
import 'package:bip32/bip32.dart' as bip32;
import 'package:hex/hex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class MnemonicLogicBloc implements BlocBase {
  PublishSubject subject = PublishSubject();

  void deriveKeysFromMnemonic(String mnemonic, String password) async {
    List deriveCredentialsParams = List(2);
    deriveCredentialsParams[0] = mnemonic;
    deriveCredentialsParams[1] = password;

    Credentials credentials =
        await compute(_deriveCredentials, deriveCredentialsParams);

    _saveJSONWalletFile(credentials, password);
  }

  void _saveJSONWalletFile(Credentials credentials, String password) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    String documentsPath = documentsDirectory.path;
    List createWalletParams = List(2);
    createWalletParams[0] = credentials;
    createWalletParams[1] = password;
    Wallet wallet = await compute(_createWallet, createWalletParams);
    String jsonV3 = await compute(_toJson, wallet);
    String address = wallet.credentials.address.hex;
    String walletPath = "$documentsPath/$address";
    File walletFile = new File(walletPath);
    walletFile.writeAsStringSync(jsonV3);
    _updateIntroPreferences();
    subject.add(true);
  }

  // params[0] => credentials
  // params[1] => password
  static Wallet _createWallet(List params) {
    Credentials credentials = params[0];
    String password = params[1];
    var random = new Random.secure();
    Wallet wallet = Wallet.createNew(credentials, password, random);
    return wallet;
  }

  static String _toJson(Wallet wallet) {
    return wallet.toJson();
  }

  // params[0] => mnemonic
  // params[1] => password
  static Credentials _deriveCredentials(List params) {
    String mnemonic = params[0];
    String password = params[1];

    String seed = bip39.mnemonicToSeedHex(mnemonic);
    print(seed);

    var masterSeed = MnemonicUtils.generateMasterSeed(mnemonic, password);

    var masterSeedHex = bytesToHex(masterSeed);

    print('master seed hex with password: ' + masterSeedHex);

    bip32.BIP32 root = bip32.BIP32.fromSeed(HEX.decode(masterSeedHex));

    bip32.BIP32 child = root.derivePath("m/44'/60'/0'/0/0");
    String privateKey = HEX.encode(child.privateKey);

    print('private key: ' + privateKey);

    privateKey = '0x' + privateKey;

    Credentials credentials = Credentials.fromPrivateKeyHex(privateKey);

    String address = credentials.address.hex;

    print('address: ' + address);

    return credentials;
  }

  void _updateIntroPreferences() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setBool('on_boarding_done', true);
  }

  void dispose() {
    subject.close();
  }
}
