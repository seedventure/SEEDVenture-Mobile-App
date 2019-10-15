import 'package:flutter/material.dart';
import 'package:seed_venture/blocs/mnemonic_logic_bloc.dart';
import 'package:seed_venture/pages/insert_password_import_page.dart';
import 'package:seed_venture/blocs/json_wallet_logic_bloc.dart';
import 'package:seed_venture/blocs/import_logic_bloc.dart';
import 'package:seed_venture/blocs/import_from_private_key_logic_bloc.dart';
import 'package:seed_venture/blocs/import_from_config_file_bloc.dart';

class ImportWalletPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ImportWalletPageState();
}

class _ImportWalletPageState extends State<ImportWalletPage> {
  final TextEditingController mnemonicController = TextEditingController();
  final TextEditingController privateKeyController = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    jsonWalletLogicBloc.outJsonFileSelection.listen((success) {
      if (success) {
        importLogicBloc.setCurrentImportMode(ImportLogicBloc.fromJSONFile);

        Navigator.pushNamed(context, '/insert_password_import_page');
      } else {
        SnackBar invalidFileSnackBar =
            SnackBar(content: Text('Invalid Wallet File'));
        _scaffoldKey.currentState.showSnackBar(invalidFileSnackBar);
      }
    });

    importFromConfigFileBloc.outConfigFileSelection.listen((success) {
      if (success) {
        importLogicBloc.setCurrentImportMode(ImportLogicBloc.fromConfigFile);

        Navigator.pushNamed(context, '/insert_password_import_page');
      } else {
        SnackBar invalidFileSnackBar =
            SnackBar(content: Text('Invalid Config File'));
        _scaffoldKey.currentState.showSnackBar(invalidFileSnackBar);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text('Import Wallet'),
        ),
        body: SingleChildScrollView(
            child: Container(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                  margin: const EdgeInsets.only(
                      left: 10.0, top: 20.0, right: 10.0, bottom: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: Center(
                            child: Text(
                          'Insert Mnemonic Words: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        )),
                      )
                    ],
                  )),
              Container(
                child: TextField(
                  controller: mnemonicController,
                  decoration: InputDecoration(
                      border: InputBorder.none, hintText: 'Mnemonic Words...'),
                ),
                margin: const EdgeInsets.only(
                    left: 20.0, right: 20.0, top: 10.0, bottom: 10.0),
              ),
              RaisedButton(
                onPressed: () {
                  mnemonicLogicBloc.inSetCustomMnemonic
                      .add(mnemonicController.text);
                  importLogicBloc
                      .setCurrentImportMode(ImportLogicBloc.fromMnemonicWords);

                  Navigator.pushNamed(context, '/insert_password_import_page');
                },
                child: Text('Import', style: TextStyle(color: Colors.white)),
              ),
              Container(
                  margin: const EdgeInsets.only(
                      left: 10.0, top: 40.0, right: 10.0, bottom: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: Center(
                            child: Text(
                          'OR Insert Private Key: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        )),
                      )
                    ],
                  )),
              Container(
                child: TextField(
                  controller: privateKeyController,
                  decoration: InputDecoration(
                      border: InputBorder.none, hintText: 'Private Key...'),
                ),
                margin: const EdgeInsets.only(
                    left: 20.0, right: 20.0, top: 10.0, bottom: 10.0),
              ),
              RaisedButton(
                onPressed: () {
                  importPrivateKeyLogicBloc
                      .setCurrentPrivateKey(privateKeyController.text);
                  importLogicBloc
                      .setCurrentImportMode(ImportLogicBloc.fromPrivateKey);
                  Navigator.pushNamed(context, '/insert_password_import_page');
                },
                child: Text('Import', style: TextStyle(color: Colors.white)),
              ),
              Container(
                  margin: const EdgeInsets.only(
                      left: 10.0, top: 40.0, right: 10.0, bottom: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: Center(
                            child: Text(
                          'OR',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        )),
                      )
                    ],
                  )),
              Container(
                  child: RaisedButton(
                onPressed: () {
                  importFromConfigFileBloc.selectConfigFile();
                },
                child: Text('Import from Config File',
                    style: TextStyle(color: Colors.white)),
              )),
              Container(
                  margin: const EdgeInsets.only(
                      left: 10.0, top: 40.0, right: 10.0, bottom: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: Center(
                            child: Text(
                          'OR',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        )),
                      )
                    ],
                  )),
              Container(
                  child: RaisedButton(
                onPressed: () {
                  jsonWalletLogicBloc.selectWalletFile();
                },
                child: Text('Import from JSON File',
                    style: TextStyle(color: Colors.white)),
              ))
            ],
          ),
        )));
  }
}
