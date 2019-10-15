import 'package:flutter/material.dart';
import 'package:seed_venture/utils/constants.dart';
import 'package:seed_venture/blocs/choose_network_bloc.dart';
import 'package:seed_venture/blocs/mnemonic_logic_bloc.dart';
import 'package:seed_venture/blocs/import_logic_bloc.dart';
import 'package:seed_venture/widgets/progress_bar_overlay.dart';
import 'package:seed_venture/blocs/address_manager_bloc.dart';

class ChooseNetworkPage extends StatefulWidget {
  static const int FromCreate = 0;
  static const int FromImport = 1;
  final int mode;

  ChooseNetworkPage({this.mode});

  @override
  State<StatefulWidget> createState() => _ChooseNetworkPageState(mode: mode);
}

class _ChooseNetworkPageState extends State<ChooseNetworkPage> {
  final int mode;
  String _network = Mainnet;

  _ChooseNetworkPageState({this.mode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Choose Network'),
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
                            child: Text(
                                'Please, choose the network and continue')),
                      )
                    ],
                  )),
              Container(
                child: new DropdownButton<String>(
                  value: _network,
                  items: <String>[Mainnet, Ropsten].map((String value) {
                    return new DropdownMenuItem<String>(
                      value: value,
                      child: new Text(value),
                    );
                  }).toList(),
                  onChanged: (network) {
                    setState(() {
                      this._network = network;
                    });
                  },
                ),
                margin: const EdgeInsets.only(
                    left: 20.0, right: 20.0, top: 10.0, bottom: 20),
              ),
              RaisedButton(
                onPressed: () async {
                  await chooseNetworkBloc.saveNetwork(_network);
                  await addressManagerBloc.loadAddressList();

                  Navigator.of(context).push(
                      ProgressBarOverlay(ProgressBarOverlay.generatingConfig));

                  if (mode == ChooseNetworkPage.FromCreate) {
                    mnemonicLogicBloc.deriveKeysFromMnemonic(
                        mnemonicLogicBloc.getPassword());
                  } else {
                    importLogicBloc.createConfigFromCredentials();
                  }
                },
                child: Text('Continue', style: TextStyle(color: Colors.white)),
              )
            ],
          )),
    );
  }
}
