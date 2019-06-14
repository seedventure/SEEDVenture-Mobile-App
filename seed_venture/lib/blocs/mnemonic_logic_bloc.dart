import 'package:rxdart/rxdart.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:seed_venture/utils/mnemonic.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/conversions.dart';
import 'package:bip32/bip32.dart' as bip32;
import 'package:hex/hex.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:seed_venture/blocs/config_manager_bloc.dart';

final mnemonicLogicBloc = MnemonicLogicBloc();

class MnemonicLogicBloc {
  BehaviorSubject<String> _randomMnemonicSubject = BehaviorSubject<String>();
  PublishSubject<bool> _checkMnemonicSubject = PublishSubject<bool>();
  PublishSubject<bool> _onDoneCreateConfigurationFromMnemonic =
      PublishSubject<bool>();
  PublishSubject<String> _setCustomMnemonic = PublishSubject<String>();

  Stream<String> get outRandomMnemonic => _randomMnemonicSubject.stream;
  Sink<String> get _inRandomMnemonic => _randomMnemonicSubject.sink;

  Stream<bool> get outCheckMnemonic => _checkMnemonicSubject.stream;
  Sink<bool> get _inCheckMnemonic => _checkMnemonicSubject.sink;

  Stream<bool> get outOnDoneCreateConfigurationFromMnemonic =>
      _onDoneCreateConfigurationFromMnemonic.stream;
  Sink<bool> get _inOnDoneCreateConfigurationFromMnemonic =>
      _onDoneCreateConfigurationFromMnemonic.sink;

  Stream<String> get outSetCustomMnemonic => _setCustomMnemonic.stream;
  Sink<String> get inSetCustomMnemonic => _setCustomMnemonic.sink;

  String _lastMnemonic;

  MnemonicLogicBloc() {
    this._lastMnemonic = _getRandomMnemonic();
    _inRandomMnemonic.add(_lastMnemonic);

    outSetCustomMnemonic.listen((mnemonic) {
      this._lastMnemonic = mnemonic;
    });
  }

  String getCurrentMnemonic() {
    return _lastMnemonic;
  }

  String _getRandomMnemonic() {
    String randomMnemonic = bip39.generateMnemonic();
    print('Random Mnemonic: ' + randomMnemonic);
    return randomMnemonic;
  }

  void isMnemonicCorrect(String typedMnemonic) {
    if (typedMnemonic == _lastMnemonic)
      _inCheckMnemonic.add(true);
    else
      _inCheckMnemonic.add(false);
  }

  static void copyMnemonicToClipboard(String mnemonic) {
    Clipboard.setData(new ClipboardData(text: mnemonic));
  }

  Future<Credentials> deriveKeysFromMnemonic(String password) async {
    ConfigManagerBloc configManagerBloc = ConfigManagerBloc();
    List deriveCredentialsParams = List(2);
    deriveCredentialsParams[0] = _lastMnemonic;
    deriveCredentialsParams[1] = password;

    Credentials credentials =
        await compute(deriveCredentials, deriveCredentialsParams);

    await configManagerBloc.createConfiguration(credentials, password);


    _inOnDoneCreateConfigurationFromMnemonic.add(true);

    closeSubjects();

    return credentials;
  }

  // params[0] => mnemonic
  // params[1] => password
  static Credentials deriveCredentials(List params) {
    String mnemonic = params[0];
    String password = params[1];
    var masterSeed = MnemonicUtils.generateMasterSeed(mnemonic, password);
    var masterSeedHex = bytesToHex(masterSeed);
    bip32.BIP32 root = bip32.BIP32.fromSeed(HEX.decode(masterSeedHex));
    bip32.BIP32 child = root.derivePath("m/44'/60'/0'/0/0");
    String privateKey = HEX.encode(child.privateKey);
    privateKey = '0x' + privateKey;
    Credentials credentials = Credentials.fromPrivateKeyHex(privateKey);
    return credentials;
  }

  void closeSubjects() {
    _randomMnemonicSubject.close();
    _checkMnemonicSubject.close();
    _onDoneCreateConfigurationFromMnemonic.close();
    _setCustomMnemonic.close();
  }
}
