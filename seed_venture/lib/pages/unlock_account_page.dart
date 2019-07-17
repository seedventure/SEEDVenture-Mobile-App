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
        resizeToAvoidBottomPadding:
            false, // if true, it resize when the keyboard appear/disappear
        key: _scaffoldKey,

        body:

            Stack(children: <Widget>[
          Positioned.fill(
            child: Image(
              image: AssetImage('assets/bg-login.png'),
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      margin: const EdgeInsets.only(top: 50.0, bottom: 10.0),
                        child: Image.asset(
                      'assets/seed-logo.png',
                      height: 100,
                      width: 100,
                    )
                    )
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                          child: Center(
                            child: Text(
                              'The first decentralized venture capital investment platform',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white),
                            ),
                          ))
                    ],
                  )
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                        child: Center(
                      child: Text(
                        'Please, type your password to unlock your account',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white),
                      ),
                    ))
                  ],
                ),
                Container(
                    margin: const EdgeInsets.all(12.0),
                    child: TextField(
                        obscureText: true,
                        controller: passwordController,
                        style: TextStyle(color: Colors.white),
                        decoration: new InputDecoration(
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.white),
                            labelStyle: new TextStyle(color: Colors.white),
                            /*border: new UnderlineInputBorder(
                                        borderSide: new BorderSide(
                                            color: Colors.white)),*/
                            hintText: 'Password...'))),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                        child: RaisedButton(
                      color: Colors.white,
                      onPressed: () {
                        FocusScope.of(context).requestFocus(new FocusNode());
                        unlockAccountBloc
                            .isPasswordCorrect(passwordController.text);
                      },
                      child: Text('Unlock',
                          style: TextStyle(color: Color(0xFF006B97))),
                    ))
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                        child: RaisedButton(
                      color: Colors.white,
                      onPressed: () {
                        OnBoardingBloc.setOnBoardingToBeDone();
                        Navigator.of(context).pushNamedAndRemoveUntil(
                            '/on_boarding', (Route<dynamic> route) => false);
                      },
                      child: Text('Forget',
                          style: TextStyle(color: Color(0xFF006B97))),
                    ))
                  ],
                ),
              ],
            ),
          )
        ])
        //    )
        );
  }
}
