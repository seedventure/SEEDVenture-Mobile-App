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
  /*MnemonicLogicBloc _mnemonicLogicBloc;
  JSONWalletLogicBloc _jsonWalletLogicBloc;
  ImportPrivateKeyLogicBloc _importPrivateKeyLogicBloc;
  ImportFromConfigFileBloc _importFromConfigFileBloc;*/

  PublishSubject _importStatusSubject = PublishSubject();

  PublishSubject<bool> _wrongPasswordSubject = PublishSubject<bool>();

  Stream get outImportStatus => _importStatusSubject.stream;
  Sink get _inImportStatus => _importStatusSubject.sink;

  Stream get outWrongPassword => _wrongPasswordSubject.stream;
  Sink get _inWrongPassword => _wrongPasswordSubject.sink;

  static const int fromJSONFile = 0;
  static const int fromPrivateKey = 1;
  static const int fromMnemonicWords = 2;
  static const int fromConfigFile = 3;

  int _currentImportMode;


  void dispose() {}

  dynamic getCurrentBloc() {
    switch (_currentImportMode) {
      case fromMnemonicWords:
        return mnemonicLogicBloc;
        break;
      case fromJSONFile:
        return jsonWalletLogicBloc;
        break;
      case fromPrivateKey:
        return importPrivateKeyLogicBloc;
        break;
      case fromConfigFile:
        return importFromConfigFileBloc;
        break;
    }
  }

  void setCurrentImportMode(int importMode) {
    this._currentImportMode = importMode;
  }

  Future import(String password) async {
    ConfigManagerBloc configManagerBloc = ConfigManagerBloc();

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

    print('address from json: ' + credentials.address.hex);

    await configManagerBloc.createConfiguration(credentials, password);

    mnemonicLogicBloc.closeSubjects();
    jsonWalletLogicBloc.closeSubjects();
    importPrivateKeyLogicBloc.closeSubjects();
    importFromConfigFileBloc.closeSubjects();

    _inImportStatus.add(true);
  }
}
