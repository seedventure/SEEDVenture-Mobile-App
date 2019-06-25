import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  void dispose() {
    _notificationsSettings.close();
  }

  static Future<bool> areNotificationsEnabled() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled');
  }
}
