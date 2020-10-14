import 'package:rxdart/rxdart.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:web3dart/web3dart.dart';

final ImportFromConfigFileBloc importFromConfigFileBloc =
    ImportFromConfigFileBloc();

class ImportFromConfigFileBloc {
  PublishSubject<bool> _configFileSelection = PublishSubject<bool>();

  Stream<bool> get outConfigFileSelection => _configFileSelection.stream;
  Sink<bool> get _inConfigFileSelection => _configFileSelection.sink;

  String _configFilePath;

  String getConfigFilePath() {
    return _configFilePath;
  }

  void dispose() {
    _configFileSelection.close();
  }

  void selectConfigFile() async {
    try {

      FilePickerResult result = await FilePicker.platform.pickFiles();
      String filePath;
      if (result != null) {
        filePath = result.files.single.path;
      } else
        return;

      if (filePath == '' || filePath == null) {
        return null;
      }
      //print("File path: " + filePath);

      File walletFile = File(filePath);

      String fileContent = walletFile.readAsStringSync();

      var json = jsonDecode(fileContent);

      if (json['user'] != null) {
        this._configFilePath = filePath;
        _inConfigFileSelection.add(true);
      } else {
        _inConfigFileSelection.add(false);
      }
    } on Exception {
      _inConfigFileSelection.add(false);
    }
  }

  static Future<Credentials> checkConfigFilePassword(List params) async {
    File configFile = File(params[0]);
    String password = params[1];

    Map encryptedConfigFileMap = jsonDecode(configFile.readAsStringSync());

    String encryptedData = encryptedConfigFileMap['user']['data'];

    var platform = MethodChannel('seedventure.io/aes');

    var decryptedData = await platform.invokeMethod('decrypt', {
      "encrypted": utf8.decode(base64.decode(encryptedData)),
      "realPass":
          crypto.md5.convert(utf8.encode(password)).toString().toUpperCase()
    });

    try {
      Map configJson = jsonDecode(decryptedData);
      Credentials credentials =
          Credentials.fromPrivateKeyHex(configJson['privateKey']);
      if (crypto.sha256
              .convert(utf8.encode(credentials.address.hex.toLowerCase()))
              .toString() ==
          encryptedConfigFileMap['user']['hash']) {
        return credentials;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
