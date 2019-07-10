import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:seed_venture/models/funding_panel_item.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:seed_venture/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'package:decimal/decimal.dart';
import 'package:seed_venture/models/basket_token_balance_item.dart';
import 'package:flutter/material.dart';

final BasketsBloc basketsBloc = BasketsBloc();

class BasketsBloc {
  BehaviorSubject<List<FundingPanelItem>> _getFundingPanelsDetails =
      BehaviorSubject<List<FundingPanelItem>>();

  Stream<List<FundingPanelItem>> get outFundingPanelsDetails =>
      _getFundingPanelsDetails.stream;
  Sink<List<FundingPanelItem>> get _inFundingPanelsDetails =>
      _getFundingPanelsDetails.sink;

  PublishSubject<List<String>> _notificationsiOS =
      PublishSubject<List<String>>();

  Stream<List<String>> get outNotificationsiOS => _notificationsiOS.stream;
  Sink<List<String>> get _inNotificationsiOS => _notificationsiOS.sink;

  BehaviorSubject<List<String>> _seedEthBalances =
      BehaviorSubject<List<String>>();

  Stream<List<String>> get outSeedEthBalance => _seedEthBalances.stream;
  Sink<List<String>> get _inSeedEthBalances => _seedEthBalances.sink;

  BehaviorSubject<List<BasketTokenBalanceItem>> _basketsTokenBalances =
      BehaviorSubject<List<BasketTokenBalanceItem>>();

  Stream<List<BasketTokenBalanceItem>> get outBasketTokenBalances =>
      _basketsTokenBalances.stream;
  Sink<List<BasketTokenBalanceItem>> get _inBasketTokenBalances =>
      _basketsTokenBalances.sink;

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  BasketsBloc() {
    getBasketsTokenBalances();

    // SEED and ETH balances fetching
    _getOldBalances();
    getCurrentBalances();

    // pre-load data for Baskets Page
    getBaskets();

    _initNotifications();
  }

  void _initNotifications() {
    flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    var initializationSettingsAndroid =
        new AndroidInitializationSettings('ic_launcher');
    var initializationSettingsIOS = new IOSInitializationSettings(
        onDidReceiveLocalNotification: onDidRecieveLocalNotification);
    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
  }

  Future<String> _getOldEthBalance() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('eth_balance');
  }

  void _getOldBalances() async {
    String oldSeedBalance = await _getOldSeedBalance();
    String oldEthBalance = await _getOldEthBalance();
    if (oldSeedBalance != null && oldEthBalance != null) {
      List<String> balances = List();
      balances.add(oldSeedBalance);
      balances.add(oldEthBalance);
      _inSeedEthBalances.add(balances);
    }
  }

  void getCurrentBalances() async {
    String seedBalance = await _getCurrentSeedBalance();
    String ethBalance = await _getCurrentEthBalance();
    List<String> balances = List();
    balances.add(seedBalance);
    balances.add(ethBalance);
    _inSeedEthBalances.add(balances);
  }

  Future<String> _getCurrentEthBalance() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String address = prefs.getString('address');

    Map callParams = {
      "id": "1",
      "jsonrpc": "2.0",
      "method": "eth_getBalance",
      "params": [address, "latest"]
    };

    var callResponse = await http.post(infuraHTTP,
        body: jsonEncode(callParams),
        headers: {'content-type': 'application/json'});

    Map resMap = jsonDecode(callResponse.body);

    String ethBalanceToShow = _getValueFromHex(resMap['result'].toString(), 18);

    prefs.setString('eth_balance', ethBalanceToShow);

    return ethBalanceToShow;
  }

  // Send old balance if not first start
  Future<String> _getOldSeedBalance() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('seed_balance');
  }

  Future<String> _getCurrentSeedBalance() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String address = prefs.getString('address').substring(2);

    String data = "0x70a08231";

    while (address.length != 64) {
      address = '0' + address;
    }

    data = data + address;

    var url = "https://ropsten.infura.io/v3/2f35010022614bcb9dd4c5fefa9a64fd";
    Map callParams = {
      "id": "1",
      "jsonrpc": "2.0",
      "method": "eth_call",
      "params": [
        {
          "to": SeedTokenAddress,
          "data": data,
        },
        "latest"
      ]
    };

    var callResponse = await http.post(url,
        body: jsonEncode(callParams),
        headers: {'content-type': 'application/json'});

    Map resMap = jsonDecode(callResponse.body);

    String seedBalanceToShow =
        _getValueFromHex(resMap['result'].toString(), 18);

    prefs.setString('seed_balance', seedBalanceToShow);

    return seedBalanceToShow;
  }

  String _getValueFromHex(String hexValue, int decimals) {
    hexValue = hexValue.substring(2);
    if (hexValue == '' || hexValue == '0') return '0.00';

    BigInt bigInt = BigInt.parse(hexValue, radix: 16);
    Decimal dec = Decimal.parse(bigInt.toString());
    Decimal x = dec / Decimal.fromInt(pow(10, decimals));
    String value = x.toString();
    if (value == '0') return '0.00';

    double doubleValue = double.parse(value);
    return doubleValue
        .toStringAsFixed(doubleValue.truncateToDouble() == doubleValue ? 0 : 2);
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
        0, 'SeedVenture', notificationData, platformChannelSpecifics,
        payload: '');
  }

  Future<void> onSelectNotification(String payload) async {
    if (payload != null) {
      //debugPrint('notification payload: ' + payload);
    }
  }

  Future<void> onDidRecieveLocalNotification(
      int id, String title, String body, String payload) {
    List<String> params = List();
    params[0] = title;
    params[0] = body;

    _inNotificationsiOS.add(params);
  }

  void getBaskets() {
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
            imgBase64: maps[i]['imgBase64'],
            name: maps[i]['name'],
            description: maps[i]['description'],
            url: maps[i]['url']));
      }

      _inFundingPanelsDetails.add(fundingPanelItems);
    });
  }

  void getBasketsTokenBalances() {
    List<BasketTokenBalanceItem> basketTokenBalances = List();

    SharedPreferences.getInstance().then((prefs) {
      List balancesMaps = jsonDecode(prefs.getString('user_baskets_balances'));

      for (int i = 0; i < balancesMaps.length; i++) {
        Map basketBalanceMap = balancesMaps[i];

        String balance = basketBalanceMap['token_balance'];
        String symbol = basketBalanceMap['token_symbol'];
        bool isWhitelisted = basketBalanceMap['is_whitelisted'];
        String fundingPanelAddress = basketBalanceMap['funding_panel_address'];

        Image tokenLogo;

        if (basketBalanceMap['imgBase64'] != '') {
          tokenLogo = Image.memory(base64Decode(basketBalanceMap['imgBase64']),
              width: 35.0, height: 35.0);
        } else {
          tokenLogo = Image.asset(
            'assets/watermelon.png',
            height: 35.0,
            width: 35.0,
          );
        }

        basketTokenBalances.add(BasketTokenBalanceItem(
            symbol: symbol,
            balance: balance,
            tokenLogo: tokenLogo,
            isWhitelisted: isWhitelisted,
        fpAddress: fundingPanelAddress));
      }

      _inBasketTokenBalances.add(basketTokenBalances);
    });
  }

  void closeSubjects() {
    _getFundingPanelsDetails.close();
    _notificationsiOS.close();
  }
}
