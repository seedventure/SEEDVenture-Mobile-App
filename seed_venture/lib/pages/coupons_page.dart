import 'package:flutter/material.dart';
import 'package:seed_venture/blocs/coupons_bloc.dart';
import 'package:seed_venture/blocs/coupons_bloc.dart' as prefix0;
import 'package:seed_venture/widgets/progress_bar_overlay.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:seed_venture/blocs/address_manager_bloc.dart';

class CouponsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _CouponsPageState();
}

class _CouponsPageState extends State<CouponsPage> {
  final _scaffoldKey = new GlobalKey<ScaffoldState>();


  Future _showCodeDialog() async {
    TextEditingController codeController = TextEditingController();

    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return new SimpleDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  child: Text('Insert Code'),
                  margin: EdgeInsets.only(bottom: 10.0),
                )
              ],
            ),
            children: <Widget>[
              Column(
                children: <Widget>[
                  Container(
                    child: TextField(
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                          border: InputBorder.none, hintText: 'Code...'),
                      controller: codeController,
                    ),
                    height: 50,
                    width: double.infinity,
                    margin: EdgeInsets.all(20.0),
                  ),
                  Container(
                    margin:
                        EdgeInsets.only(right: 20.0, left: 20.0, bottom: 20.0),
                    child: RaisedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        couponsBloc.setCouponCode(codeController.text);
                        _showPasswordDialog();
                      },
                      child: const Text(
                        'Redeem Code',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                ],
                crossAxisAlignment: CrossAxisAlignment.center,
              )
            ],
          );
        });
  }

  Future _showPasswordDialog() async {
    TextEditingController passwordController = TextEditingController();

    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return new SimpleDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  child: Text('Insert Password'),
                  margin: EdgeInsets.only(bottom: 10.0),
                )
              ],
            ),
            children: <Widget>[
              Column(
                children: <Widget>[
                  Container(
                    child: TextField(
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                          border: InputBorder.none, hintText: 'Password...'),
                      controller: passwordController,
                      obscureText: true,
                    ),
                    height: 50,
                    width: double.infinity,
                    margin: EdgeInsets.all(20.0),
                  ),
                  Container(
                    margin:
                        EdgeInsets.only(right: 20.0, left: 20.0, bottom: 20.0),
                    child: RaisedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(ProgressBarOverlay(
                            ProgressBarOverlay.sendingTransaction));
                        couponsBloc.redeemCode(passwordController.text);
                      },
                      child: const Text(
                        'Redeem Code',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                ],
                crossAxisAlignment: CrossAxisAlignment.center,
              )
            ],
          );
        });
  }

  @override
  void initState() {

    couponsBloc.initStreams();

    couponsBloc.outPasswordDialog.listen((scanned) {
      if (scanned) {
        _showPasswordDialog();
      }
    });

    couponsBloc.outWrongPassword.listen((wrongPassword) {
      if (wrongPassword) {
        Navigator.pop(context);
        SnackBar wrongPasswordSnackBar =
            SnackBar(content: Text('Wrong Password'));
        _scaffoldKey.currentState.showSnackBar(wrongPasswordSnackBar);
      }
    });

    couponsBloc.outRedeemError.listen((error) {
      if (error) {
        Navigator.pop(context);
        SnackBar txErrorSnackBar = SnackBar(
            content: Text(
                'There was an error in your transaction: check your funds to pay gas!'));
        _scaffoldKey.currentState.showSnackBar(txErrorSnackBar);
      }
    });

    couponsBloc.outWrongRedeemCode.listen((error) {
      if (error) {
        Navigator.pop(context);
        SnackBar txErrorSnackBar =
            SnackBar(content: Text('Your redeem code is not valid'));
        _scaffoldKey.currentState.showSnackBar(txErrorSnackBar);
      }
    });

    couponsBloc.outRedeemSuccess.listen((txHash) {
      if (txHash != null) {
        Navigator.pop(context);
        SnackBar contributedSnackBar = SnackBar(
            duration: const Duration(seconds: 15),
            content: Text('You are redeeming your coupon'),
            action: SnackBarAction(
              label: 'View Tx',
              onPressed: () {
                launch(addressManagerBloc.etherscanURL + 'tx/$txHash');
              },
            ));
        _scaffoldKey.currentState.showSnackBar(contributedSnackBar);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        key: _scaffoldKey,
        appBar: new AppBar(
          title: new Text('Redeem Coupon'),
        ),
        body: Container(
          margin: const EdgeInsets.only(top: 12.0),
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        await couponsBloc.scan();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(left: 12.0, right: 6.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              child: Image.asset(
                                'assets/qrcode.png',
                                width: 75,
                                height: 75,
                              ),
                              margin: EdgeInsets.only(top: 20.0),
                            ),
                            Container(
                              child: Text(
                                'QR Code',
                              ),
                              margin: EdgeInsets.only(top: 15.0),
                            ),
                            Container(
                              child: Center(
                                child: Text('Scan Coupon QR code',
                                    textAlign: TextAlign.center),
                              ),
                              margin: EdgeInsets.all(8.0),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                      child: InkWell(
                    onTap: () {
                      _showCodeDialog();
                    },
                    child: Container(
                        margin: const EdgeInsets.only(left: 6.0, right: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              child: Image.asset(
                                'assets/text.png',
                                width: 57,
                                height: 75,
                              ),
                              margin: EdgeInsets.only(top: 20.0),
                            ),
                            Container(
                              child: Text(
                                'Enter Coupon',
                              ),
                              margin: EdgeInsets.only(top: 15.0),
                            ),
                            Container(
                              child: Center(
                                child: Text('Paste or type the coupon code',
                                    textAlign: TextAlign.center),
                              ),
                              margin: EdgeInsets.all(8.0),
                            )
                          ],
                        )),
                  ))
                ],
              )
            ],
          ),
        ));
  }

  @override
  void dispose() {
    couponsBloc.dispose();
    super.dispose();
  }
}
