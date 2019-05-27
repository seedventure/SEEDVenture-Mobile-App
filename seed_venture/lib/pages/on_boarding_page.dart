import 'package:flutter/material.dart';
import 'package:seed_venture/pages/create_config_page.dart';
import 'package:seed_venture/blocs/createconfig_bloc.dart';
import 'package:seed_venture/blocs/bloc_provider.dart';
import 'package:seed_venture/blocs/onboarding_bloc.dart';
import 'package:seed_venture/pages/import_config_page.dart';
import 'package:seed_venture/blocs/mnemonic_logic_bloc.dart';

class OnBoardingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
   // final OnBoardingBloc onBoardingBloc =
   // BlocProvider.of<OnBoardingBloc>(context);

    return Scaffold(
        appBar: AppBar(
          title: Text('On Boarding'),
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
                            'Create/Import a configuration or continue to view all the baskets...'),
                      )
                    ],
                  )),
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
                onPressed: () {
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (BuildContext context) {
                    return BlocProvider<MnemonicLogicBloc>(
                      bloc: MnemonicLogicBloc(),
                      child: ImportConfigPage(),
                    );
                  }));
                },
                child: Text('Import Config',
                    style: TextStyle(color: Colors.white)),
              ),
              Container(
                  margin: const EdgeInsets.only(top: 25.0),
                  child: RaisedButton(
                    color: Theme.of(context).accentColor,
                    onPressed: () {
                      //onBoardingBloc.setOnBoardingDone();
                      Navigator.of(context).pushNamedAndRemoveUntil(
                          '/home', (Route<dynamic> route) => false);
                    },
                    child: Text('Continue without Config',
                        style: TextStyle(color: Colors.white)),
                  ))
            ],
          ),
        ));
  }
}
