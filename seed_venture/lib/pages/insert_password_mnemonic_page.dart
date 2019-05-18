import 'package:flutter/material.dart';
import 'package:seed_venture/blocs/bloc_provider.dart';
import 'package:seed_venture/blocs/insertpasswordmnemonic_bloc.dart';
import 'package:seed_venture/widgets/progress_bar_overlay.dart';
import 'package:seed_venture/pages/grid_page.dart';

class InsertPasswordMnemonicPage extends StatelessWidget {
  final String mnemonic;
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController repeatPasswordController =
      TextEditingController();

  InsertPasswordMnemonicPage({this.mnemonic});

  @override
  Widget build(BuildContext context) {
    final InsertPasswordMnemonicBloc insertPasswordMnemonicBloc =
        BlocProvider.of<InsertPasswordMnemonicBloc>(context);

    return Scaffold(
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
                margin: const EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0, bottom: 10.0),
              ),
              Container(
                child: TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                      border: InputBorder.none, hintText: 'Repeat Password...'),
                  controller: repeatPasswordController,
                ),
                margin: const EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0, bottom: 20.0),
              ),
              RaisedButton(
                onPressed: () {
                  Navigator.of(context).push(ProgressBarOverlay());
                  insertPasswordMnemonicBloc.deriveKeysFromMnemonic(
                      mnemonic, passwordController.text);

                  insertPasswordMnemonicBloc.subject.listen((success) {
                    if (success) {
                      Navigator.pop(context);


                      Navigator.of(context).pushNamedAndRemoveUntil(
                          '/home', (Route<dynamic> route) => false);


                    }
                  });
                },
                child: Text('Continue', style: TextStyle(color: Colors.white)),
              )
            ],
          )),
    );
  }
}
