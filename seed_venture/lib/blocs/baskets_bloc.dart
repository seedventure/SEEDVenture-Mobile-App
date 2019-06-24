import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:seed_venture/models/funding_panel_details.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final BasketsBloc basketsBloc = BasketsBloc();

class BasketsBloc {
  PublishSubject<List<FundingPanelDetails>> _getFundingPanelsDetails =
      PublishSubject<List<FundingPanelDetails>>();

  Stream<List<FundingPanelDetails>> get outFundingPanelsDetails =>
      _getFundingPanelsDetails.stream;
  Sink<List<FundingPanelDetails>> get _inFundingPanelsDetails =>
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
      List maps = jsonDecode(prefs.getString('funding_panels_details'));
      List<FundingPanelDetails> fundingPanelsDetails = List();

      for (int i = 0; i < maps.length; i++) {
        fundingPanelsDetails.add(FundingPanelDetails(maps[i]['name'],
            maps[i]['description'], maps[i]['url'], maps[i]['imgBase64'], maps[i]['funding_panel_address']));
      }

      _inFundingPanelsDetails.add(fundingPanelsDetails);
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
      List maps = jsonDecode(prefs.getString('funding_panels_details'));
      List<FundingPanelDetails> fundingPanelsDetails = List();

      for (int i = 0; i < maps.length; i++) {
        fundingPanelsDetails.add(FundingPanelDetails(maps[i]['name'],
            maps[i]['description'], maps[i]['url'], maps[i]['imgBase64'], maps[i]['funding_panel_address']));
      }

      _inFundingPanelsDetails.add(fundingPanelsDetails);
    }
    );
  }

  void closeSubjects() {
    _getFundingPanelsDetails.close();
    _notificationsiOS.close();
  }
}
