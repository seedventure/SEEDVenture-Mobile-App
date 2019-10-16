import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:seed_venture/blocs/baskets_bloc.dart';

SettingsBloc settingsBloc = SettingsBloc();

class SettingsBloc {
  BehaviorSubject<bool> _notificationsSettings = BehaviorSubject<bool>();

  Stream<bool> get outNotificationSettings => _notificationsSettings.stream;
  Sink<bool> get _inNotificationSettings => _notificationsSettings.sink;

  BehaviorSubject<bool> _zeroStartupsSettings = BehaviorSubject<bool>();

  Stream<bool> get outZeroStartupsSettings => _zeroStartupsSettings.stream;
  Sink<bool> get _inZeroStartupsSettings => _zeroStartupsSettings.sink;

  BehaviorSubject<bool> _withoutURLBasketsSettings = BehaviorSubject<bool>();

  Stream<bool> get outWithoutURLBasketsSettings =>
      _withoutURLBasketsSettings.stream;
  Sink<bool> get _inWithoutURLBasketsSettings =>
      _withoutURLBasketsSettings.sink;

  BehaviorSubject<bool> _zeroDocsStartupsSettings = BehaviorSubject<bool>();

  Stream<bool> get outZeroDocsStartupsSettings =>
      _zeroDocsStartupsSettings.stream;
  Sink<bool> get _inZeroDocsStartupsSettings => _zeroDocsStartupsSettings.sink;

  BehaviorSubject<String> _currentNetwork = BehaviorSubject<String>();

  Stream<String> get outCurrentNetwork => _currentNetwork.stream;
  Sink<String> get _inCurrentNetwork => _currentNetwork.sink;

  void initBloc() {
    settingsBloc = SettingsBloc();
  }

  SettingsBloc() {
    SharedPreferences.getInstance().then((prefs) {
      if (prefs.getBool('notifications_enabled') == null) {
        prefs.setBool('notifications_enabled', true);
      }
      _inNotificationSettings.add(prefs.getBool('notifications_enabled'));

      if (prefs.getBool('filter_zero_startups') == null) {
        prefs.setBool('filter_zero_startups', true);
      }
      _inZeroStartupsSettings.add(prefs.getBool('filter_zero_startups'));

      if (prefs.getBool('filter_no_url') == null) {
        prefs.setBool('filter_no_url', true);
      }
      _inWithoutURLBasketsSettings.add(prefs.getBool('filter_no_url'));

      if (prefs.getBool('filter_zero_docs_startup') == null) {
        prefs.setBool('filter_zero_docs_startup', true);
      }
      _inZeroDocsStartupsSettings
          .add(prefs.getBool('filter_zero_docs_startup'));

      _inCurrentNetwork.add(prefs.getString("network"));
    });
  }

  void onChangeNotificationSettings(bool newValue) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('notifications_enabled', newValue);
      _inNotificationSettings.add(newValue);
    });
  }

  void onChangeZeroStartupSettings(bool newValue) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('filter_zero_startups', newValue);
      _inZeroStartupsSettings.add(newValue);
    });
  }

  void onChangeURLBasketsSettings(bool newValue) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('filter_no_url', newValue);
      _inWithoutURLBasketsSettings.add(newValue);
    });
  }

  void onChangeZeroDocsStartupSettings(bool newValue) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('filter_zero_docs_startup', newValue);
      _inZeroDocsStartupsSettings.add(newValue);
    });
  }

  Future exportConfigurationFile() async {
    final documentsDir = await getApplicationSupportDirectory();
    String path = documentsDir.path;
    String configFilePath = '$path/configuration.json';

    var platform = MethodChannel('seedventure.io/export_config');

    await platform.invokeMethod('exportConfig', {
      "path": configFilePath,
    });
  }

  void dispose() {
    _notificationsSettings.close();
    _zeroStartupsSettings.close();
    _withoutURLBasketsSettings.close();
    _zeroDocsStartupsSettings.close();
    _currentNetwork.close();
  }

  static Future<bool> areNotificationsEnabled() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool notificationsEnabled = prefs.getBool('notifications_enabled');
    if (notificationsEnabled == null) {
      prefs.setBool('notifications_enabled', true);
      notificationsEnabled = true;
    }
    return notificationsEnabled;
  }

  static Future<bool> isZeroStartupFilterEnabled() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool enabled = prefs.getBool('filter_zero_startups');
    if (enabled == null) {
      prefs.setBool('filter_zero_startups', true);
      enabled = true;
    }
    return enabled;
  }

  static Future<bool> isNoURLFilterEnabled() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool enabled = prefs.getBool('filter_no_url');
    if (enabled == null) {
      prefs.setBool('filter_no_url', true);
      enabled = true;
    }
    return enabled;
  }

  static Future<bool> isZeroDocsStartupFilterEnabled() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool enabled = prefs.getBool('filter_zero_docs_startup');
    if (enabled == null) {
      prefs.setBool('filter_zero_docs_startup', true);
      enabled = true;
    }
    return enabled;
  }

  void applyFilter() {
    basketsBloc.getBasketsTokenBalances();
  }

  static Future resetPreferences() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString("address", null);
    sharedPreferences.setString("sha256_pass", null);
    sharedPreferences.setString("funding_panels_data", null);
    sharedPreferences.setString("eth_balance", null);
    sharedPreferences.setString("seed_balance", null);
    sharedPreferences.setStringList("favorites", null);
    sharedPreferences.setString("user_baskets_balances", null);
    sharedPreferences.setString("fp_check_again_list", null);
    sharedPreferences.setString("members_check_again_list", null);
  }
}
