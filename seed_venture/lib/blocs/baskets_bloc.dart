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
import 'package:seed_venture/utils/utils.dart';

final BasketsBloc basketsBloc = BasketsBloc();

class BasketsBloc {
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

  BehaviorSubject<FundingPanelItem> _singleFundingPanelData =
      BehaviorSubject<FundingPanelItem>();

  Stream<FundingPanelItem> get outSingleFundingPanelData =>
      _singleFundingPanelData.stream;
  Sink<FundingPanelItem> get _inSingleFundingPanelData =>
      _singleFundingPanelData.sink;

  BehaviorSubject<List<BasketTokenBalanceItem>> _favoritesBasketsTokenBalances =
      BehaviorSubject<List<BasketTokenBalanceItem>>();

  Stream<List<BasketTokenBalanceItem>> get outFavoritesBasketsTokenBalances =>
      _favoritesBasketsTokenBalances.stream;
  Sink<List<BasketTokenBalanceItem>> get _inFavoritesBasketsTokenBalances =>
      _favoritesBasketsTokenBalances.sink;

  // Used to avoid reloading base64 images (flickering)
  List<BasketTokenBalanceItem> _prevBasketTokenBalances;

  // Used to avoid reloading base64 images (flickering)
  List<BasketTokenBalanceItem> _prevBasketTokenBalancesFavorites;

  // Address of last funding panel opened by the user
  String _currentFundingPanelAddress;

  // Last funding panel opened by the user
  FundingPanelItem _currentFundingPanelItem;

  List _favorites;

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  BasketsBloc() {
    getBasketsTokenBalances();

    // SEED and ETH balances fetching
    _getOldBalances();
    getCurrentBalances();

    _initNotifications();
  }

  String getCurrentFundingPanelAddress() {
    return _currentFundingPanelAddress;
  }

  void updateAfterContribute() {
    // _currentFundingPanelAddress will be the fp the user contributed to
    getCurrentBalances();
  }

  void getSingleBasketData(String fundingPanelAddress) {
    SharedPreferences.getInstance().then((prefs) {
      List maps = jsonDecode(prefs.getString('funding_panels_data'));
      FundingPanelItem basket;

      for (int i = 0; i < maps.length; i++) {
        // no need for members in this case

        if (maps[i]['funding_panel_address'].toString().toLowerCase() ==
            fundingPanelAddress.toLowerCase()) {
          bool favorite = false;
          ;
          List favorites = prefs.getStringList('favorites');
          if (favorites.contains(fundingPanelAddress.toLowerCase()))
            favorite = true;

          bool isWhitelisted;
          bool isBlacklisted;

          for (int i = 0; i < _prevBasketTokenBalances.length; i++) {
            if (_prevBasketTokenBalances[i].fpAddress.toLowerCase() ==
                fundingPanelAddress.toLowerCase()) {
              isWhitelisted = _prevBasketTokenBalances[i].isWhitelisted;
              isBlacklisted = _prevBasketTokenBalances[i].isBlacklisted;
              break;
            }
          }

          basket = FundingPanelItem(
              favorite: favorite,
              tags: maps[i]['tags'],
              documents: maps[i]['documents'],
              tokenAddress: maps[i]['token_address'],
              fundingPanelAddress: maps[i]['funding_panel_address'],
              adminToolsAddress: maps[i]['admin_tools_address'],
              latestDexQuotation: maps[i]['latest_dex_price'],
              imgBase64: maps[i]['imgBase64'],
              seedWhitelistThreshold: maps[i]['seed_whitelist_threshold'],
              name: maps[i]['name'],
              description: maps[i]['description'],
              whitelisted: isWhitelisted,
              blacklisted: isBlacklisted,
              url: maps[i]['url']);

          break;
        }
      }

      _inSingleFundingPanelData.add(basket);
      this._currentFundingPanelAddress = fundingPanelAddress;
      this._currentFundingPanelItem = basket;
    });
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
        onSelectNotification: _onSelectNotification);
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

    var callResponse = await http.post(infuraHTTP,
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
    await _launchNotification(notificationData);
  }

