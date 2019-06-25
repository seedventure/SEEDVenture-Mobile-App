import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:seed_venture/models/funding_panel_item.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final BasketsBloc basketsBloc = BasketsBloc();

class BasketsBloc {
  PublishSubject<List<FundingPanelItem>> _getFundingPanelsDetails =
      PublishSubject<List<FundingPanelItem>>();

  Stream<List<FundingPanelItem>> get outFundingPanelsDetails =>
      _getFundingPanelsDetails.stream;
  Sink<List<FundingPanelItem>> get _inFundingPanelsDetails =>
      _getFundingPanelsDetails.sink;

  PublishSubject<List<String>> _notificationsiOS =
  PublishSubject<List<String>>();

  Stream<List<String>> get outNotificationsiOS =>
      _notificationsiOS.stream;
  Sink<List<String>> get _inNotificationsiOS =>
      _notificationsiOS.sink;

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;


  BasketsBloc() {

    flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    var initializationSettingsAndroid =
    new AndroidInitializationSettings('ic_launcher');
    var initializationSettingsIOS = new IOSInitializationSettings(
        onDidReceiveLocalNotification: onDidRecieveLocalNotification);
    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);


    SharedPreferences.getInstance().then((prefs) {
      List maps = jsonDecode(prefs.getString('funding_panels_data'));
      List<FundingPanelItem> fundingPanelItems = List();

      for (int i = 0; i < maps.length; i++) {
        // no need for members in this case
        fundingPanelItems.add(FundingPanelItem(
          tokenAddress: maps[i]['token_address'],
          fundingPanelAddress: maps[i]['funding_panel_address'],
          adminToolsAddress: maps[i]['admin_tools_address'],
          latestDexQuotation: maps[i]['latest_dex_price'],
          imgBase64: maps[i]['imgbase64'],
          name: maps[i]['name'],
          description: maps[i]['description'],
          url: maps[i]['url']
        ));
      }

      _inFundingPanelsDetails.add(fundingPanelItems);
    }
    );
  }

  void notification(String notificationData) async {


    await launchNotification(notificationData);
  }

  Future<void> launchNotification(String notificationData) async {
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        'SeedVenture', 'SeedVenture update', 'Seedventure',
        importance: Importance.Max, priority: Priority.High);
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0,
        'SeedVenture', notificationData,
        platformChannelSpecifics,
        payload: '');
  }

  Future<void> onSelectNotification(String payload) async {
    if (payload != null) {
      //debugPrint('notification payload: ' + payload);
    }
  }

  Future<void> onDidRecieveLocalNotification(
      int id, String title, String body, String payload)  {


    List<String> params = List();
    params[0] = title;
    params[0] = body;

    _inNotificationsiOS.add(params);
  }

  void updateBaskets() {
    SharedPreferences.getInstance().then((prefs) {
      List maps = jsonDecode(prefs.getString('funding_panels_data'));
      List<FundingPanelItem> fundingPanelItems = List();

      for (int i = 0; i < maps.length; i++) {
        // no need for members in this case
        fundingPanelItems.add(FundingPanelItem(
            tokenAddress: maps[i]['token_address'],
            fundingPanelAddress: maps[i]['funding_panel_address'],
            adminToolsAddress: maps[i]['admin_tools_address'],
            latestDexQuotation: maps[i]['latest_dex_price'],
            imgBase64: maps[i]['imgbase64'],
            name: maps[i]['name'],
            description: maps[i]['description'],
            url: maps[i]['url']
        ));
      }

      _inFundingPanelsDetails.add(fundingPanelItems);
    }
    );
  }

  void closeSubjects() {
    _getFundingPanelsDetails.close();
    _notificationsiOS.close();
  }
}
