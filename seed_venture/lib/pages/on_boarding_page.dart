import 'package:flutter/material.dart';
import 'package:seed_venture/pages/create_wallet_page.dart';
import 'package:seed_venture/pages/import_wallet_page.dart';

class OnBoardingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Welcome to SEED Venture'),
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
                    children: <Widget>[
                      Expanded(
                        child: Text(
                            'Create/Import a wallet or continue to view all the baskets...'),
                      )
                    ],
                  )),
              RaisedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/create_wallet_page');
                },
                child: Text(
                  'Create Wallet',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              RaisedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/import_wallet_page');
                },
                child: Text('Import Wallet',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ));
  }
}
