import 'package:seed_venture/blocs/mnemonic_logic_bloc.dart';
import 'package:seed_venture/blocs/json_wallet_logic_bloc.dart';
import 'package:seed_venture/blocs/import_from_private_key_logic_bloc.dart';
import 'package:seed_venture/blocs/config_manager_bloc.dart';
import 'package:seed_venture/blocs/import_from_config_file_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:web3dart/web3dart.dart';
import 'package:rxdart/rxdart.dart';

final ImportLogicBloc importLogicBloc = ImportLogicBloc();

class ImportLogicBloc {
  PublishSubject _importStatusSubject = PublishSubject();

  Stream get outImportStatus => _importStatusSubject.stream;
  Sink get _inImportStatus => _importStatusSubject.sink;

  PublishSubject<bool> _wrongPasswordSubject = PublishSubject<bool>();

  Stream get outWrongPassword => _wrongPasswordSubject.stream;
  Sink get _inWrongPassword => _wrongPasswordSubject.sink;

  static const int fromJSONFile = 0;
  static const int fromPrivateKey = 1;
  static const int fromMnemonicWords = 2;
  static const int fromConfigFile = 3;

  int _currentImportMode;
  Credentials _credentials;
  String _password;

  void dispose() {
    _importStatusSubject.close();
    _wrongPasswordSubject.close();
  }

  void setCurrentImportMode(int importMode) {
    this._currentImportMode = importMode;
  }

  Future import(String password) async {
    Credentials credentials;

    switch (_currentImportMode) {
      case fromJSONFile:
        List<String> checkPasswordParams = List(2);
        checkPasswordParams[0] = jsonWalletLogicBloc.getWalletFilePath();
        checkPasswordParams[1] = password;
        credentials = await compute(
            JSONWalletLogicBloc.checkJSONPassword, checkPasswordParams);

        break;
      case fromPrivateKey:
        credentials = Credentials.fromPrivateKeyHex(
            importPrivateKeyLogicBloc.getCurrentPrivateKey());
        break;
      case fromMnemonicWords:
        List deriveCredentialsParams = List(2);
        deriveCredentialsParams[0] = mnemonicLogicBloc.getCurrentMnemonic();
        deriveCredentialsParams[1] = password;

        credentials = await compute(
            MnemonicLogicBloc.deriveCredentials, deriveCredentialsParams);

        break;
      case fromConfigFile:
        List importFromConfigFileParams = List(2);
        importFromConfigFileParams[0] =
            importFromConfigFileBloc.getConfigFilePath();
        importFromConfigFileParams[1] = password;

        credentials = await ImportFromConfigFileBloc.checkConfigFilePassword(
            importFromConfigFileParams);

        break;
    }

    if (credentials == null) {
      _inWrongPassword.add(true);
      return;
    }

    _inWrongPassword.add(false);

    _credentials = credentials;
    _password = password;
  }

  Future createConfigFromCredentials() async {
    if (_credentials != null && _password != null) {
      await configManagerBloc.createConfiguration(_credentials, _password);

      /* mnemonicLogicBloc.dispose();
      jsonWalletLogicBloc.dispose();
      importPrivateKeyLogicBloc.dispose();
      importFromConfigFileBloc.dispose(); */

      _inImportStatus.add(true);
    }
  }
}
