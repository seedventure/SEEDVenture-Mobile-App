import 'package:flutter/material.dart';
import 'package:seed_venture/blocs/wallet_info_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share/share.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:seed_venture/utils/constants.dart';

class WalletInfoPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _WalletInfoPageState();
}

class _WalletInfoPageState extends State<WalletInfoPage> {
  final _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        key: _scaffoldKey,
        appBar: new AppBar(
          title: new Text('Wallet Info'),
        ),
        body: StreamBuilder(
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.hasData) {
              return SingleChildScrollView(
                  child: Column(
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(top: 5.0, bottom: 5.0),
                    height: 1.0,
                    width: double.infinity,
                    color: Color(0xFFF5F5F5),
                  ),
                  Container(
                      margin: EdgeInsets.only(top: 25.0),
                      child: Align(
                          alignment: Alignment.topCenter,
                          child: QrImage(
                            data: snapshot.data,
                            size: 175.0,
                          ))),
                  Container(
                    margin: EdgeInsets.only(top: 40.0, left: 18.0, right: 18.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          'Your',
                          style: TextStyle(
                              color: Color(0xFF5B5B5B),
                              fontFamily: 'SF-Pro-Regular',
                              fontSize: 16.0),
                          maxLines: 2,
                        ),
                        Text(
                          ' ETHEREUM ',
                          style: TextStyle(
                              color: Color(0xFF5B5B5B),
                              fontFamily: 'SF-Pro-Bold',
                              fontSize: 16.0),
                        ),
                        Text(
                          'address',
                          style: TextStyle(
                              color: Color(0xFF5B5B5B),
                              fontFamily: 'SF-Pro-Regular',
                              fontSize: 16.0),
                        )
                      ],
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 20.0, left: 13.0, right: 13.0),
                    child: Text(snapshot.data,
                        style: TextStyle(
                            color: Color(0xFF5B5B5B),
                            fontFamily: 'SF-Pro-Regular',
                            fontSize: 14.0)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                          margin: EdgeInsets.only(top: 50.0),
                          child: RaisedButton(
                            onPressed: () {
                              Share.share('My address is: ' + snapshot.data);
                            },
                            child: const Text(
                              'Share your address',
                              style: TextStyle(color: Colors.white),
                            ),
                          ))
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                          margin: EdgeInsets.only(top: 20.0),
                          child: RaisedButton(
                            elevation: 0,
                            onPressed: () {
                              WalletInfoBloc.copyAddressToClipboard(
                                  snapshot.data);
                              SnackBar copySnack =
                                  SnackBar(content: Text('Address copied!'));
                              _scaffoldKey.currentState.showSnackBar(copySnack);
                            },
                            child: const Text(
                              'Copy to clipboard',
                              style: TextStyle(color: Colors.white),
                            ),
                          ))
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: EdgeInsets.only(top: 20.0),
                        child: RichText(
                          text: TextSpan(
                            text: 'View on Etherscan',
                            style: new TextStyle(
                                color: Colors.blue,
                                fontFamily: 'Poppins-Regular'),
                            recognizer: new TapGestureRecognizer()
                              ..onTap = () {
                                launch(
                                    EtherscanURL + 'address/' + snapshot.data);
                              },
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ));
            } else {
              return Container();
            }
          },
          stream: walletInfoBloc.outAddress,
        ));
  }
}
