import 'package:flutter/material.dart';
import 'package:seed_venture/blocs/mnemonic_logic_bloc.dart';
import 'package:seed_venture/widgets/progress_bar_overlay.dart';
import 'dart:async';

class InsertPasswordMnemonicPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _InsertPasswordMnemonicPageState();
}

class _InsertPasswordMnemonicPageState
    extends State<InsertPasswordMnemonicPage> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController repeatPasswordController =
      TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription _streamSubscription;
  Stream _previousStream;

  void _listen(Stream<bool> stream) {
    _streamSubscription = stream.listen((success) {
      if (success) {
        Navigator.pop(context);
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (Route<dynamic> route) => false);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mnemonicLogicBloc.outOnDoneCreateConfigurationFromMnemonic !=
        _previousStream) {
      _streamSubscription?.cancel();
      _previousStream =
          mnemonicLogicBloc.outOnDoneCreateConfigurationFromMnemonic;
      _listen(mnemonicLogicBloc.outOnDoneCreateConfigurationFromMnemonic);
    }
  }

  @override
  void initState() {
    mnemonicLogicBloc.outCheckConfirmPassword.listen((equal) {
      if (equal == 'ok') {
        Navigator.of(context)
            .push(ProgressBarOverlay(ProgressBarOverlay.generatingConfig));
        mnemonicLogicBloc.deriveKeysFromMnemonic(passwordController.text);
      } else {
        SnackBar snack;
        if (equal == 'empty') {
          snack = SnackBar(content: Text('The password can\'t be empty'));
        } else {
          snack = SnackBar(content: Text('The passwords don\'t correspond!'));
        }

        _scaffoldKey.currentState.showSnackBar(snack);
      }
    });
    super.initState();
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
        title: Text('Password'),
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
                            child:
                                Text('Please, insert a password and confirm')),
                      )
                    ],
                  )),
              Container(
                child: TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                      border: InputBorder.none, hintText: 'Password...'),
                  controller: passwordController,
                ),
                margin: const EdgeInsets.only(
                    left: 20.0, right: 20.0, top: 10.0, bottom: 10.0),
              ),
              Container(
                child: TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                      border: InputBorder.none, hintText: 'Repeat Password...'),
                  controller: repeatPasswordController,
                ),
                margin: const EdgeInsets.only(
                    left: 20.0, right: 20.0, top: 10.0, bottom: 20.0),
              ),
              RaisedButton(
                onPressed: () {
                  mnemonicLogicBloc.checkConfirmPassword(
                      passwordController.text, repeatPasswordController.text);
                },
                child: Text('Continue', style: TextStyle(color: Colors.white)),
              )
            ],
          )),
    );
  }
}
