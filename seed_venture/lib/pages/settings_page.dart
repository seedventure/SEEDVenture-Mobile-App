import 'package:flutter/material.dart';
import 'package:seed_venture/blocs/settings_bloc.dart';
import 'package:seed_venture/widgets/progress_bar_overlay.dart';

class SettingsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SettingsStatePage();
}

class _SettingsStatePage extends State<SettingsPage> {
  final _scaffoldKey = new GlobalKey<ScaffoldState>();
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
                                    Navigator.of(context).push(
                                        ProgressBarOverlay(
                                            ProgressBarOverlay.applyingFilter));

                                    await settingsBloc.applyFilter();

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

                                    await settingsBloc.applyFilter();

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

                                    await settingsBloc.applyFilter();

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
                      Container(
                        margin: const EdgeInsets.only(top: 8.0),
                        child: InkWell(
                            onTap: () async {
                              await settingsBloc.exportConfigurationFile();
                            },
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text('Export Configuration File'),
                                ),
                              ],
                            )),
                      )
                    ]))));
  }

  @override
  void dispose() {
    //settingsBloc.dispose();
    super.dispose();
  }
}
