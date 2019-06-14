import 'package:rxdart/rxdart.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:web3dart/web3dart.dart';

final JSONWalletLogicBloc jsonWalletLogicBloc = JSONWalletLogicBloc();

class JSONWalletLogicBloc {
  PublishSubject<bool> _jsonFileSelection = PublishSubject<bool>();

  Stream<bool> get outJsonFileSelection => _jsonFileSelection.stream;
  Sink<bool> get _inJsonFileSelection => _jsonFileSelection.sink;

  String _walletFilePath;

  String getWalletFilePath() {
    return _walletFilePath;
  }

  void selectWalletFile() async {
    try {
      String filePath = await FilePicker.getFilePath(type: FileType.ANY);
      if (filePath == '' || filePath == null) {
        return null;
      }
      print("File path: " + filePath);

      File walletFile = File(filePath);

      String fileContent = walletFile.readAsStringSync();

      var json = jsonDecode(fileContent);

      if (json['crypto'] != null || json['Crypto'] != null) {
        this._walletFilePath = filePath;
        _inJsonFileSelection.add(true);
      } else {
        _inJsonFileSelection.add(false);
      }
    } on Exception {
      _inJsonFileSelection.add(false);
    }
  }

  static Credentials checkJSONPassword(List<String> params) {
    File walletFile = File(params[0]);
    String password = params[1];

    try {
      Wallet wallet = Wallet.fromJson(walletFile.readAsStringSync(), password);
      return wallet.credentials;
    } catch (e) {
      return null;
    }
  }

  void closeSubjects() {
    _jsonFileSelection.close();
  }

  void dispose() {}
}
