import 'package:rxdart/rxdart.dart';
import 'package:seed_venture/blocs/bloc_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';

class JSONWalletBloc implements BlocBase {
  PublishSubject subject = PublishSubject();

  Future<String> getWalletFilePath() async {
    try {
      String filePath = await FilePicker.getFilePath(type: FileType.ANY);
      if (filePath == '') {
        return null;
      }
      print("File path: " + filePath);

      File walletFile = File(filePath);

      String fileContent = walletFile.readAsStringSync();

      var json = jsonDecode(fileContent);

      if (json['crypto'] == null && json['Crypto'] == null) {
        return null;
      } else {
        return filePath;
      }
    } on Exception {
      return null;
    }
  }

  void dispose() {
    subject.close();
  }
}
