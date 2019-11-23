import 'package:flutter/material.dart';
import 'package:seed_venture/blocs/settings_bloc.dart';
import 'package:seed_venture/widgets/progress_bar_overlay.dart';
import 'package:seed_venture/blocs/onboarding_bloc.dart';
import 'package:seed_venture/blocs/config_manager_bloc.dart';
import 'package:seed_venture/utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SettingsStatePage();
}

class _SettingsStatePage extends State<SettingsPage> {
  final _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    settingsBloc.initBloc();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        key: _scaffoldKey,
        appBar: new AppBar(
          title: new Text('Settings'),
        ),
        body: SingleChildScrollView(
            child: Container(
                margin: const EdgeInsets.all(12),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      StreamBuilder(
                        builder:
                            (BuildContext context, AsyncSnapshot snapshot) {
                          if (snapshot.hasData) {
                            return Row(
                              children: <Widget>[
                                Text('Notifications '),
                                Spacer(),
                                Switch(
                                  value: snapshot.data,
                                  onChanged: (newValue) {
                                    settingsBloc
                                        .onChangeNotificationSettings(newValue);
                                  },
                                  activeTrackColor:
                                      Theme.of(context).accentColor,
                                  activeColor: Theme.of(context).primaryColor,
                                ),
                              ],
                            );
                          } else
                            return Container();
                        },
                        stream: settingsBloc.outNotificationSettings,
                      ),
                      StreamBuilder(
                        builder:
                            (BuildContext context, AsyncSnapshot snapshot) {
                          if (snapshot.hasData) {
                            return Row(
                              children: <Widget>[
                                Text('Hide 0-Startups Baskets '),
                                Spacer(),
                                Switch(
                                  value: snapshot.data,
                                  onChanged: (newValue) async {
                                    settingsBloc
                                        .onChangeZeroStartupSettings(newValue);

                                    settingsBloc.applyFilter();

                                    SnackBar copySnack = SnackBar(
                                        content: Text('Filter Applied'));
                                    _scaffoldKey.currentState
                                        .showSnackBar(copySnack);
                                  },
                                  activeTrackColor:
                                      Theme.of(context).accentColor,
                                  activeColor: Theme.of(context).primaryColor,
                                ),
                              ],
                            );
                          } else
                            return Container();
                        },
                        stream: settingsBloc.outZeroStartupsSettings,
                      ),
                      StreamBuilder(
                        builder:
                            (BuildContext context, AsyncSnapshot snapshot) {
                          if (snapshot.hasData) {
                            return Row(
                              children: <Widget>[
                                Text('Hide Baskets without URL '),
                                Spacer(),
                                Switch(
                                  value: snapshot.data,
                                  onChanged: (newValue) async {
                                    settingsBloc
                                        .onChangeURLBasketsSettings(newValue);
                                    Navigator.of(context).push(
                                        ProgressBarOverlay(
                                            ProgressBarOverlay.applyingFilter));

                                    settingsBloc.applyFilter();

                                    Navigator.pop(context);

                                    SnackBar copySnack = SnackBar(
                                        content: Text('Filter Applied'));
                                    _scaffoldKey.currentState
                                        .showSnackBar(copySnack);
                                  },
                                  activeTrackColor:
                                      Theme.of(context).accentColor,
                                  activeColor: Theme.of(context).primaryColor,
                                ),
                              ],
                            );
                          } else
                            return Container();
                        },
                        stream: settingsBloc.outWithoutURLBasketsSettings,
                      ),
                      StreamBuilder(
                        builder:
                            (BuildContext context, AsyncSnapshot snapshot) {
                          if (snapshot.hasData) {
                            return Row(
                              children: <Widget>[
                                Text('Hide 0-Docs Startups '),
                                Spacer(),
                                Switch(
                                  value: snapshot.data,
                                  onChanged: (newValue) async {
                                    settingsBloc
                                        .onChangeZeroDocsStartupSettings(
                                            newValue);
                                    Navigator.of(context).push(
                                        ProgressBarOverlay(
                                            ProgressBarOverlay.applyingFilter));

                                    settingsBloc.applyFilter();

                                    Navigator.pop(context);

                                    SnackBar copySnack = SnackBar(
                                        content: Text('Filter Applied'));
                                    _scaffoldKey.currentState
                                        .showSnackBar(copySnack);
                                  },
                                  activeTrackColor:
                                      Theme.of(context).accentColor,
                                  activeColor: Theme.of(context).primaryColor,
                                ),
                              ],
                            );
                          } else
                            return Container();
                        },
                        stream: settingsBloc.outZeroDocsStartupsSettings,
                      ),
                      StreamBuilder(
                        builder:
                            (BuildContext context, AsyncSnapshot snapshot) {
                          if (snapshot.hasData && snapshot.data[0]) {
                            return Column(
                              children: <Widget>[
                                Container(
                                  child: InkWell(
                                      onTap: () {
                                        launch(ropstenSEEDFaucet +
                                            snapshot.data[1]);
                                      },
                                      child: Padding(
                                          padding: const EdgeInsets.only(
                                              top: 8.0, bottom: 8.0),
                                          child: Row(
                                            children: <Widget>[
                                              Expanded(
                                                child: Text('Get Ropsten SEED'),
                                              ),
                                            ],
                                          ))),
                                ),
                                Container(
                                  child: InkWell(
                                      onTap: () {
                                        launch(ropstenETHFaucet);
                                      },
                                      child: Padding(
                                          padding: const EdgeInsets.only(
                                              top: 8.0, bottom: 8.0),
                                          child: Row(
                                            children: <Widget>[
                                              Expanded(
                                                child: Text('Get Ropsten ETH'),
                                              ),
                                            ],
                                          ))),
                                ),
                              ],
                            );
                          } else
                            return Container();
                        },
                        stream: settingsBloc.outFaucetSettings,
                      ),
                      Container(
                        child: InkWell(
                            onTap: () async {
                              await settingsBloc.exportConfigurationFile();
                            },
                            child: Padding(
                                padding: const EdgeInsets.only(
                                    top: 8.0, bottom: 8.0),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text('Export Configuration File'),
                                    ),
                                  ],
                                ))),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 12.0),
                        height: 1.0,
                        width: double.infinity,
                        color: Color(0xFFE3DFDF),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 12.0),
                        child: StreamBuilder(
                          builder:
                              (BuildContext context, AsyncSnapshot snapshot) {
                            if (snapshot.hasData) {
                              return Row(
                                children: <Widget>[
                                  Text('Current Network is '),
                                  Text(
                                    snapshot.data,
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  )
                                ],
                              );
                            } else
                              return Container();
                          },
                          stream: settingsBloc.outCurrentNetwork,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 16.0),
                        child: InkWell(
                            onTap: () {
                              _showSwitchNetworkAlertDialog();
                            },
                            child: Padding(
                                padding: const EdgeInsets.only(
                                    top: 8.0, bottom: 8.0),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text('Switch Network'),
                                    ),
                                  ],
                                ))),
                      ),
                    ]))));
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showSwitchNetworkAlertDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: new Text("Switch Network"),
          content: new Text(
              "To change the network you have to repeat the account creation. If you don't have a wallet backup "
              "all your data will be lost, do you want to continue?"),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            new FlatButton(
              child: new Text("Yes"),
              onPressed: () async {
                Navigator.of(context).pop();
                configManagerBloc.cancelPeriodicUpdate();
                configManagerBloc.cancelBalancesPeriodicUpdate();
                configManagerBloc.deleteConfigFile();
                await SettingsBloc.resetPreferences();
                OnBoardingBloc.setOnBoardingToBeDone();
                Navigator.of(context).pushNamedAndRemoveUntil(
                    '/on_boarding', (Route<dynamic> route) => false);
              },
            ),
          ],
        );
      },
    );
  }
}
