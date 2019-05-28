import 'package:flutter/material.dart';
import 'package:web3dart/web3dart.dart';
import 'package:seed_venture/blocs/insert_password_import_bloc.dart';

class InsertPasswordImportPage extends StatefulWidget {

  static int fromJSONFile = 0;
  static int fromPrivateKey = 1;
  static int fromMnemonicWords = 2;

  final int importMode;
  final Credentials credentials;
  final String privateKey;
  final String jsonPath;
  final String mnemonic;

  InsertPasswordImportPage({this.importMode, this.credentials, this.privateKey, this.jsonPath, this.mnemonic});


  @override
  State<StatefulWidget> createState() => _InsertPasswordImportPageState(importMode: importMode, credentials: credentials, privateKey: privateKey, jsonPath: jsonPath, mnemonic: mnemonic);
}

class _InsertPasswordImportPageState extends State<InsertPasswordImportPage>{

  final TextEditingController passwordController = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final int importMode;
  final Credentials credentials;
  final String privateKey;
  final String jsonPath;
  final String mnemonic;


  _InsertPasswordImportPageState({this.importMode, this.credentials, this.privateKey, this.jsonPath, this.mnemonic});



  @override
  Widget build(BuildContext context) {

   final InsertPasswordImportBloc insertPasswordImportBloc =
    InsertPasswordImportBloc(importMode: importMode, credentials: credentials, privateKey: privateKey, jsonPath: jsonPath, mnemonic: mnemonic);

   insertPasswordImportBloc.wrongPasswordSubject.listen((data){
     SnackBar wrongPasswordSnackBar = SnackBar(content: Text('Wrong Password For JSON Wallet'));
     _scaffoldKey.currentState.showSnackBar(wrongPasswordSnackBar);
   });



    return Scaffold(
      key: _scaffoldKey,
        appBar: AppBar(
          title: Text('Insert Password'),
        ),
        body: Container(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[

              Container(
                child: TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                      border: InputBorder.none, hintText: 'Password...'),
                ),
                margin: const EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0, bottom: 10.0),
              ),
              RaisedButton(
                onPressed: () {
                  insertPasswordImportBloc.import(passwordController.text);
                },
                child: Text('Import', style: TextStyle(color: Colors.white)),
              ),


            ],
          ),
        ));
  }
}
