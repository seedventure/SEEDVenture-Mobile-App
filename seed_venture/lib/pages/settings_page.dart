import 'package:flutter/material.dart';
import 'package:seed_venture/blocs/settings_bloc.dart';

class SettingsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SettingsStatePage();
}

class _SettingsStatePage extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text('Settings'),
        ),
        body: StreamBuilder(
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.hasData) {
              return SingleChildScrollView(
                child: Container(
                    margin: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Text('Notifications '),
                            Checkbox(
                              value: snapshot.data,
                              onChanged: (newValue) => settingsBloc
                                  .onChangeNotificationSettings(newValue),
                            )
                          ],
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
                      ],
                    )),
              );
            } else {
              return Container();
            }
          },
          stream: settingsBloc.outNotificationSettings,
        ));
  }

  @override
  void dispose() {
    settingsBloc.dispose();
    super.dispose();
  }
}
