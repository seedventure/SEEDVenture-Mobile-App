import 'package:flutter/material.dart';
import 'package:bip39/bip39.dart' as bip39;


class OnBoardingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('On Boarding'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(bottom: 50.0),
            child: Row(
              children: <Widget>[
                Expanded(
                    child: Container(
                        height: 20.0,
                        child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text(
                                'Create/Import a configuration or continue to view all the baskets...'))))
              ],
            ),
          ),
          RaisedButton(
            onPressed: () {
              String randomMnemonic = bip39.generateMnemonic();
              print(randomMnemonic);

              String seed = bip39.mnemonicToSeedHex(randomMnemonic);
              print(seed);


            },
            child: Text(
              'Create Config',
              style: TextStyle(color: Colors.white),
            ),
          ),
          RaisedButton(
            onPressed: () => print('ciao'),
            child: Text('Import Config', style: TextStyle(color: Colors.white)),
          ),
          Container(
              margin: const EdgeInsets.only(top: 25.0),
              child: RaisedButton(
                color: Theme.of(context).accentColor,
                onPressed: () => print('ciao'),
                child: Text('Continue without Config',
                    style: TextStyle(color: Colors.white)),
              ))
        ],
      ),
    );
  }
}
