import 'package:flutter/material.dart';
import 'package:seed_venture/blocs/repeatmnemonic_bloc.dart';
import 'package:seed_venture/blocs/bloc_provider.dart';
import 'package:seed_venture/blocs/insertpasswordmnemonic_bloc.dart';
import 'package:seed_venture/pages/insert_password_mnemonic_page.dart';

class RepeatMnemonicPage extends StatefulWidget {
  final String rightMnemonic;

  RepeatMnemonicPage({this.rightMnemonic});

  @override
  State<StatefulWidget> createState() =>
      _RepeatMnemonicPageState(rightMnemonic: rightMnemonic);
}

class _RepeatMnemonicPageState extends State<RepeatMnemonicPage> {
  final TextEditingController mnemonicController = TextEditingController();
  final String rightMnemonic;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  _RepeatMnemonicPageState({this.rightMnemonic});

  @override
  Widget build(BuildContext context) {
    final RepeatMnemonicBloc repeatMnemonicBloc =
        BlocProvider.of<RepeatMnemonicBloc>(context);

    repeatMnemonicBloc.subject.listen((isCorrect) {
      if (!isCorrect) {
        SnackBar copySnack = SnackBar(content: Text('Wrong Mnemonic!'));
        _scaffoldKey.currentState.showSnackBar(copySnack);
      } else {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (BuildContext context) {
          return BlocProvider<InsertPasswordMnemonicBloc>(
            bloc: InsertPasswordMnemonicBloc(),
            child: InsertPasswordMnemonicPage(
              mnemonic: rightMnemonic,
            ),
          );
        }));
      }
    });

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
                  repeatMnemonicBloc.checkMnemonic(
                      rightMnemonic, mnemonicController.text);
                },
                child: Text('Check', style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ));
  }
}
