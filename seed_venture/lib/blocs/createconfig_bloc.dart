import 'package:rxdart/rxdart.dart';
import 'package:seed_venture/blocs/bloc_provider.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:seed_venture/utils/mnemonic.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/conversions.dart';
import 'package:bip32/bip32.dart' as bip32;
import 'package:hex/hex.dart';
import 'package:flutter/services.dart';

class CreateConfigBloc implements BlocBase {
  BehaviorSubject subject = BehaviorSubject();

  void getRandomMnemonic() {

      String randomMnemonic = bip39.generateMnemonic();
      print(randomMnemonic);
      subject.add(randomMnemonic);

  }

  void copyMnemonicToClipboard(String mnemonic)  {
     Clipboard.setData(new ClipboardData(text: mnemonic));
  }

  CreateConfigBloc() {
    /*String randomMnemonic = bip39.generateMnemonic();
    print(randomMnemonic);

    subject.add(randomMnemonic);*/

    /*String seed = bip39.mnemonicToSeedHex(randomMnemonic);
    print(seed);

    var masterSeed = MnemonicUtils.generateMasterSeed(
        randomMnemonic,
        "password");

    var masterSeedHex = bytesToHex(masterSeed);

    print('master seed hex with password: ' + masterSeedHex);



    bip32.BIP32 root = bip32.BIP32.fromSeed(HEX.decode(masterSeedHex));

    bip32.BIP32 child = root.derivePath("m/44'/60'/0'/0/0");
    String privateKey = HEX.encode(child.privateKey);

    print('private key: ' + privateKey);

    privateKey = '0x' + privateKey;

    String address = Credentials.fromPrivateKeyHex(privateKey).address.hex;

    print('address: ' + address);*/
  }

  void dispose() {
    subject.close();
  }
}
