import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

final SettingsBloc settingsBloc = SettingsBloc();

class SettingsBloc {
  BehaviorSubject<bool> _notificationsSettings = BehaviorSubject<bool>();

  Stream<bool> get outNotificationSettings => _notificationsSettings.stream;
  Sink<bool> get _inNotificationSettings => _notificationsSettings.sink;

  SettingsBloc() {
    SharedPreferences.getInstance().then((prefs) {
      if (prefs.getBool('notifications_enabled') == null) {
        prefs.setBool('notifications_enabled', true);
      }
      _inNotificationSettings.add(prefs.getBool('notifications_enabled'));
    });
  }

  void onChangeNotificationSettings(bool newValue) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('notifications_enabled', newValue);

      _inNotificationSettings.add(newValue);
    });
  }


  Future exportConfigurationFile() async {

    final documentsDir = await getApplicationDocumentsDirectory();
    String path = documentsDir.path;
    String configFilePath = '$path/configuration.json';


    var platform = MethodChannel(
        'seedventure.io/export_config');


    var result = await platform
        .invokeMethod('exportConfig', {
      "path": configFilePath,
    });


  }

  void dispose() {
    _notificationsSettings.close();
  }

  static Future<bool> areNotificationsEnabled() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool notificationsEnabled = prefs.getBool('notifications_enabled');
    if(notificationsEnabled == null) {
      prefs.setBool('notifications_enabled', true);
      notificationsEnabled = true;
    }
    return notificationsEnabled;
  }
}
