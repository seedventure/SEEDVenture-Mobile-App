import 'package:flutter/material.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:seed_venture/utils/mnemonic.dart';
import 'package:seed_venture/utils/hdkey.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/conversions.dart';
import 'package:bitcoin_bip44/bitcoin_bip44.dart';
import 'package:bip32/bip32.dart' as bip32;
import 'package:hex/hex.dart';




class OnBoardingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('On Boarding'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(bottom: 50.0),
            child: Row(
              children: <Widget>[
                Expanded(
                    child: Container(
                        height: 20.0,
                        child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text(
                                'Create/Import a configuration or continue to view all the baskets...'))))
              ],
            ),
          ),
          RaisedButton(
            onPressed: () {
              String randomMnemonic = bip39.generateMnemonic();
              print(randomMnemonic);

              String seed = bip39.mnemonicToSeedHex(randomMnemonic);
              print(seed);

              var masterSeed = MnemonicUtils.generateMasterSeed(
                  randomMnemonic,
                  "password");

              var masterSeedHex = bytesToHex(masterSeed);

              print('master seed hex with password: ' + masterSeedHex);

              /*var rootSeed = getRootSeed(hexToBytes(
                  masterSeedHex));


              var childPrivateKeyHardened = CKDprivHardened(
                rootSeed,
                0,
              )[0];

              var childChainCode = CKDprivHardened(
                rootSeed,
                0,
              )[1];

              var cprivkHardHex = bytesToHex(childPrivateKeyHardened);
              var publicKey = Credentials
                  .fromPrivateKeyHex(cprivkHardHex)
                  .publicKey
                  .toRadixString(16);
              var address = Credentials.fromPrivateKeyHex(cprivkHardHex).address.hex;

              print('address -> ' + address);*/

              //bip32.BIP32 root = bip32.BIP32.fromSeed(HEX.decode(seed));

              bip32.BIP32 root = bip32.BIP32.fromSeed(HEX.decode(masterSeedHex));

              bip32.BIP32 child = root.derivePath("m/44'/60'/0'/0/0");
              String privateKey = HEX.encode(child.privateKey);

              print('private key: ' + privateKey);

              privateKey = '0x' + privateKey;

              String address = Credentials.fromPrivateKeyHex(privateKey).address.hex;

              print('address: ' + address);









              /*var rootSeed = getRootSeed(hexToBytes(
                  masterSeedHex));


              var childPrivateKeyHardened = CKDprivNonHardened(
                rootSeed,
                0,
              )[0];

              var childChainCode = CKDprivNonHardened(
                rootSeed,
                0,
              )[1];

              var cprivkHardHex = bytesToHex(childPrivateKeyHardened);
              var publicKey = Credentials
                  .fromPrivateKeyHex(cprivkHardHex)
                  .publicKey
                  .toRadixString(16);
              var address = Credentials.fromPrivateKeyHex(cprivkHardHex).address.hex;

              print('address -> ' + address);
*/

            },
            child: Text(
              'Create Config',
              style: TextStyle(color: Colors.white),
            ),
          ),
          RaisedButton(
            onPressed: () => print('ciao'),
            child: Text('Import Config', style: TextStyle(color: Colors.white)),
          ),
          Container(
              margin: const EdgeInsets.only(top: 25.0),
              child: RaisedButton(
                color: Theme.of(context).accentColor,
                onPressed: () => print('ciao'),
                child: Text('Continue without Config',
                    style: TextStyle(color: Colors.white)),
              ))
        ],
      ),
    );
  }
}
