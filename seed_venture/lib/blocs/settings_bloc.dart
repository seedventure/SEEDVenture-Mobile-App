import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:seed_venture/blocs/baskets_bloc.dart';


final SettingsBloc settingsBloc = SettingsBloc();

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

  Stream<bool> get outZeroDocsStartupsSettings => _zeroDocsStartupsSettings.stream;
  Sink<bool> get _inZeroDocsStartupsSettings => _zeroDocsStartupsSettings.sink;

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

  void applyFilter()  {
   /* configManagerBloc.cancelPeriodicUpdate();
    configManagerBloc.cancelBalancesPeriodicUpdate();
    int currentBlockNumber = await configManagerBloc.getCurrentBlockNumber();
    Map prevConfig = await configManagerBloc.loadPreviousConfigFile();
    List<FundingPanelItem> fundingPanels = List();
    await configManagerBloc.getFundingPanelItems(fundingPanels, prevConfig, currentBlockNumber);
    configManagerBloc.setFundingPanels(fundingPanels);
    await configManagerBloc.getBasketTokensBalances(fundingPanels);
    configManagerBloc.enablePeriodicUpdate();
    configManagerBloc.configurationPeriodicUpdate();
    configManagerBloc.balancesPeriodicUpdate();*/

    basketsBloc.getBasketsTokenBalances();
  }



}
