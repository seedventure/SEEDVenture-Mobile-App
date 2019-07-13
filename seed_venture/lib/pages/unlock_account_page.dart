import 'package:flutter/material.dart';
import 'package:seed_venture/blocs/unlock_account_bloc.dart';
import 'package:seed_venture/blocs/onboarding_bloc.dart';

class UnlockAccountPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _UnlockAccountPageState();
}

class _UnlockAccountPageState extends State<UnlockAccountPage> {
  final passwordController = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    unlockAccountBloc.outPasswordCheck.listen((isCorrect) {
      if (!isCorrect) {
        SnackBar wrongPasswordSnackBar =
            SnackBar(content: Text('Wrong Password'));
        _scaffoldKey.currentState.showSnackBar(wrongPasswordSnackBar);
      } else {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (Route<dynamic> route) => false);
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        key: _scaffoldKey,
        appBar: new AppBar(
          title: new Text('Unlock Account'),
        ),
        body: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.only(top: 12.0),
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                        child: Center(
                      child: Text(
                          'Please, type your password to unlock your account'),
                    ))
                  ],
                ),
                Container(
                    margin: const EdgeInsets.all(12.0),
                    child: TextField(
                      obscureText: true,
                      controller: passwordController,
                      decoration: InputDecoration(
                          border: InputBorder.none, hintText: 'Password...'),
                    )),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                        child: RaisedButton(
                      onPressed: () {
                        unlockAccountBloc
                            .isPasswordCorrect(passwordController.text);
                      },
                      child:
                          Text('Unlock', style: TextStyle(color: Colors.white)),
                    ))
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                        child: RaisedButton(
                      onPressed: () {
                        OnBoardingBloc.setOnBoardingToBeDone();
                        Navigator.of(context).pushNamedAndRemoveUntil(
                            '/on_boarding', (Route<dynamic> route) => false);
                      },
                      child:
                          Text('Forget', style: TextStyle(color: Colors.white)),
                    ))
                  ],
                ),
              ],
            ),
          ),
        ));
  }
}
