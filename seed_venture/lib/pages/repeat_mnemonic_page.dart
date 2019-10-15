import 'package:flutter/material.dart';
import 'package:seed_venture/blocs/mnemonic_logic_bloc.dart';
import 'dart:async';

class RepeatMnemonicPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _RepeatMnemonicPageState();
}

class _RepeatMnemonicPageState extends State<RepeatMnemonicPage> {
  final TextEditingController mnemonicController = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription _streamSubscription;
  Stream _previousStream;

  void _listen(Stream<bool> stream) {
    _streamSubscription = stream.listen((isCorrect) {
      if (!isCorrect) {
        SnackBar copySnack = SnackBar(content: Text('Wrong Mnemonic!'));
        _scaffoldKey.currentState.showSnackBar(copySnack);
      } else {
        Navigator.pushNamed(context, '/insert_password_mnemonic_page');
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (mnemonicLogicBloc.outCheckMnemonic != _previousStream) {
      _streamSubscription?.cancel();
      _previousStream = mnemonicLogicBloc.outCheckMnemonic;
      _listen(mnemonicLogicBloc.outCheckMnemonic);
    }
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text('Repeat the words'),
        ),
        body: Container(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                  margin: const EdgeInsets.only(
                      left: 10.0, top: 10.0, right: 10.0, bottom: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: Center(
                            child: Text('Please, repeat the words in order')),
                      )
                    ],
                  )),
              Container(
                child: TextField(
                  controller: mnemonicController,
                  decoration: InputDecoration(
                      border: InputBorder.none, hintText: 'Mnemonic Words...'),
                ),
                margin: const EdgeInsets.all(20.0),
              ),
              RaisedButton(
                onPressed: () {
                  mnemonicLogicBloc.isMnemonicCorrect(mnemonicController.text);
                },
                child: Text('Check', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ));
  }
}