  Future<void> _launchNotification(String notificationData) async {
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

  Future<void> _onSelectNotification(String payload) async {
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

  /*void getBaskets() {
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
  }*/

  void getFavoritesBasketsTokenBalances() {
    List<BasketTokenBalanceItem> basketTokenBalances = List();

    SharedPreferences.getInstance().then((prefs) {
      List balancesMaps = jsonDecode(prefs.getString('user_baskets_balances'));
      List favorites = prefs.getStringList('favorites');

      for (int i = 0; i < balancesMaps.length; i++) {
        Map basketBalanceMap = balancesMaps[i];

        String fundingPanelAddress = basketBalanceMap['funding_panel_address'];

        if (favorites.contains(fundingPanelAddress.toLowerCase())) {
          String name = basketBalanceMap['name'];
          String balance = basketBalanceMap['token_balance'];
          String symbol = basketBalanceMap['token_symbol'];
          bool isWhitelisted = basketBalanceMap['is_whitelisted'];
          bool isBlacklisted = basketBalanceMap['is_blacklisted'];
          String imgBase64 = basketBalanceMap['imgBase64'];
          List tags = basketBalanceMap['basket_tags'];

          Image tokenLogo;

          if (_prevBasketTokenBalances != null &&
              _prevBasketTokenBalances.length > i &&
              _prevBasketTokenBalances[i].imgBase64 == imgBase64) {
            tokenLogo = _prevBasketTokenBalances[i].tokenLogo;
          } else {
            tokenLogo = Utils.getImageFromBase64(basketBalanceMap['imgBase64']);
          }

          basketTokenBalances.add(BasketTokenBalanceItem(
            name: name,
            basketTags: tags,
            symbol: symbol,
            balance: balance,
            tokenLogo: tokenLogo,
            isWhitelisted: isWhitelisted,
            isBlacklisted: isBlacklisted,
            fpAddress: fundingPanelAddress,
            imgBase64: imgBase64,
          ));
        }
      }

      _prevBasketTokenBalancesFavorites = basketTokenBalances;
      _favorites = favorites;
      _inFavoritesBasketsTokenBalances.add(basketTokenBalances);
    });
  }

  void getBasketsTokenBalances() {
    List<BasketTokenBalanceItem> basketTokenBalances = List();

    SharedPreferences.getInstance().then((prefs) {
      List balancesMaps = jsonDecode(prefs.getString('user_baskets_balances'));

      for (int i = 0; i < balancesMaps.length; i++) {
        Map basketBalanceMap = balancesMaps[i];

        String name = basketBalanceMap['name'];
        String balance = basketBalanceMap['token_balance'];
        String symbol = basketBalanceMap['token_symbol'];
        bool isWhitelisted = basketBalanceMap['is_whitelisted'];
        bool isBlacklisted = basketBalanceMap['is_blacklisted'];
        String fundingPanelAddress = basketBalanceMap['funding_panel_address'];
        String imgBase64 = basketBalanceMap['imgBase64'];
        List tags = basketBalanceMap['basket_tags'];

        Image tokenLogo;

        if (_prevBasketTokenBalances != null &&
            _prevBasketTokenBalances.length > i &&
            _prevBasketTokenBalances[i].imgBase64 == imgBase64) {
          tokenLogo = _prevBasketTokenBalances[i].tokenLogo;
        } else {
          tokenLogo = Utils.getImageFromBase64(basketBalanceMap['imgBase64']);
        }

        basketTokenBalances.add(BasketTokenBalanceItem(
          name: name,
          basketTags: tags,
          symbol: symbol,
          balance: balance,
          tokenLogo: tokenLogo,
          isWhitelisted: isWhitelisted,
          isBlacklisted: isBlacklisted,
          fpAddress: fundingPanelAddress,
          imgBase64: imgBase64,
        ));
      }

      _prevBasketTokenBalances = basketTokenBalances;
      _inBasketTokenBalances.add(basketTokenBalances);
    });
  }

  void dispose() {
    //_getFundingPanelsDetails.close();
    _notificationsiOS.close();
    _seedEthBalances.close();
    _basketsTokenBalances.close();
    _singleFundingPanelData.close();
    _favoritesBasketsTokenBalances.close();
  }

  List getFilteredItems(String searchText) {
    if (searchText == '') return _prevBasketTokenBalances;
    List items = List();
    for (int i = 0; i < _prevBasketTokenBalances.length; i++) {
      /*if(_prevBasketTokenBalances[i].basketTags.contains(searchText)){
        items.add(_prevBasketTokenBalances[i]);
      }*/

      /*else if(_prevBasketTokenBalances[i].symbol.toLowerCase() == searchText.toLowerCase()) {
    items.add(_prevBasketTokenBalances[i]);
    }
    else if(_prevBasketTokenBalances[i].name.toLowerCase() == searchText.toLowerCase()) {
    items.add(_prevBasketTokenBalances[i]);
    }*/

      bool added = false;
      _prevBasketTokenBalances[i].basketTags.forEach((tag) {
        if (!added &&
            tag.toString().toLowerCase().contains(searchText.toLowerCase())) {
          items.add(_prevBasketTokenBalances[i]);
          added = true;
        }
      });

      if (_prevBasketTokenBalances[i].name == null) print('NAME IS NULL!!!!!');

      if (!added) {
        if (_prevBasketTokenBalances[i]
            .symbol
            .toLowerCase()
            .contains(searchText.toLowerCase())) {
          items.add(_prevBasketTokenBalances[i]);
        } else if (_prevBasketTokenBalances[i].name != null &&
            _prevBasketTokenBalances[i]
                .name
                .toLowerCase()
                .contains(searchText.toLowerCase())) {
          items.add(_prevBasketTokenBalances[i]);
        }
      }
    }
    return items;
  }

  List getFilteredItemsFavorites(String searchText) {
    if (searchText == '') return _prevBasketTokenBalancesFavorites;
    List items = List();
    for (int i = 0; i < _prevBasketTokenBalancesFavorites.length; i++) {
      if (_favorites.contains(
          _prevBasketTokenBalancesFavorites[i].fpAddress.toLowerCase())) {
        bool added = false;
        _prevBasketTokenBalancesFavorites[i].basketTags.forEach((tag) {
          if (!added &&
              tag.toString().toLowerCase().contains(searchText.toLowerCase())) {
            items.add(_prevBasketTokenBalancesFavorites[i]);
            added = true;
          }
        });

        if (_prevBasketTokenBalancesFavorites[i].name == null)
          print('NAME IS NULL!!!!!');

        if (!added) {
          if (_prevBasketTokenBalancesFavorites[i]
              .symbol
              .toLowerCase()
              .contains(searchText.toLowerCase())) {
            items.add(_prevBasketTokenBalancesFavorites[i]);
          } else if (_prevBasketTokenBalancesFavorites[i].name != null &&
              _prevBasketTokenBalancesFavorites[i]
                  .name
                  .toLowerCase()
                  .contains(searchText.toLowerCase())) {
            items.add(_prevBasketTokenBalancesFavorites[i]);
          }
        }
      }
    }
    return items;
  }

  void setFavorite() {
    SharedPreferences.getInstance().then((prefs) {
      List favorites = prefs.getStringList('favorites');
      favorites.add(_currentFundingPanelAddress.toLowerCase());
      prefs.setStringList('favorites', favorites);

      _currentFundingPanelItem.setFavorite(true);
      _inSingleFundingPanelData.add(_currentFundingPanelItem);
    });
  }

  void removeFromFavorites() {
    SharedPreferences.getInstance().then((prefs) {
      List favorites = prefs.getStringList('favorites');
      for (int i = 0; i < favorites.length; i++) {
        if (favorites[i] == _currentFundingPanelAddress.toLowerCase()) {
          favorites.removeAt(i);
          break;
        }
      }
      prefs.setStringList('favorites', favorites);

      _currentFundingPanelItem.setFavorite(false);
      _inSingleFundingPanelData.add(_currentFundingPanelItem);
      getFavoritesBasketsTokenBalances();
    });
  }
}
