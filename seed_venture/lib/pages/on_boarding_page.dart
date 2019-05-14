import 'package:flutter/material.dart';
import 'package:seed_venture/pages/create_config_page.dart';
import 'package:seed_venture/blocs/createconfig_bloc.dart';
import 'package:seed_venture/blocs/bloc_provider.dart';

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
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (BuildContext context) {
                return BlocProvider<CreateConfigBloc>(
                  bloc: CreateConfigBloc(),
                  child: CreateConfigPage(),
                );
              }));
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
