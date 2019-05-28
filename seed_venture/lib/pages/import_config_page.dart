import 'package:flutter/material.dart';
import 'package:seed_venture/blocs/bloc_provider.dart';
import 'package:seed_venture/blocs/mnemonic_logic_bloc.dart';
import 'package:seed_venture/pages/insert_password_import_page.dart';
import 'package:seed_venture/blocs/json_wallet_bloc.dart';
import 'package:seed_venture/blocs/private_key_wallet_bloc.dart';

class ImportConfigPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ImportConfigPageState();
}

class _ImportConfigPageState extends State<ImportConfigPage> {
  final TextEditingController mnemonicController = TextEditingController();
  final TextEditingController privateKeyController = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final MnemonicLogicBloc mnemonicLogicBloc =
        BlocProvider.of<MnemonicLogicBloc>(context);

    final JSONWalletBloc jsonWalletBloc = JSONWalletBloc();
    final PrivateKeyWalletBloc privateKeyWalletBloc = PrivateKeyWalletBloc();

    return Scaffold(
      key: _scaffoldKey,
        appBar: AppBar(
          title: Text('Import Config'),
        ),
        body: Container(
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
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => InsertPasswordImportPage(importMode: InsertPasswordImportPage.fromMnemonicWords, mnemonic: mnemonicController.text,)));
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
                          'Insert Private Key: ',
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
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => InsertPasswordImportPage(importMode: InsertPasswordImportPage.fromPrivateKey, privateKey: privateKeyController.text,)));
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
                onPressed: ()  async {
                  String walletPath = await jsonWalletBloc.getWalletFilePath();

                  if(walletPath != null) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => InsertPasswordImportPage(importMode: InsertPasswordImportPage.fromJSONFile, jsonPath: walletPath,)));
                  }
                  else{
                    SnackBar invalidFileSnackBar = SnackBar(content: Text('Invalid File'));
                    _scaffoldKey.currentState.showSnackBar(invalidFileSnackBar);

                  }

                },
                child: Text('Import from JSON File',
                    style: TextStyle(color: Colors.white)),
              ))
            ],
          ),
        ));
  }
}
