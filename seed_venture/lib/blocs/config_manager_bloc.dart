import 'package:web3dart/web3dart.dart';
import 'package:hex/hex.dart';
import 'package:flutter/services.dart';
import 'package:seed_venture/models/funding_panel_item.dart';
import 'package:seed_venture/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import "package:web3dart/src/utils/numbers.dart" as numbers;
import 'package:crypto/crypto.dart' as crypto;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seed_venture/blocs/onboarding_bloc.dart';
import 'dart:async';
import 'package:seed_venture/blocs/baskets_bloc.dart';
import 'package:seed_venture/models/member_item.dart';
import 'package:seed_venture/blocs/settings_bloc.dart';
import 'package:decimal/decimal.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';

final ConfigManagerBloc configManagerBloc = ConfigManagerBloc();

class ConfigManagerBloc {
  Map _previousConfigurationMap;
  List<FundingPanelItem> _fundingPanelItems;
  int _fromBlockAgain;
  int _toBlockForced;
  Map _resMapLogsDEX;
  bool _logsResultsExceeded = false;
  bool _hasToUpdate = true;
  Timer _balancesUpdateTimer;

  /// Configuration creation and update section

  void _saveAddress(Credentials credentials) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('address', credentials.address.hex);
    });
  }

  void _saveSHA256Pass(String password) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('sha256_pass',
          crypto.sha256.convert(utf8.encode(password)).toString());
    });
  }

  void setFundingPanels(List fundingPanels) {
    this._fundingPanelItems = fundingPanels;
  }

  Future createConfiguration(
      Credentials walletCredentials, String password) async {
    _saveAddress(walletCredentials);
    _saveSHA256Pass(password);

    Map configurationMap = Map();
    List<FundingPanelItem> fundingPanelItems = List();

    Map localMap = {
      'lang_config_stuff': {'name': 'English (England)', 'code': 'en_EN'}
    };
    configurationMap.addAll(localMap);

    int currentBlockNumber = await getCurrentBlockNumber();
    Map lastCheckedBlockNumberMap = {
      'lastCheckedBlockNumber': currentBlockNumber
    };
    configurationMap.addAll(lastCheckedBlockNumberMap);

    Map additionalInfo = {
      'seedTokenAddress': SeedTokenAddress,
      'factoryAddress': GlobalFactoryAddress,
      'dexAddress': DexAddress,
      'gasPrice': DefaultGasPrice,
      'gasLimit': DefaultGasLimit,
    };

    configurationMap.addAll(additionalInfo);

    await getFundingPanelItems(
        fundingPanelItems, configurationMap, currentBlockNumber);

    Map userMapDecrypted = {
      'privateKey': walletCredentials.privateKey.toRadixString(16),
      'wallet': walletCredentials.address.hex,
      'list': []
    };

    String realPass = _generateMd5(password);
    String plainData = jsonEncode(userMapDecrypted);

    var platform = MethodChannel('seedventure.io/aes');

    var encryptedData = await platform.invokeMethod('encrypt',
        {"plainData": plainData, "realPass": realPass.toUpperCase()});

    var encryptedDataBase64 = base64.encode(utf8.encode(encryptedData));

    var hash = crypto.sha256
        .convert(utf8.encode(walletCredentials.address.hex.toLowerCase()));

    Map userMapEncrypted = {
      'user': {'data': encryptedDataBase64, 'hash': hash.toString()}
    };

    configurationMap.addAll(userMapEncrypted);

    _saveConfigurationFile(configurationMap);

    this._fundingPanelItems = fundingPanelItems;

    await getBasketTokensBalances(fundingPanelItems, creatingConfig: true);

    OnBoardingBloc.setOnBoardingDone();
  }

  String _generateMd5(String input) {
    return crypto.md5.convert(utf8.encode(input)).toString();
  }

  static Future<String> _getSeedMaxSupplyFromPreviousSharedPref(
      String fundingPanelAddress) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (prefs.getString('funding_panels_data') == null) return null;

    List maps = jsonDecode(prefs.getString('funding_panels_data'));

    for (int i = 0; i < maps.length; i++) {
      if (maps[i]['funding_panel_address'].toString().toLowerCase() ==
          fundingPanelAddress.toLowerCase()) {
        String seedMaxSupply = maps[i]['seed_max_supply'];
        return seedMaxSupply;
      }
    }

    return null;
  }

  static Future<double> _getExchangeRateSeedFromPreviousSharedPref(
      String fundingPanelAddress) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (prefs.getString('funding_panels_data') == null) return null;

    List maps = jsonDecode(prefs.getString('funding_panels_data'));

    for (int i = 0; i < maps.length; i++) {
      if (maps[i]['funding_panel_address'].toString().toLowerCase() ==
          fundingPanelAddress.toLowerCase()) {
        double exchangeRateSeed = maps[i]['seed_exchange_rate'];
        return exchangeRateSeed;
      }
    }

    return null;
  }

  static Future<double> _getExchangeRateOnTopFromPreviousSharedPref(
      String fundingPanelAddress) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (prefs.getString('funding_panels_data') == null) return null;

    List maps = jsonDecode(prefs.getString('funding_panels_data'));

    for (int i = 0; i < maps.length; i++) {
      if (maps[i]['funding_panel_address'].toString().toLowerCase() ==
          fundingPanelAddress.toLowerCase()) {
        double exchangeRateOnTop = maps[i]['exchange_rate_on_top'];
        return exchangeRateOnTop;
      }
    }

    return null;
  }

  static Future<double> _getExchangeRateSeedDEXFromPreviousSharedPref(
      String fundingPanelAddress) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (prefs.getString('funding_panels_data') == null) return null;

    List maps = jsonDecode(prefs.getString('funding_panels_data'));

    for (int i = 0; i < maps.length; i++) {
      if (maps[i]['funding_panel_address'].toString().toLowerCase() ==
          fundingPanelAddress.toLowerCase()) {
        double exchangeRateSeed = maps[i]['seed_exchange_rate_dex'];
        return exchangeRateSeed;
      }
    }

    return null;
  }

  static Future<double> _getWLThresholdFromPreviousSharedPref(
      String fundingPanelAddress) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (prefs.getString('funding_panels_data') == null) return null;

    List maps = jsonDecode(prefs.getString('funding_panels_data'));

    for (int i = 0; i < maps.length; i++) {
      if (maps[i]['funding_panel_address'].toString().toLowerCase() ==
          fundingPanelAddress.toLowerCase()) {
        double threshold = maps[i]['whitelist_threshold'];
        return threshold;
      }
    }

    return null;
  }

  static Future<List<MemberItem>> _getMembersFromPreviousSharedPref(
      String fundingPanelAddress) async {
    List<MemberItem> members = List();
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (prefs.getString('funding_panels_data') == null) return null;

    List maps = jsonDecode(prefs.getString('funding_panels_data'));

    for (int i = 0; i < maps.length; i++) {
      if (maps[i]['funding_panel_address'].toString().toLowerCase() ==
          fundingPanelAddress.toLowerCase()) {
        List memberMaps = maps[i]['members'];

        for (int j = 0; j < memberMaps.length; j++) {
          members.add(MemberItem(
            memberAddress: memberMaps[j]['member_address'],
            fundingPanelAddress: memberMaps[j]['funding_panel_address'],
            ipfsUrl: memberMaps[j]['ipfsUrl'],
            hash: memberMaps[j]['hash'],
            name: memberMaps[j]['name'],
            description: memberMaps[j]['description'],
            documents: memberMaps[j]['documents'],
            url: memberMaps[j]['url'],
            imgBase64: memberMaps[j]['imgBase64'],
            seedsUnlocked: memberMaps[j]['seeds_unlocked'],
          ));
        }

        return members;
      }
    }

    return null;
  }

  static Future<MemberItem> _getSingleMemberFromPreviousSharedPref(
      String fundingPanelAddress, String memberAddress) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (prefs.getString('funding_panels_data') == null) return null;

    List maps = jsonDecode(prefs.getString('funding_panels_data'));

    for (int i = 0; i < maps.length; i++) {
      if (maps[i]['funding_panel_address'].toString().toLowerCase() ==
          fundingPanelAddress.toLowerCase()) {
        List memberMaps = maps[i]['members'];

        for (int j = 0; j < memberMaps.length; j++) {
          if (memberMaps[j]['member_address'].toString().toLowerCase() ==
              memberAddress.toLowerCase()) {
            return MemberItem(
              memberAddress: memberMaps[j]['member_address'],
              fundingPanelAddress: memberMaps[j]['funding_panel_address'],
              ipfsUrl: memberMaps[j]['ipfsUrl'],
              hash: memberMaps[j]['hash'],
              name: memberMaps[j]['name'],
              description: memberMaps[j]['description'],
              documents: memberMaps[j]['documents'],
              url: memberMaps[j]['url'],
              imgBase64: memberMaps[j]['imgBase64'],
              seedsUnlocked: memberMaps[j]['seeds_unlocked'],
            );
          }
        }
      }
    }

    return null;
  }

  static Future<List<String>> _getMembersAddressListFromPreviousSharedPref(
      String fundingPanelAddress) async {
    List<String> addressList = List();
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (prefs.getString('funding_panels_data') == null) return null;

    List maps = jsonDecode(prefs.getString('funding_panels_data'));

    for (int i = 0; i < maps.length; i++) {
      if (maps[i]['funding_panel_address'].toString().toLowerCase() ==
          fundingPanelAddress.toLowerCase()) {
        List memberMaps = maps[i]['members'];

        for (int j = 0; j < memberMaps.length; j++) {
          addressList.add(memberMaps[j]['member_address']);
        }

        return addressList;
      }
    }

    return null;
  }

  static Future<Map> _getLatestOwnerDataFromPreviousSharedPref(
      String fundingPanelAddress) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (prefs.getString('funding_panels_data') == null) return null;

    List maps = jsonDecode(prefs.getString('funding_panels_data'));

    for (int i = 0; i < maps.length; i++) {
      if (maps[i]['funding_panel_address'].toString().toLowerCase() ==
          fundingPanelAddress.toLowerCase()) {
        return maps[i]['latest_owner_data'];
      }
    }

    return null;
  }

  static Future<String> _getSeedTotalRaisedFromPreviousSharedPref(
      String fundingPanelAddress) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (prefs.getString('funding_panels_data') == null) return null;

    List maps = jsonDecode(prefs.getString('funding_panels_data'));

    for (int i = 0; i < maps.length; i++) {
      if (maps[i]['funding_panel_address'].toString().toLowerCase() ==
          fundingPanelAddress.toLowerCase()) {
        return maps[i]['seed_total_raised'];
      }
    }

    return null;
  }

  static Future<FundingPanelItem> _handleNewPanel(
      Map addressMap, int fromBlock, int toBlock, Map logResponseMap) async {
    String fundingPanelAddress = addressMap['funding_panel_address'];
    String adminToolsAddress = addressMap['admin_tools_address'];
    String tokenAddress = addressMap['token_address'];

    String seedMaxSupply = await _getSeedMaxSupply(fundingPanelAddress);

    if (seedMaxSupply == '0.00') return null; // skip zero-supply funding panels

    Map latestOwnerData = await _getLatestOwnerData(fundingPanelAddress);

    List fundingPanelVisualData =
        await _getFundingPanelDetails(latestOwnerData['url']);

    if (fundingPanelVisualData == null) {
      return null;
    }

    List retParams = await _getBasketSeedExchangeRateFromDEX(
        tokenAddress, fromBlock, toBlock, logResponseMap);
    double exchangeRateSeedDEX;
    //this._resMapLogsDEX = resMap;

    if (retParams != null) exchangeRateSeedDEX = retParams[0];

    double exchangeRateSeed =
        await _getBasketSeedExchangeRate(fundingPanelAddress);

    double exchangeRateOnTop =
        await _getBasketExchangeRateOnTop(fundingPanelAddress);

    String seedTotalRaised = await _getSeedTotalRaised(fundingPanelAddress);
    //String seedLiquidity = await _getSeedLiquidity(fundingPanelAddress);

    double threshold =
        await _getWhitelistThreshold(adminToolsAddress, exchangeRateSeed);

    List documents = List();

    if (fundingPanelVisualData[4] != null && fundingPanelVisualData[4] != '') {
      List documentMaps = jsonDecode(fundingPanelVisualData[4]);
      documentMaps.forEach((document) {
        documents.add(document);
      });
    }

    List tags = List();

    if (fundingPanelVisualData[5] != null && fundingPanelVisualData[5] != '') {
      List tagMaps = jsonDecode(fundingPanelVisualData[5]);
      tagMaps.forEach((tag) {
        String tagRepl = tag.toString().replaceAll('_', ' ');
        tagRepl = tagRepl.replaceAll('-', ' ');
        tags.add(tagRepl);
      });
    }

    double basketSuccessFee;

    if (fundingPanelVisualData[6] != null && fundingPanelVisualData[6] != '') {
      basketSuccessFee = double.parse(fundingPanelVisualData[6]);
    }

    List<MemberItem> members =
        await _getMembersOfFundingPanel(fundingPanelAddress);

    double totalUnlockedForStartup = 0;

    for (int i = 0; i < members.length; i++) {
      totalUnlockedForStartup += double.parse(members[i].seedsUnlocked);
    }

    FundingPanelItem FPItem = FundingPanelItem(
        totalUnlockedForStartup: totalUnlockedForStartup.toString(),
        seedTotalRaised: seedTotalRaised,
        whitelistThreshold: threshold,
        adminToolsAddress: adminToolsAddress,
        tokenAddress: tokenAddress,
        fundingPanelAddress: fundingPanelAddress,
        latestOwnerData: latestOwnerData,
        seedMaxSupply: seedMaxSupply,
        seedExchangeRate: exchangeRateSeed,
        seedExchangeRateDEX: exchangeRateSeedDEX,
        exchangeRateOnTop: exchangeRateOnTop,
        name: fundingPanelVisualData[0],
        description: fundingPanelVisualData[1],
        url: fundingPanelVisualData[2],
        imgBase64: fundingPanelVisualData[3],
        members: members,
        tags: tags,
        documents: documents,
        basketSuccessFee: basketSuccessFee);

    return FPItem;
  }

  static void _addToFPCheckAgainList(String fundingPanelAddress,
      String adminToolsAddress, String tokenAddress) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    if (sharedPreferences.getString('fp_check_again_list') == null) {
      sharedPreferences.setString('fp_check_again_list', jsonEncode(List()));
    }
    List fpToCheckAgainList =
        jsonDecode(sharedPreferences.getString('fp_check_again_list'));

    bool found = false;

    for (int i = 0; i < fpToCheckAgainList.length; i++) {
      Map map = fpToCheckAgainList[i];
      if (map['funding_panel_address'].toString().toLowerCase() ==
          fundingPanelAddress.toLowerCase()) {
        found = true;
        break;
      }
    }

    if (!found) {
      Map fpToCheckAgain = {
        'funding_panel_address': fundingPanelAddress,
        'admin_tools_address': adminToolsAddress,
        'token_address': tokenAddress,
      };

      fpToCheckAgainList.add(fpToCheckAgain);

      sharedPreferences.setString(
          'fp_check_again_list', jsonEncode(fpToCheckAgainList));
    }
  }

  static void _addToMembersCheckAgainList(
      String fundingPanelAddress, String memberAddress) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    if (sharedPreferences.getString('members_check_again_list') == null) {
      sharedPreferences.setString(
          'members_check_again_list', jsonEncode(List()));
    }
    List membersToCheckAgainList =
        jsonDecode(sharedPreferences.getString('members_check_again_list'));

    bool found = false;

    for (int i = 0; i < membersToCheckAgainList.length; i++) {
      Map map = membersToCheckAgainList[i];
      if (map['member_address'].toString().toLowerCase() ==
          memberAddress.toLowerCase()) {
        found = true;
        break;
      }
    }

    if (!found) {
      Map fpToCheckAgain = {
        'funding_panel_address': fundingPanelAddress,
        'member_address': memberAddress,
      };

      membersToCheckAgainList.add(fpToCheckAgain);

      sharedPreferences.setString(
          'members_check_again_list', jsonEncode(membersToCheckAgainList));
    }
  }

  static Future<List<MemberItem>> _checkAgainMembers(
      List<MemberItem> members, String fundingPanelAddress) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    if (sharedPreferences.getString('members_check_again_list') == null) {
      sharedPreferences.setString(
          'members_check_again_list', jsonEncode(List()));
    }
    List membersToCheckAgainList =
        jsonDecode(sharedPreferences.getString('members_check_again_list'));

    for (int i = 0; i < membersToCheckAgainList.length; i++) {
      Map map = membersToCheckAgainList[i];
      if (map['funding_panel_address'].toString().toLowerCase() ==
          fundingPanelAddress.toLowerCase()) {
        List<String> memberData = await _getMemberDataByAddress(
            fundingPanelAddress, map['member_address']);
        List<String> memberJsonData =
            await _getMemberJSONDataFromIPFS(memberData[0]);

        if (memberJsonData != null) {
          List documents = List();

          if (memberJsonData[4] != null && memberJsonData[4] != '') {
            List documentMaps = jsonDecode(memberJsonData[4]);
            documentMaps.forEach((document) {
              documents.add(document);
            });
          }

          bool contained = false;
          int index;
          for (int k = 0; k < members.length; k++) {
            if (map['member_address'].toString().toLowerCase() ==
                members[k].memberAddress.toLowerCase()) {
              contained = true;
              index = k;
              break;
            }
          }
          if (!contained) {
            members.add(MemberItem(
                seedsUnlocked: memberData[2],
                memberAddress: map['member_address'],
                fundingPanelAddress: fundingPanelAddress,
                ipfsUrl: memberData[0],
                hash: memberData[1],
                name: memberJsonData[0],
                description: memberJsonData[1],
                url: memberJsonData[2],
                documents: documents,
                imgBase64: memberJsonData[3]));
          } else {
            members[index].seedsUnlocked = memberData[2];
            members[index].ipfsUrl = memberData[0];
            members[index].hash = memberData[1];
            members[index].name = memberJsonData[0];
            members[index].description = memberJsonData[1];
            members[index].url = memberJsonData[2];
            members[index].documents = documents;
            members[index].imgBase64 = memberJsonData[3];
          }

          membersToCheckAgainList.removeAt(i);
        }
      }
    }

    sharedPreferences.setString(
        'members_check_again_list', jsonEncode(membersToCheckAgainList));
    return members;
  }

  // address maps is a JSON array with objects like {FPAddress: "", ATAddress: "", TAddress = ""}
  static Future<List> _getLogsUpdate(List params) async {
    List addressMaps = params[0];
    List addressList = params[1];
    int fromBlock = params[2];
    int toBlock = params[3];
    Map configurationMap = params[4];
    List fundingPanelItemsPrev = params[5];

    bool _logsResultsExceeded = false;

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    List favorites = sharedPreferences.getStringList('favorites');
    List<FundingPanelItem> fundingPanelItems = List();
    List<Map> fpMapsConfigFile = List();
    List<Map> fpMapsSharedPrefs = List();

    String fromBlockHex = numbers.toHex(fromBlock);
    String toBlockHex = numbers.toHex(toBlock);

    Map callParams = {
      "id": "1",
      "jsonrpc": "2.0",
      "method": "eth_getLogs",
      "params": [
        {
          "fromBlock": '0x' + fromBlockHex,
          "toBlock": '0x' + toBlockHex,
          "address": addressList,
          "topics": []
        },
      ]
    };

    var callResponse;

    try {
      callResponse = await http.post(infuraHTTP,
          body: jsonEncode(callParams),
          headers: {'content-type': 'application/json'});
    } catch (e) {
      print('error http');
      return null;
    }

    Map resMap = jsonDecode(callResponse.body);

    if (resMap['error'] != null &&
        resMap['error']['message'].toString().contains('query returned more')) {
      _logsResultsExceeded = true;
      return null;
    } else
      _logsResultsExceeded = false;

    List result = resMap['result'];

    // Check for new funding panels created

    for (int i = 0; i < result.length; i++) {
      if (result[i]['topics'].contains(newPanelCreatedTopic)) {
        // New Funding Panel was created

        String data = result[i]['data'].toString().substring(2);

        String ATAddress = EthereumAddress(data.substring(64, 128)).hex;
        String TAddress = EthereumAddress(data.substring(128, 192)).hex;
        String FPAddress = EthereumAddress(data.substring(192, 256)).hex;

        Map addressMap = {
          'funding_panel_address': FPAddress,
          'admin_tools_address': ATAddress,
          'token_address': TAddress,
          'new_added': true,
        };

        addressMaps.add(addressMap);
      }
    }

    if (sharedPreferences.getString('fp_check_again_list') == null)
      sharedPreferences.setString('fp_check_again_list', jsonEncode(List()));

    List fpToCheckAgainList =
        jsonDecode(sharedPreferences.getString('fp_check_again_list'));
    for (int i = 0; i < fpToCheckAgainList.length; i++) {
      Map addressMap = {
        'funding_panel_address': fpToCheckAgainList[i]['funding_panel_address'],
        'admin_tools_address': fpToCheckAgainList[i]['admin_tools_address'],
        'token_address': fpToCheckAgainList[i]['token_address'],
        'new_added': true,
      };

      addressMaps.add(addressMap);
    }

    for (int i = 0; i < addressMaps.length; i++) {
      String fundingPanelAddress = addressMaps[i]['funding_panel_address'];
      String adminToolsAddress = addressMaps[i]['admin_tools_address'];
      String tokenAddress = addressMaps[i]['token_address'];

      if (addressMaps[i]['new_added'] != null && addressMaps[i]['new_added']) {
        FundingPanelItem FPItem =
            await _handleNewPanel(addressMaps[i], fromBlock, toBlock, resMap);

        if (FPItem != null) {
          for (int k = 0; k < fpToCheckAgainList.length; k++) {
            Map map = fpToCheckAgainList[k];
            if (map['funding_panel_address'].toString().toLowerCase() ==
                FPItem.fundingPanelAddress.toLowerCase()) {
              fpToCheckAgainList.removeAt(k);
              sharedPreferences.setString(
                  'fp_check_again_list', jsonEncode(fpToCheckAgainList));
              break;
            }
          }

          fundingPanelItems.add(FPItem);

          List<Map> memberMapsConfigFile = List();
          List<Map> membersMapsSharedPrefs = List();

          List members = FPItem.members;

          for (int i = 0; i < members.length; i++) {
            Map memberMapConfigFile = {
              'memberAddress': members[i].memberAddress,
              'memberName': members[i].name,
              'latestIPFSUrl': members[i].ipfsUrl,
              'latestHash': members[i].hash,
            };

            memberMapsConfigFile.add(memberMapConfigFile);

            Map memberMapSP = {
              'member_address': members[i].memberAddress,
              'ipfsUrl': members[i].ipfsUrl,
              'hash': members[i].hash,
              'name': members[i].name,
              'description': members[i].description,
              'url': members[i].url,
              'imgBase64': members[i].imgBase64,
              'documents': members[i].documents,
              'seeds_unlocked': members[i].seedsUnlocked
            };

            membersMapsSharedPrefs.add(memberMapSP);
          }

          Map fpMapConfig = {
            'tokenAddress': FPItem.tokenAddress,
            'fundingPanelAddress': FPItem.fundingPanelAddress,
            'adminsToolsAddress': FPItem.adminToolsAddress,
            'fundingPanelName': FPItem.name,
            'seedExchangeRate': FPItem.seedExchangeRate,
            'seedExchangeRateDEX': FPItem.seedExchangeRateDEX,
            'exchangeRateOnTop': FPItem.exchangeRateOnTop,
            'fundingPanelData': FPItem.latestOwnerData,
            'whitelistThreshold': FPItem.whitelistThreshold,
            'seedMaxSupply': FPItem.seedMaxSupply,
            'members': memberMapsConfigFile
          };

          fpMapsConfigFile.add(fpMapConfig);

          Map fpMapSP = {
            'name': FPItem.name,
            'description': FPItem.description,
            'url': FPItem.url,
            'imgBase64': FPItem.imgBase64,
            'funding_panel_address': FPItem.fundingPanelAddress,
            'token_address': FPItem.tokenAddress,
            'admin_tools_address': FPItem.adminToolsAddress,
            'latest_owner_data': FPItem.latestOwnerData,
            'seed_exchange_rate': FPItem.seedExchangeRate,
            'seed_exchange_rate_dex': FPItem.seedExchangeRateDEX,
            'exchange_rate_on_top': FPItem.exchangeRateOnTop,
            'tags': FPItem.tags,
            'whitelist_threshold': FPItem.whitelistThreshold,
            'seed_total_raised': FPItem.seedTotalRaised,
            'seed_max_supply': FPItem.seedMaxSupply,
            'total_unlocked': FPItem.totalUnlockedForStartup,
            'documents': FPItem.documents,
            'basket_success_fee': FPItem.basketSuccessFee,
            'members': membersMapsSharedPrefs
          };

          fpMapsSharedPrefs.add(fpMapSP);

          String notificationData = 'Basket ' + FPItem.name + ' added!';
          basketsBloc.notification(notificationData);
        }
      } else {
        Map latestOwnerData;
        String seedMaxSupply;
        List fundingPanelVisualData;
        double exchangeRateSeed;
        double exchangeRateSeedDEX;
        double exchangeRateOnTop;
        String seedTotalRaised;
        double WLThreshold;
        List<MemberItem> members;

        String basketName;
        for (int j = 0; j < fundingPanelItemsPrev.length; j++) {
          if (fundingPanelItemsPrev[j].fundingPanelAddress.toLowerCase() ==
              fundingPanelAddress.toLowerCase()) {
            basketName = fundingPanelItemsPrev[j].name;
            break;
          }
        }

        // check for seed max supply changes
        bool changed = false;
        for (int j = 0; j < result.length; j++) {
          if (result[j]['topics'].contains(newSeedMaxSupplyTopic) &&
              result[j]['address'].toString().toLowerCase() ==
                  fundingPanelAddress.toString().toLowerCase()) {
            changed = true;
            break;
          }
        }

        if (changed) {
          print('seed max supply changed');
          seedMaxSupply = await _getSeedMaxSupply(fundingPanelAddress);

          if (seedMaxSupply != null) {
            if (favorites.contains(fundingPanelAddress.toLowerCase())) {
              String notificationData =
                  'Total Supply by basket ' + basketName + ' changed!';
              basketsBloc.notification(notificationData);
            }
          }
        } else {
          seedMaxSupply = await _getSeedMaxSupplyFromPreviousSharedPref(
              fundingPanelAddress);
        }

        if (seedMaxSupply == null || seedMaxSupply == '0.00') {
          String notificationData =
              'Basket ' + basketName + ' disabled (zero-supply)!';
          basketsBloc.notification(notificationData);

          _addToFPCheckAgainList(
              fundingPanelAddress, adminToolsAddress, tokenAddress);
          continue;
        }

        // check for owner data hash changes
        changed = false;

        for (int j = 0; j < result.length; j++) {
          if (result[j]['topics'].contains(ownerDataHashChangedTopic) &&
              result[j]['address'].toString().toLowerCase() ==
                  fundingPanelAddress.toString().toLowerCase()) {
            changed = true;
            break;
          }
        }

        if (changed) {
          print('owner data hash changed');

          latestOwnerData = await _getLatestOwnerData(fundingPanelAddress);

          fundingPanelVisualData =
              await _getFundingPanelDetails(latestOwnerData['url']);

          if (fundingPanelVisualData == null) {
            fundingPanelVisualData =
                await _loadFundingPanelVisualDataFromPreviousSharedPref(
                    fundingPanelAddress);
          } else {
            List prevVisualData =
                await _loadFundingPanelVisualDataFromPreviousSharedPref(
                    fundingPanelAddress);

            if (favorites.contains(fundingPanelAddress.toLowerCase())) {
              if (basketName != null) {
                if (prevVisualData[6] != null &&
                    prevVisualData[6] != 'null' &&
                    fundingPanelVisualData[6] != null &&
                    fundingPanelVisualData[6] != 'null' &&
                    double.parse(prevVisualData[6]) !=
                        double.parse(fundingPanelVisualData[6])) {
                  String notificationData = 'Basket Success Fee by basket ' +
                      basketName +
                      ' changed!';
                  basketsBloc.notification(notificationData);
                } else {
                  String notificationData =
                      'Documents by basket ' + basketName + ' changed!';
                  basketsBloc.notification(notificationData);
                }
              }
            }
          }
        } else {
          latestOwnerData = await _getLatestOwnerDataFromPreviousSharedPref(
              fundingPanelAddress);

          fundingPanelVisualData =
              await _loadFundingPanelVisualDataFromPreviousSharedPref(
                  fundingPanelAddress);
        }

        if (fundingPanelVisualData == null) {
          _addToFPCheckAgainList(
              fundingPanelAddress, adminToolsAddress, tokenAddress);
          continue;
        }

        List documents = List();

        if (fundingPanelVisualData[4] != null &&
            fundingPanelVisualData[4] != '') {
          List documentMaps = jsonDecode(fundingPanelVisualData[4]);
          if (documentMaps != null) {
            documentMaps.forEach((document) {
              documents.add(document);
            });
          }
        }

        List tags = List();

        if (fundingPanelVisualData[5] != null &&
            fundingPanelVisualData[5] != '') {
          List tagMaps = jsonDecode(fundingPanelVisualData[5]);
          if (tagMaps != null) {
            tagMaps.forEach((tag) {
              String tagRepl = tag.toString().replaceAll('_', ' ');
              tagRepl = tagRepl.replaceAll('-', ' ');
              tags.add(tagRepl);
            });
          }
        }

        double basketSuccessFee;

        if (fundingPanelVisualData[6] != null &&
            fundingPanelVisualData[6] != 'null' &&
            fundingPanelVisualData[6] != '') {
          basketSuccessFee = double.parse(fundingPanelVisualData[6]);
        }

        // check for token exchange rate changes
        changed = false;

        for (int j = 0; j < result.length; j++) {
          if (result[j]['topics'].contains(tokenExchangeRateChangedTopic) &&
              result[j]['address'].toString().toLowerCase() ==
                  fundingPanelAddress.toString().toLowerCase()) {
            changed = true;
            break;
          }
        }

        if (changed) {
          print('exchangeRateSeed changed');

          exchangeRateSeed =
              await _getBasketSeedExchangeRate(fundingPanelAddress);

          if (exchangeRateSeed != null) {
            String notificationData =
                'Quotation by basket ' + basketName + ' changed!';
            basketsBloc.notification(notificationData);
          }
        } else {
          exchangeRateSeed = await _getExchangeRateSeedFromPreviousSharedPref(
              fundingPanelAddress);
        }

        if (exchangeRateSeed == null) {
          _addToFPCheckAgainList(
              fundingPanelAddress, adminToolsAddress, tokenAddress);
          continue;
        }

        // check for token exchange rate on top changes
        changed = false;

        for (int j = 0; j < result.length; j++) {
          if (result[j]['topics'].contains(changeTokenExchangeRateOnTopTopic) &&
              result[j]['address'].toString().toLowerCase() ==
                  fundingPanelAddress.toString().toLowerCase()) {
            changed = true;
            break;
          }
        }

        if (changed) {
          print('exchangeRate on top changed');

          exchangeRateOnTop =
              await _getBasketExchangeRateOnTop(fundingPanelAddress);

          if (exchangeRateOnTop != null) {
            if (favorites.contains(fundingPanelAddress.toLowerCase())) {
              String notificationData =
                  'Exchange Rate on Top by basket ' + basketName + ' changed!';
              basketsBloc.notification(notificationData);
            }
          }
        } else {
          exchangeRateOnTop = await _getExchangeRateOnTopFromPreviousSharedPref(
              fundingPanelAddress);
        }

        if (exchangeRateOnTop == null) {
          _addToFPCheckAgainList(
              fundingPanelAddress, adminToolsAddress, tokenAddress);
          continue;
        }

        // check for token exchange rate changes (DEX)
        changed = false;

        for (int j = 0; j < result.length; j++) {
          if (result[j]['topics'].contains(tradeTopic)) {
            String tokenGetAddress =
                EthereumAddress(result[j]['topics'][1]).hex;
            String tokenGiveAddress =
                EthereumAddress(result[j]['topics'][2]).hex;

            if (tokenGetAddress.toLowerCase() == tokenAddress.toLowerCase() ||
                tokenGiveAddress.toLowerCase() == tokenAddress.toLowerCase()) {
              changed = true;
              break;
            }
          }
        }

        if (changed) {
          print('exchangeRateSeed changed (DEX)');

          List retParams = await _getBasketSeedExchangeRateFromDEX(
              tokenAddress, fromBlock, toBlock, resMap);

          if (retParams != null) {
            exchangeRateSeedDEX = retParams[0];

            String notificationData =
                'Quotation by basket ' + basketName + ' changed!';
            basketsBloc.notification(notificationData);
          }
        } else {
          exchangeRateSeedDEX =
              await _getExchangeRateSeedDEXFromPreviousSharedPref(
                  fundingPanelAddress);
        }

        // check for total raised changes (has _holderSendSeeds been called?)
        changed = false;

        for (int j = 0; j < result.length; j++) {
          if (result[j]['topics'].contains(tokenMintedTopic) &&
              result[j]['address'].toString().toLowerCase() ==
                  fundingPanelAddress.toString().toLowerCase()) {
            changed = true;
            break;
          }
        }

        if (changed) {
          print('totalRaised changed');

          seedTotalRaised = await _getSeedTotalRaised(fundingPanelAddress);
        } else {
          seedTotalRaised = await _getSeedTotalRaisedFromPreviousSharedPref(
              fundingPanelAddress);
        }

        // check for WL threshold changes
        changed = false;

        for (int j = 0; j < result.length; j++) {
          if (result[j]['topics'].contains(WLThresholdChangedTopic) &&
              result[j]['address'].toString().toLowerCase() ==
                  adminToolsAddress.toString().toLowerCase()) {
            changed = true;
            break;
          }
        }

        if (changed) {
          print('threshold changed');

          WLThreshold =
              await _getWhitelistThreshold(adminToolsAddress, exchangeRateSeed);

          if (WLThreshold != null) {
            if (basketName != null) {
              String notificationData =
                  'WL Threshold by basket ' + basketName + ' changed!';
              basketsBloc.notification(notificationData);
            }
          }
        } else {
          WLThreshold =
              await _getWLThresholdFromPreviousSharedPref(fundingPanelAddress);
        }

        if (WLThreshold == null) {
          _addToFPCheckAgainList(
              fundingPanelAddress, adminToolsAddress, tokenAddress);
          continue;
        }

        bool fundsUnlocked = false;

        for (int j = 0; j < result.length; j++) {
          if (result[j]['topics'].contains(fundsUnlockedTopic) &&
              result[j]['address'].toString().toLowerCase() ==
                  fundingPanelAddress.toString().toLowerCase()) {
            fundsUnlocked = true;
            break;
          }
        }

        // check for members hash changed
        changed = false;

        for (int j = 0; j < result.length; j++) {
          if (result[j]['topics'].contains(memberHashChangedTopic) &&
              result[j]['address'].toString().toLowerCase() ==
                  fundingPanelAddress.toString().toLowerCase()) {
            changed = true;
            break;
          }
        }

        if (changed || fundsUnlocked) {
          print('some member hash changed or funds were unlocked');

          if (fundsUnlocked) {
            // Notification if funds unlocked
            if (favorites.contains(fundingPanelAddress.toLowerCase())) {
              if (basketName != null) {
                String notificationData =
                    'Funds Unlocked by basket $basketName changed!';
                basketsBloc.notification(notificationData);
              }
            }
          }

          if (changed) {
            members = List();
            List<String> membersAddressList =
                await _getMembersAddressListFromPreviousSharedPref(
                    fundingPanelAddress);

            for (int j = 0; j < membersAddressList.length; j++) {
              List<String> memberData = await _getMemberDataByAddress(
                  fundingPanelAddress, membersAddressList[j]);
              List<String> memberJsonData =
                  await _getMemberJSONDataFromIPFS(memberData[0]);

              if (memberJsonData != null) {
                List documents = List();

                if (memberJsonData[4] != null && memberJsonData[4] != '') {
                  List documentMaps = jsonDecode(memberJsonData[4]);
                  documentMaps.forEach((document) {
                    documents.add(document);
                  });
                }

                members.add(MemberItem(
                    seedsUnlocked: memberData[2],
                    memberAddress: membersAddressList[j],
                    fundingPanelAddress: fundingPanelAddress,
                    ipfsUrl: memberData[0],
                    hash: memberData[1],
                    name: memberJsonData[0],
                    description: memberJsonData[1],
                    url: memberJsonData[2],
                    documents: documents,
                    imgBase64: memberJsonData[3]));
              } else {
                _addToMembersCheckAgainList(
                    fundingPanelAddress, membersAddressList[j]);
                MemberItem member =
                    await _getSingleMemberFromPreviousSharedPref(
                        fundingPanelAddress, membersAddressList[j]);
                members.add(member);
              }
            }

            if (favorites.contains(fundingPanelAddress.toLowerCase())) {
              String notificationData =
                  'Documents by Startup changed! (Basket ' + basketName + ')';
              basketsBloc.notification(notificationData);
            }
          }
        } else {
          members =
              await _getMembersFromPreviousSharedPref(fundingPanelAddress);
        }

        if (members == null) {
          _addToFPCheckAgainList(
              fundingPanelAddress, adminToolsAddress, tokenAddress);
          continue;
        }

        // check for new members added
        changed = false;

        for (int j = 0; j < result.length; j++) {
          if (result[j]['topics'].contains(memberAddedTopic) &&
              result[j]['address'].toString().toLowerCase() ==
                  fundingPanelAddress.toString().toLowerCase()) {
            changed = true;
            break;
          }
        }

        if (changed) {
          print('members added');

          int newMembersLength = await _getMembersLength(fundingPanelAddress);
          List<MemberItem> oldMembers =
              await _getMembersFromPreviousSharedPref(fundingPanelAddress);
          int oldMembersLength = oldMembers.length;
          int index = oldMembersLength;
          while (index < newMembersLength) {
            String memberAddress =
                await _getMemberAddressByIndex(index, fundingPanelAddress);

            List<String> memberData = await _getMemberDataByAddress(
                fundingPanelAddress, memberAddress);

            List<String> memberJsonData =
                await _getMemberJSONDataFromIPFS(memberData[0]);

            if (memberJsonData != null) {
              List documents = List();

              if (memberJsonData[4] != null && memberJsonData[4] != '') {
                List documentMaps = jsonDecode(memberJsonData[4]);
                documentMaps.forEach((document) {
                  documents.add(document);
                });
              }

              members.add(MemberItem(
                  seedsUnlocked: memberData[2],
                  memberAddress: memberAddress,
                  fundingPanelAddress: fundingPanelAddress,
                  ipfsUrl: memberData[0],
                  hash: memberData[1],
                  name: memberJsonData[0],
                  description: memberJsonData[1],
                  url: memberJsonData[2],
                  imgBase64: memberJsonData[3],
                  documents: documents));

              String notificationData = 'Startup ' +
                  memberJsonData[0] +
                  ' added! (Basket ' +
                  basketName +
                  ')';
              basketsBloc.notification(notificationData);
            } else {
              _addToMembersCheckAgainList(fundingPanelAddress, memberAddress);
            }

            index++;
          }
        }

        members = await _checkAgainMembers(members, fundingPanelAddress);

        double totalUnlockedForStartup = 0;

        for (int i = 0; i < members.length; i++) {
          if (members[i] != null && members[i].seedsUnlocked != null) {
            totalUnlockedForStartup += double.parse(members[i].seedsUnlocked);
          }
        }

        FundingPanelItem FPItem = FundingPanelItem(
            totalUnlockedForStartup: totalUnlockedForStartup.toString(),
            seedTotalRaised: seedTotalRaised,
            adminToolsAddress: adminToolsAddress,
            tokenAddress: tokenAddress,
            fundingPanelAddress: fundingPanelAddress,
            latestOwnerData: latestOwnerData,
            seedExchangeRate: exchangeRateSeed,
            seedExchangeRateDEX: exchangeRateSeedDEX,
            exchangeRateOnTop: exchangeRateOnTop,
            name: fundingPanelVisualData[0],
            description: fundingPanelVisualData[1],
            url: fundingPanelVisualData[2],
            imgBase64: fundingPanelVisualData[3],
            tags: tags,
            documents: documents,
            members: members,
            basketSuccessFee: basketSuccessFee);

        fundingPanelItems.add(FPItem);

        List<Map> memberMapsConfigFile = List();
        List<Map> membersMapsSharedPrefs = List();

        for (int i = 0; i < members.length; i++) {
          Map memberMapConfigFile = {
            'memberAddress': members[i].memberAddress,
            'memberName': members[i].name,
            'latestIPFSUrl': members[i].ipfsUrl,
            'latestHash': members[i].hash,
          };

          memberMapsConfigFile.add(memberMapConfigFile);

          Map memberMapSP = {
            'member_address': members[i].memberAddress,
            'ipfsUrl': members[i].ipfsUrl,
            'hash': members[i].hash,
            'name': members[i].name,
            'description': members[i].description,
            'url': members[i].url,
            'imgBase64': members[i].imgBase64,
            'documents': members[i].documents,
            'seeds_unlocked': members[i].seedsUnlocked
          };

          membersMapsSharedPrefs.add(memberMapSP);
        }

        Map fpMapConfig = {
          'tokenAddress': FPItem.tokenAddress,
          'fundingPanelAddress': FPItem.fundingPanelAddress,
          'adminsToolsAddress': FPItem.adminToolsAddress,
          'fundingPanelName': FPItem.name,
          'seedExchangeRate': FPItem.seedExchangeRate,
          'seedExchangeRateDEX': FPItem.seedExchangeRateDEX,
          'exchangeRateOnTop': FPItem.exchangeRateOnTop,
          'fundingPanelData': FPItem.latestOwnerData,
          'whitelistThreshold': WLThreshold,
          'seedMaxSupply': seedMaxSupply,
          'members': memberMapsConfigFile
        };

        fpMapsConfigFile.add(fpMapConfig);

        Map fpMapSP = {
          'name': FPItem.name,
          'description': FPItem.description,
          'url': FPItem.url,
          'imgBase64': FPItem.imgBase64,
          'funding_panel_address': FPItem.fundingPanelAddress,
          'token_address': FPItem.tokenAddress,
          'admin_tools_address': FPItem.adminToolsAddress,
          'latest_owner_data': FPItem.latestOwnerData,
          'seed_exchange_rate': FPItem.seedExchangeRate,
          'seed_exchange_rate_dex': FPItem.seedExchangeRateDEX,
          'exchange_rate_on_top': FPItem.exchangeRateOnTop,
          'tags': FPItem.tags,
          'whitelist_threshold': WLThreshold,
          'seed_total_raised': FPItem.seedTotalRaised,
          'seed_max_supply': seedMaxSupply,
          //'seed_liquidity': seedLiquidity,
          'total_unlocked': FPItem.totalUnlockedForStartup,
          'documents': FPItem.documents,
          'basket_success_fee': FPItem.basketSuccessFee,
          'members': membersMapsSharedPrefs
        };

        fpMapsSharedPrefs.add(fpMapSP);
      }
    }

    Map FPListMap = {'list': fpMapsConfigFile};

    configurationMap.addAll(FPListMap);

    sharedPreferences = await SharedPreferences.getInstance();

    sharedPreferences.setString(
        'funding_panels_data', jsonEncode(fpMapsSharedPrefs));

    List returnParams = List();
    returnParams.add(fundingPanelItems);
    returnParams.add(_logsResultsExceeded);

    return returnParams;
  }

  Future getFundingPanelItems(List<FundingPanelItem> fundingPanelItems,
      Map configurationMap, int currentBlockNumber) async {
    List<Map> fpMapsConfigFile = List();
    List<Map> fpMapsSharedPrefs = List();
    int length = await _getLastDeployersLength();

    for (int index = 0; index < length; index++) {
      List<String> basketContracts = await _getBasketContractsByIndex(
          index); // 0: Deployer, 1: AdminTools, 2: Token, 3: FundingPanel

      String seedMaxSupply = await _getSeedMaxSupply(basketContracts[3]);

      if (seedMaxSupply == '0.00') {
        // skip zero-supply funding panels
        _addToFPCheckAgainList(
            basketContracts[3], basketContracts[1], basketContracts[2]);
        continue;
      }

      Map latestOwnerData = await _getLatestOwnerData(basketContracts[3]);

      List fundingPanelVisualData =
          await _getFundingPanelDetails(latestOwnerData['url']);

      if (fundingPanelVisualData == null) {
        // IPFS error, check if data is available in previous saved data (shared_prefs)
        fundingPanelVisualData =
            await _loadFundingPanelVisualDataFromPreviousSharedPref(
                basketContracts[3]);
      }

      if (fundingPanelVisualData != null) {
        List retParams = await _getBasketSeedExchangeRateFromDEX(
            basketContracts[2], 0, currentBlockNumber, _resMapLogsDEX);

        double exchangeRateSeedDEX;

        if (retParams != null) {
          exchangeRateSeedDEX = retParams[0];
          this._resMapLogsDEX = retParams[1];
        }

        double exchangeRateSeed =
            await _getBasketSeedExchangeRate(basketContracts[3]);

        double exchangeRateOnTop =
            await _getBasketExchangeRateOnTop(basketContracts[3]);

        String seedTotalRaised = await _getSeedTotalRaised(basketContracts[3]);

        double threshold =
            await _getWhitelistThreshold(basketContracts[1], exchangeRateSeed);

        List documents = List();

        if (fundingPanelVisualData[4] != null &&
            fundingPanelVisualData[4] != '') {
          List documentMaps = jsonDecode(fundingPanelVisualData[4]);
          documentMaps.forEach((document) {
            documents.add(document);
          });
        }

        List tags = List();

        if (fundingPanelVisualData[5] != null &&
            fundingPanelVisualData[5] != '') {
          List tagMaps = jsonDecode(fundingPanelVisualData[5]);
          tagMaps.forEach((tag) {
            String tagRepl = tag.toString().replaceAll('_', ' ');
            tagRepl = tagRepl.replaceAll('-', ' ');
            tags.add(tagRepl);
          });
        }

        double basketSuccessFee;

        if (fundingPanelVisualData[6] != null &&
            fundingPanelVisualData[6] != '') {
          basketSuccessFee = double.parse(fundingPanelVisualData[6]);
        }

        List<MemberItem> members =
            await _getMembersOfFundingPanel(basketContracts[3]);

        double totalUnlockedForStartup = 0;

        for (int i = 0; i < members.length; i++) {
          totalUnlockedForStartup += double.parse(members[i].seedsUnlocked);
        }

        FundingPanelItem FPItem = FundingPanelItem(
            totalUnlockedForStartup: totalUnlockedForStartup.toString(),
            seedTotalRaised: seedTotalRaised,
            adminToolsAddress: basketContracts[1],
            tokenAddress: basketContracts[2],
            fundingPanelAddress: basketContracts[3],
            latestOwnerData: latestOwnerData,
            seedExchangeRate: exchangeRateSeed,
            seedExchangeRateDEX: exchangeRateSeedDEX,
            exchangeRateOnTop: exchangeRateOnTop,
            name: fundingPanelVisualData[0],
            description: fundingPanelVisualData[1],
            url: fundingPanelVisualData[2],
            imgBase64: fundingPanelVisualData[3],
            members: members,
            tags: tags,
            documents: documents,
            basketSuccessFee: basketSuccessFee);

        fundingPanelItems.add(FPItem);
        List<Map> memberMapsConfigFile = List();
        List<Map> membersMapsSharedPrefs = List();

        for (int i = 0; i < members.length; i++) {
          Map memberMapConfigFile = {
            'memberAddress': members[i].memberAddress,
            'memberName': members[i].name,
            'latestIPFSUrl': members[i].ipfsUrl,
            'latestHash': members[i].hash,
          };

          memberMapsConfigFile.add(memberMapConfigFile);

          Map memberMapSP = {
            'member_address': members[i].memberAddress,
            'ipfsUrl': members[i].ipfsUrl,
            'hash': members[i].hash,
            'name': members[i].name,
            'description': members[i].description,
            'url': members[i].url,
            'imgBase64': members[i].imgBase64,
            'documents': members[i].documents,
            'seeds_unlocked': members[i].seedsUnlocked
          };

          membersMapsSharedPrefs.add(memberMapSP);
        }

        Map fpMapConfig = {
          'tokenAddress': FPItem.tokenAddress,
          'fundingPanelAddress': FPItem.fundingPanelAddress,
          'adminsToolsAddress': FPItem.adminToolsAddress,
          'fundingPanelName': FPItem.name,
          'seedExchangeRate': FPItem.seedExchangeRate,
          'seedExchangeRateDEX': FPItem.seedExchangeRateDEX,
          'exchangeRateOnTop': FPItem.exchangeRateOnTop,
          'fundingPanelData': FPItem.latestOwnerData,
          'whitelistThreshold': threshold,
          'seedMaxSupply': seedMaxSupply,
          'members': memberMapsConfigFile
        };

        fpMapsConfigFile.add(fpMapConfig);

        Map fpMapSP = {
          'name': FPItem.name,
          'description': FPItem.description,
          'url': FPItem.url,
          'imgBase64': FPItem.imgBase64,
          'funding_panel_address': FPItem.fundingPanelAddress,
          'token_address': FPItem.tokenAddress,
          'admin_tools_address': FPItem.adminToolsAddress,
          'latest_owner_data': FPItem.latestOwnerData,
          'seed_exchange_rate': FPItem.seedExchangeRate,
          'seed_exchange_rate_dex': FPItem.seedExchangeRateDEX,
          'exchange_rate_on_top': FPItem.exchangeRateOnTop,
          'tags': FPItem.tags,
          'whitelist_threshold': threshold,
          'seed_total_raised': FPItem.seedTotalRaised,
          'seed_max_supply': seedMaxSupply,
          'total_unlocked': FPItem.totalUnlockedForStartup,
          'documents': FPItem.documents,
          'basket_success_fee': FPItem.basketSuccessFee,
          'members': membersMapsSharedPrefs
        };

        fpMapsSharedPrefs.add(fpMapSP);
      } else {
        // Funding Panel was not added, maybe because of an IPFS or Server error, save it for check again later

        _addToFPCheckAgainList(
            basketContracts[3], basketContracts[1], basketContracts[2]);
      }
    }

    if (configurationMap['list'] == null) {
      Map FPListMap = {'list': fpMapsConfigFile};
      configurationMap.addAll(FPListMap);
    } else
      configurationMap['list'] = fpMapsConfigFile;

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    sharedPreferences.setString(
        'funding_panels_data', jsonEncode(fpMapsSharedPrefs));
  }

  static Future<List<MemberItem>> _getMembersOfFundingPanel(
      String fundingPanelAddress) async {
    List<MemberItem> members = List();
    int membersLength = await _getMembersLength(fundingPanelAddress);

    for (int i = 0; i < membersLength; i++) {
      String memberAddress =
          await _getMemberAddressByIndex(i, fundingPanelAddress);
      List<String> memberData =
          await _getMemberDataByAddress(fundingPanelAddress, memberAddress);
      List<String> memberJsonData =
          await _getMemberJSONDataFromIPFS(memberData[0]);

      if (memberJsonData != null) {
        List documents = List();

        if (memberJsonData[4] != null && memberJsonData[4] != '') {
          List documentMaps = jsonDecode(memberJsonData[4]);
          documentMaps.forEach((document) {
            documents.add(document);
          });
        }

        members.add(MemberItem(
            seedsUnlocked: memberData[2],
            memberAddress: memberAddress,
            fundingPanelAddress: fundingPanelAddress,
            ipfsUrl: memberData[0],
            hash: memberData[1],
            name: memberJsonData[0],
            description: memberJsonData[1],
            url: memberJsonData[2],
            imgBase64: memberJsonData[3],
            documents: documents));
      } else {
        _addToMembersCheckAgainList(fundingPanelAddress, memberAddress);
      }
    }

    return members;
  }

  static Future<List<String>> _getMemberJSONDataFromIPFS(String ipfsURL) async {
    List<String> memberJsonData = List();

    try {
      var response = await http.get(ipfsURL).timeout(Duration(seconds: 10));
      if (response.statusCode != 200) {
        return null;
      }
      Map responseMap = jsonDecode(response.body);

      memberJsonData.add(responseMap['name']);

      try {
        var base64Dec = base64.decode(responseMap['description']);
        var descrDec = Uri.decodeFull(utf8.decode(base64Dec));
        memberJsonData.add(descrDec);
      } catch (e) {
        memberJsonData.add(responseMap['description']);
      }

      memberJsonData.add(responseMap['url']);
      memberJsonData.add(responseMap['image']);

      if (responseMap['documents'] != null) {
        memberJsonData.add(jsonEncode(responseMap['documents']));
      } else {
        memberJsonData.add('');
      }

      return memberJsonData;
    } catch (e) {
      return null;
    }
  }

  static Future<List> _getFundingPanelDetails(String ipfsUrl) async {
    try {
      //print('AAAAA IPFS: ' + ipfsUrl);
      var response = await http.get(ipfsUrl).timeout(Duration(seconds: 10));
      //print('BBBBBBB');

      if (response.statusCode != 200) {
        return null;
      }
      Map responseMap = jsonDecode(response.body);

      List returnFpDetails = List();

      returnFpDetails.add(responseMap['name']);

      // 'Description' is base64 encoded, URI and html encoded
      try {
        var base64Dec = base64.decode(responseMap['description']);
        var descrDec = Uri.decodeFull(utf8.decode(base64Dec));
        returnFpDetails.add(descrDec);
      } catch (e) {
        // not base64 encoded
        returnFpDetails.add(responseMap['description']);
      }

      returnFpDetails.add(responseMap['url']);
      returnFpDetails.add(responseMap['image']);

      if (responseMap['documents'] != null) {
        returnFpDetails.add(jsonEncode(responseMap['documents']));
      } else
        returnFpDetails.add('');

      if (responseMap['tags'] != null) {
        returnFpDetails.add(jsonEncode(responseMap['tags']));
      } else
        returnFpDetails.add('');

      if (responseMap['basketSuccessFee'] != null) {
        returnFpDetails.add(jsonEncode(responseMap['basketSuccessFee']));
      } else
        returnFpDetails.add('');

      return returnFpDetails;
    } catch (e) {
      print('error http get ' + e.toString() + ' FROM ' + ipfsUrl);
      return null;
    }
  }

  static Future<List<String>> _loadFundingPanelVisualDataFromPreviousSharedPref(
      String fundingPanelAddress) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (prefs.getString('funding_panels_data') == null) return null;

    List maps = jsonDecode(prefs.getString('funding_panels_data'));

    for (int i = 0; i < maps.length; i++) {
      if (maps[i]['funding_panel_address'].toString().toLowerCase() ==
          fundingPanelAddress.toLowerCase()) {
        List<String> ret = List();
        ret.add(maps[i]['name']);
        ret.add(maps[i]['description']);
        ret.add(maps[i]['url']);
        ret.add(maps[i]['imgBase64']);
        ret.add(jsonEncode(maps[i]['documents']));
        ret.add(jsonEncode(maps[i]['tags']));
        ret.add(jsonEncode(maps[i]['basket_success_fee']));
        return ret;
      }
    }

    return null;
  }

  // Used in _update to load fundingPanelItems from previous sp before actually updating, so that updateHoldings() can be called
  // Used by BasketsBloc to load FundingPanels in order to filter baskets
  static Future<List<FundingPanelItem>>
      getFundingPanelItemsFromPrevSharedPref() async {
    List<FundingPanelItem> fundingPanelItems = List();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString('funding_panels_data') == null) return null;

    List maps = jsonDecode(prefs.getString('funding_panels_data'));
    for (int i = 0; i < maps.length; i++) {
      List<MemberItem> members = await _getMembersFromPreviousSharedPref(
          maps[i]['funding_panel_address']);

      // I only set parameters used by updateHoldings() and to filter baskets
      fundingPanelItems.add(FundingPanelItem(
          seedTotalRaised: maps[i]['seed_total_raised'],
          seedExchangeRate: maps[i]['seed_exchange_rate'],
          seedExchangeRateDEX: maps[i]['seed_exchange_rate_dex'],
          tokenAddress: maps[i]['token_address'],
          adminToolsAddress: maps[i]['admin_tools_address'],
          fundingPanelAddress: maps[i]['funding_panel_address'],
          imgBase64: maps[i]['imgBase64'],
          tags: maps[i]['tags'],
          documents: maps[i]['documents'],
          basketSuccessFee: maps[i]['basket_success_fee'],
          url: maps[i]['url'],
          members: members));
    }

    return fundingPanelItems;
  }

  Future _update() async {
    if (_previousConfigurationMap == null) {
      _previousConfigurationMap = await loadPreviousConfigFile();
      this._fundingPanelItems = await getFundingPanelItemsFromPrevSharedPref();
    }

    Map configurationMap = Map();
    List<FundingPanelItem> fundingPanelItems = List();

    Map localMap = {
      'lang_config_stuff': {'name': 'English (England)', 'code': 'en_EN'}
    };
    configurationMap.addAll(localMap);

    Map additionalInfo = {
      'seedTokenAddress': SeedTokenAddress,
      'factoryAddress': GlobalFactoryAddress,
      'dexAddress': DexAddress,
      'gasPrice': DefaultGasPrice,
      'gasLimit': DefaultGasLimit,
    };

    configurationMap.addAll(additionalInfo);

    int fromBlock;

    if (_fromBlockAgain != null) {
      fromBlock = _fromBlockAgain;
    } else {
      fromBlock = await _getFromBlockForLogsFromConfigFile();
      fromBlock++;
    }

    int currentBlockNumber;

    if (_toBlockForced != null) {
      currentBlockNumber = _toBlockForced;
    } else {
      currentBlockNumber = await getCurrentBlockNumber();
    }

    Map lastCheckedBlockNumberMap = {
      'lastCheckedBlockNumber': currentBlockNumber
    };
    configurationMap.addAll(lastCheckedBlockNumberMap);

    List addressMaps = List();
    List addressList = List(); // A list of all address to add to eth_getLogs

    addressList.add(GlobalFactoryAddress);
    addressList.add(DexAddress);

    for (int i = 0; i < _fundingPanelItems.length; i++) {
      Map addressMap = {
        'funding_panel_address': _fundingPanelItems[i].fundingPanelAddress,
        'admin_tools_address': _fundingPanelItems[i].adminToolsAddress,
        'token_address': _fundingPanelItems[i].tokenAddress,
        'new_added': false
      };
      addressMaps.add(addressMap);
      addressList.add(_fundingPanelItems[i].fundingPanelAddress);
      addressList.add(_fundingPanelItems[i].adminToolsAddress);
    }

    if (currentBlockNumber >= fromBlock) {
      // else, block number didn't changed

      print('FROM BLOCK: ' + fromBlock.toString());
      print('TO BLOCK: ' + currentBlockNumber.toString());

      List updateParams = List();
      updateParams.add(addressMaps);
      updateParams.add(addressList);
      updateParams.add(fromBlock);
      updateParams.add(currentBlockNumber);
      updateParams.add(configurationMap);
      updateParams.add(_fundingPanelItems);

      List returnParams = await _getLogsUpdate(updateParams);
      if (returnParams.length > 1) {
        fundingPanelItems = returnParams[0];
        _logsResultsExceeded = returnParams[1];
      } else
        _logsResultsExceeded = returnParams[0];

      if (fundingPanelItems == null) {
        if (_logsResultsExceeded) {
          int window = currentBlockNumber - fromBlock;
          _toBlockForced = currentBlockNumber - (window ~/ 2);
        }
        _fromBlockAgain = fromBlock;
        return;
      } else {
        _fromBlockAgain = null;
        _toBlockForced = null;
      }

      List<String> encryptedParams = await _getEncryptedParamsFromConfigFile();

      Map userMapEncrypted = {
        'user': {'data': encryptedParams[0], 'hash': encryptedParams[1]}
      };

      configurationMap.addAll(userMapEncrypted);

      _saveConfigurationFile(configurationMap);

      this._fundingPanelItems = fundingPanelItems;

      print('configuration updated!');

      _previousConfigurationMap = configurationMap;
    }
  }

  void configurationPeriodicUpdate() async {
    if (_hasToUpdate) {
      _update().whenComplete(() {
        new Timer(
            const Duration(milliseconds: 200), configurationPeriodicUpdate);
      });
    }
  }

  void cancelPeriodicUpdate() {
    _hasToUpdate = false;
  }

  void enablePeriodicUpdate() {
    _hasToUpdate = true;
  }

  /// Contracts Methods Calls

  Future<int> _getLastDeployersLength() async {
    String data = "0xe0118a53";
    Map callParams = {
      "id": "1",
      "jsonrpc": "2.0",
      "method": "eth_call",
      "params": [
        {
          "to": GlobalFactoryAddress,
          "data": data,
        },
        "latest"
      ]
    };

    var callResponse = await http.post(infuraHTTP,
        body: jsonEncode(callParams),
        headers: {'content-type': 'application/json'});

    Map resMap = jsonDecode(callResponse.body);

    return numbers.hexToInt(resMap['result']).toInt();
  }

  Future<List<String>> _getBasketContractsByIndex(int index) async {
    String data = "0xf40e056c"; // getContractsByIndex

    String indexHex = numbers.toHex(index);

    for (int i = 0; i < 64 - indexHex.length; i++) {
      data += "0";
    }

    data += indexHex;

    print(data);

    Map callParams = {
      "id": "1",
      "jsonrpc": "2.0",
      "method": "eth_call",
      "params": [
        {
          "to": GlobalFactoryAddress,
          "data": data,
        },
        "latest"
      ]
    };

    var callResponse = await http.post(infuraHTTP,
        body: jsonEncode(callParams),
        headers: {'content-type': 'application/json'});

    Map resMap = jsonDecode(callResponse.body);

    resMap['result'] = resMap['result'].toString().substring(2);

    List<String> addresses = List(4);

    addresses[0] = EthereumAddress(resMap['result']
            .toString()
            .substring(0, resMap['result'].toString().length ~/ 4))
        .hex;
    addresses[1] = EthereumAddress(resMap['result'].toString().substring(
            resMap['result'].toString().length ~/ 4,
            resMap['result'].toString().length ~/ 2))
        .hex;
    addresses[2] = EthereumAddress(resMap['result'].toString().substring(
            resMap['result'].toString().length ~/ 2,
            3 * (resMap['result'].toString().length ~/ 4)))
        .hex;
    addresses[3] = EthereumAddress(resMap['result'].toString().substring(
            3 * (resMap['result'].toString().length ~/ 4),
            resMap['result'].toString().length))
        .hex;

    print(callResponse.body);

    return addresses;
  }

  static Future<List> _getBasketSeedExchangeRateFromDEX(
      String tokenAddress, int fromBlock, int toBlock, Map res) async {
    Map resMap;
    if (res == null) {
      String fromBlockHex = numbers.toHex(fromBlock);
      String toBlockHex = numbers.toHex(toBlock);

      Map callParams = {
        "id": "1",
        "jsonrpc": "2.0",
        "method": "eth_getLogs",
        "params": [
          {
            "fromBlock": '0x' + fromBlockHex,
            "toBlock": '0x' + toBlockHex,
            "address": DexAddress,
            "topics": [tradeTopic]
          },
        ]
      };

      var callResponse;

      try {
        callResponse = await http.post(infuraHTTP,
            body: jsonEncode(callParams),
            headers: {'content-type': 'application/json'});
      } catch (e) {
        print('error http');
        return null;
      }

      resMap = jsonDecode(callResponse.body);

      if (resMap['error'] != null &&
          resMap['error']['message']
              .toString()
              .contains('query returned more')) {
        int decreaseRate = 500000;
        fromBlock = toBlock - decreaseRate;
        while (fromBlock <= toBlock && decreaseRate >= 0) {
          String fromBlockHex = numbers.toHex(fromBlock);
          Map callParams = {
            "id": "1",
            "jsonrpc": "2.0",
            "method": "eth_getLogs",
            "params": [
              {
                "fromBlock": '0x' + fromBlockHex,
                "toBlock": '0x' + toBlockHex,
                "address": DexAddress,
                "topics": [tradeTopic]
              },
            ]
          };

          var callResponse;

          try {
            callResponse = await http.post(infuraHTTP,
                body: jsonEncode(callParams),
                headers: {'content-type': 'application/json'});
          } catch (e) {
            print('error http');
            return null;
          }

          resMap = jsonDecode(callResponse.body);

          if (resMap['error'] != null &&
              resMap['error']['message']
                  .toString()
                  .contains('query returned more')) {
            decreaseRate = decreaseRate ~/ 2;
            fromBlock = toBlock - decreaseRate;
            continue;
          }

          if (resMap['error'] == null) break;
        }

        if (resMap['error'] != null) return null;
      }
    } else
      resMap = res;

    List result = resMap['result'];

    for (int i = result.length - 1; i >= 0; i--) {
      if (result[i]['topics'].contains(tradeTopic)) {
        String tokenGetAddress = EthereumAddress(result[i]['topics'][1]).hex;
        String tokenGiveAddress = EthereumAddress(result[i]['topics'][2]).hex;

        if (tokenGetAddress.toLowerCase() == tokenAddress.toLowerCase() ||
            tokenGiveAddress.toLowerCase() == tokenAddress.toLowerCase()) {
          String amountGetHex = result[i]['data'].toString().substring(2, 66);
          String amountGiveHex =
              result[i]['data'].toString().substring(66, 130);

          while (amountGetHex.codeUnitAt(0) == '0'.codeUnitAt(0)) {
            amountGetHex = amountGetHex.substring(1);
          }

          while (amountGiveHex.codeUnitAt(0) == '0'.codeUnitAt(0)) {
            amountGiveHex = amountGiveHex.substring(1);
          }

          amountGetHex = '0x' + amountGetHex;
          amountGiveHex = '0x' + amountGiveHex;

          double amountGet = double.parse(
              _getValueFromHex(amountGetHex, 18, morePrecision: true));
          double amountGive = double.parse(
              _getValueFromHex(amountGiveHex, 18, morePrecision: true));

          List retParams = List();

          if (tokenGetAddress.toLowerCase() == tokenAddress.toLowerCase()) {
            // Baskets token was bought

            retParams.add(amountGive / amountGet);
          } else {
            retParams.add(amountGet / amountGive);
          }

          retParams.add(resMap);
          return retParams;
        }
      }
    }

    return null;
  }

  static Future<double> _getBasketSeedExchangeRate(
      String fundingPanelAddress) async {
    String data = "0x18bf6abc"; // get exchangeRateSeed
    Map callParams = {
      "id": "1",
      "jsonrpc": "2.0",
      "method": "eth_call",
      "params": [
        {
          "to": fundingPanelAddress,
          "data": data,
        },
        "latest"
      ]
    };

    var callResponse = await http.post(infuraHTTP,
        body: jsonEncode(callParams),
        headers: {'content-type': 'application/json'});

    Map resMap = jsonDecode(callResponse.body);

    double rate = numbers.hexToInt(resMap['result']).toDouble() / pow(10, 18);
    return 1 / rate;
  }

  static Future<double> _getBasketExchangeRateOnTop(
      String fundingPanelAddress) async {
    String data = "0x3378df78";
    Map callParams = {
      "id": "1",
      "jsonrpc": "2.0",
      "method": "eth_call",
      "params": [
        {
          "to": fundingPanelAddress,
          "data": data,
        },
        "latest"
      ]
    };

    var callResponse = await http.post(infuraHTTP,
        body: jsonEncode(callParams),
        headers: {'content-type': 'application/json'});

    Map resMap = jsonDecode(callResponse.body);

    double rateOnTop =
        numbers.hexToInt(resMap['result']).toDouble() / pow(10, 18);
    return rateOnTop;
  }

  static Future<Map> _getLatestOwnerData(String fundingPanelAddress) async {
    String data = "0xe4b85399"; // getOwnerData
    Map callParams = {
      "id": "1",
      "jsonrpc": "2.0",
      "method": "eth_call",
      "params": [
        {
          "to": fundingPanelAddress,
          "data": data,
        },
        "latest"
      ]
    };

    var callResponse = await http.post(infuraHTTP,
        body: jsonEncode(callParams),
        headers: {'content-type': 'application/json'});

    Map resMap = jsonDecode(callResponse.body);

    print("get owner data: " + callResponse.body);

    print('hash: ' + resMap['result'].substring(66, 130));

    HexDecoder a = HexDecoder();
    List byteArray = a.convert(resMap['result'].toString().substring(130));

    String ipfsUrl = utf8.decode(byteArray);

    for (int i = 0; i < ipfsUrl.length; i++) {
      if (ipfsUrl.codeUnitAt(i) == 'h'.codeUnitAt(0)) {
        for (int k = i; k < ipfsUrl.length; k++) {
          if (ipfsUrl.codeUnitAt(k) == 0) {
            ipfsUrl = ipfsUrl.substring(i, k);
            break;
          }
        }

        break;
      }
    }

    Map latestDataUpdate = {
      'url': ipfsUrl,
      'hash': resMap['result'].substring(66, 130)
    };
    return latestDataUpdate;
  }

  static Future<List<String>> _getMemberDataByAddress(
      String fundingPanelAddress, String memberAddress) async {
    String data = "0xca87a8a1000000000000000000000000";

    data = data + memberAddress.substring(2);

    print(data);

    Map callParams = {
      "id": "1",
      "jsonrpc": "2.0",
      "method": "eth_call",
      "params": [
        {
          "to": fundingPanelAddress,
          "data": data,
        },
        "latest"
      ]
    };

    var callResponse = await http.post(infuraHTTP,
        body: jsonEncode(callParams),
        headers: {'content-type': 'application/json'});

    Map resMap = jsonDecode(callResponse.body);

    String hash = resMap['result'].toString().substring(194, 258);

    String seedsUnlocked = _getValueFromHex(
        '0x' + resMap['result'].toString().substring(386, 450), 18);

    HexDecoder a = HexDecoder();
    List byteArray = a.convert(resMap['result'].toString().substring(512));

    String ipfsUrl = utf8.decode(byteArray);

    for (int i = 0; i < ipfsUrl.length; i++) {
      if (ipfsUrl.codeUnitAt(i) == 'h'.codeUnitAt(0)) {
        for (int k = i; k < ipfsUrl.length; k++) {
          if (ipfsUrl.codeUnitAt(k) == 0) {
            ipfsUrl = ipfsUrl.substring(i, k);
            break;
          }
        }

        break;
      }
    }

    List<String> memberData = List();
    memberData.add(ipfsUrl);
    memberData.add(hash);
    memberData.add(seedsUnlocked);

    return memberData;
  }

  static Future<String> _getMemberAddressByIndex(
      int index, String fundingPanelAddress) async {
    String data = "0x3c8c3ca6";

    String indexHex = numbers.toHex(index);

    for (int i = 0; i < 64 - indexHex.length; i++) {
      data += "0";
    }

    data += indexHex;

    print(data);

    Map callParams = {
      "id": "1",
      "jsonrpc": "2.0",
      "method": "eth_call",
      "params": [
        {
          "to": fundingPanelAddress,
          "data": data,
        },
        "latest"
      ]
    };

    var callResponse = await http.post(infuraHTTP,
        body: jsonEncode(callParams),
        headers: {'content-type': 'application/json'});

    Map resMap = jsonDecode(callResponse.body);

    String address = EthereumAddress(resMap['result'].toString()).hex;

    return address;
  }

  static Future<int> _getMembersLength(String fundingPanelAddress) async {
    String data = "0x7351262f"; // get deployerListLength
    Map callParams = {
      "id": "1",
      "jsonrpc": "2.0",
      "method": "eth_call",
      "params": [
        {
          "to": fundingPanelAddress,
          "data": data,
        },
        "latest"
      ]
    };

    var callResponse = await http.post(infuraHTTP,
        body: jsonEncode(callParams),
        headers: {'content-type': 'application/json'});

    Map resMap = jsonDecode(callResponse.body);

    return numbers.hexToInt(resMap['result']).toInt();
  }

  static Future<String> _getSeedTotalRaised(String fundingPanelAddress) async {
    String data = "0x8f5f695f";

    Map callParams = {
      "id": "1",
      "jsonrpc": "2.0",
      "method": "eth_call",
      "params": [
        {
          "to": fundingPanelAddress,
          "data": data,
        },
        "latest"
      ]
    };

    var callResponse = await http.post(infuraHTTP,
        body: jsonEncode(callParams),
        headers: {'content-type': 'application/json'});

    Map resMap = jsonDecode(callResponse.body);

    String seedTotalRaised = _getValueFromHex(resMap['result'].toString(), 18);

    return seedTotalRaised;
  }

  static Future<double> _getWhitelistThreshold(
      String adminToolsAddress, double exchangeRateSeed) async {
    String data = "0x6163607e";

    Map callParams = {
      "id": "1",
      "jsonrpc": "2.0",
      "method": "eth_call",
      "params": [
        {
          "to": adminToolsAddress,
          "data": data,
        },
        "latest"
      ]
    };

    var callResponse = await http.post(infuraHTTP,
        body: jsonEncode(callParams),
        headers: {'content-type': 'application/json'});

    Map resMap = jsonDecode(callResponse.body);

    String threshold = _getValueFromHex(resMap['result'].toString(), 18);
    return double.parse(threshold);
  }

  static Future<String> _getSeedMaxSupply(String fundingPanelAddress) async {
    String data = "0x8f8361ea";

    Map callParams = {
      "id": "1",
      "jsonrpc": "2.0",
      "method": "eth_call",
      "params": [
        {
          "to": fundingPanelAddress,
          "data": data,
        },
        "latest"
      ]
    };

    var callResponse = await http.post(infuraHTTP,
        body: jsonEncode(callParams),
        headers: {'content-type': 'application/json'});

    Map resMap = jsonDecode(callResponse.body);

    String seedMaxSupply =
        _getValueFromHex(resMap['result'].toString(), 18, morePrecision: true);

    if (seedMaxSupply.codeUnitAt(seedMaxSupply.length - 1) ==
            '0'.codeUnitAt(0) &&
        seedMaxSupply.codeUnitAt(seedMaxSupply.length - 2) ==
            '.'.codeUnitAt(0)) {
      seedMaxSupply = seedMaxSupply.substring(0, seedMaxSupply.length - 2);
    }

    return seedMaxSupply;
  }

  Future<int> getCurrentBlockNumber() async {
    Map callParams = {
      "id": "1",
      "jsonrpc": "2.0",
      "method": "eth_blockNumber",
      "params": []
    };

    var callResponse = await http.post(infuraHTTP,
        body: jsonEncode(callParams),
        headers: {'content-type': 'application/json'});

    Map resMap = jsonDecode(callResponse.body);

    return numbers.hexToInt(resMap['result']).toInt();
  }

  /// Config File Utils Section

  void _saveConfigurationFile(Map configurationMap) async {
    final documentsDir = await getApplicationSupportDirectory();
    String path = documentsDir.path;
    String configFilePath = '$path/configuration.json';
    File configFile = File(configFilePath);
    configFile.writeAsStringSync(jsonEncode(configurationMap));
  }

  // Used to contribute to a basket
  Future<Credentials> checkConfigPassword(String password) async {
    List<String> encryptedParams = await _getEncryptedParamsFromConfigFile();
    String encryptedData = encryptedParams[0];
    String hash = encryptedParams[1];

    var platform = MethodChannel('seedventure.io/aes');

    var decryptedData = await platform.invokeMethod('decrypt', {
      "encrypted": utf8.decode(base64.decode(encryptedData)),
      "realPass":
          crypto.md5.convert(utf8.encode(password)).toString().toUpperCase()
    });

    try {
      Map configJson = jsonDecode(decryptedData);
      Credentials credentials =
          Credentials.fromPrivateKeyHex(configJson['privateKey']);
      if (crypto.sha256
              .convert(utf8.encode(credentials.address.hex.toLowerCase()))
              .toString() ==
          hash) {
        return credentials;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<int> _getFromBlockForLogsFromConfigFile() async {
    final documentsDir = await getApplicationSupportDirectory();
    String path = documentsDir.path;
    String configFilePath = '$path/configuration.json';
    File configFile = File(configFilePath);
    String content = configFile.readAsStringSync();
    Map configurationMap = jsonDecode(content);
    int lastCheckedBlockNumber = configurationMap['lastCheckedBlockNumber'];
    return lastCheckedBlockNumber;
  }

  Future<List<String>> _getEncryptedParamsFromConfigFile() async {
    final documentsDir = await getApplicationSupportDirectory();
    String path = documentsDir.path;
    String configFilePath = '$path/configuration.json';
    File configFile = File(configFilePath);
    String content = configFile.readAsStringSync();
    Map configurationMap = jsonDecode(content);
    List<String> encryptedParams = List();
    encryptedParams.add(configurationMap['user']['data']);
    encryptedParams.add(configurationMap['user']['hash']);
    return encryptedParams;
  }

  Future<Map> loadPreviousConfigFile() async {
    final documentsDir = await getApplicationSupportDirectory();
    String path = documentsDir.path;
    String configFilePath = '$path/configuration.json';
    File configFile = File(configFilePath);
    String content = configFile.readAsStringSync();
    Map configurationMap = jsonDecode(content);
    return configurationMap;
  }

  /// Token Balances Section

  void balancesPeriodicUpdate() async {
    const secs = const Duration(seconds: 5);
    _balancesUpdateTimer =
        new Timer.periodic(secs, (Timer t) => _updateHoldings());
  }

  void cancelBalancesPeriodicUpdate() {
    if (_balancesUpdateTimer != null) _balancesUpdateTimer.cancel();
  }

  void updateSingleBalanceAfterContribute(String fundingPanelAddress) async {
    await _getSingleBasketTokenBalance(fundingPanelAddress);
    basketsBloc.getBasketsTokenBalances(
        fpAddressToHighlight: fundingPanelAddress);
    basketsBloc.setFavorite();
  }

  void _updateHoldings() async {
    if (_fundingPanelItems != null) {
      print('updating holdings...');
      basketsBloc.getCurrentBalances();
      await getBasketTokensBalances(_fundingPanelItems);
      basketsBloc.getBasketsTokenBalances();
    }
  }

  // used after contribute
  Future _getSingleBasketTokenBalance(String fundingPanelAddress) async {
    if (_fundingPanelItems == null) return;
    String tokenAddress;
    List tags;
    for (int i = 0; i < _fundingPanelItems.length; i++) {
      if (_fundingPanelItems[i].fundingPanelAddress.toLowerCase() ==
          fundingPanelAddress.toLowerCase()) {
        tokenAddress = _fundingPanelItems[i].tokenAddress;
        tags = _fundingPanelItems[i].tags;
        break;
      }
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();

    String userAddress = prefs.getString('address');

    List<Map> userBasketsBalances = List();

    List prevUserBasketsBalancesSharedPref;

    if (prefs.getString('user_baskets_balances') != null) {
      prevUserBasketsBalancesSharedPref =
          jsonDecode(prefs.getString('user_baskets_balances'));
    }

    for (int i = 0; i < prevUserBasketsBalancesSharedPref.length; i++) {
      if (prevUserBasketsBalancesSharedPref[i]['funding_panel_address']
              .toString()
              .toLowerCase() ==
          fundingPanelAddress.toLowerCase()) {
        int decimals = 18;
        String symbol = prevUserBasketsBalancesSharedPref[i]['token_symbol'];

        // I only need to update the balance after contribute
        String balance =
            await _getTokenBalance(userAddress, tokenAddress, decimals);

        bool isWhitelisted =
            prevUserBasketsBalancesSharedPref[i]['is_whitelisted'];
        bool isBlacklisted =
            prevUserBasketsBalancesSharedPref[i]['is_blacklisted'];
        double maxWLAmount =
            prevUserBasketsBalancesSharedPref[i]['max_wl_amount'];

        Map basketBalance = {
          'name': prevUserBasketsBalancesSharedPref[i]['name'],
          'quotation': prevUserBasketsBalancesSharedPref[i]['quotation'],
          'quotation_dex': prevUserBasketsBalancesSharedPref[i]
              ['quotation_dex'],
          'funding_panel_address': fundingPanelAddress,
          'imgBase64': prevUserBasketsBalancesSharedPref[i]['imgBase64'],
          'token_address': tokenAddress,
          'token_symbol': symbol,
          'token_balance': balance,
          'token_decimals': decimals,
          'is_whitelisted': isWhitelisted,
          'is_blacklisted': isBlacklisted,
          'seed_total_raised': prevUserBasketsBalancesSharedPref[i]
              ['seed_total_raised'],
          'basket_tags': tags,
          'max_wl_amount': maxWLAmount
        };

        userBasketsBalances.add(basketBalance);
      } else {
        userBasketsBalances.add(prevUserBasketsBalancesSharedPref[i]);
      }
    }

    prefs.setString('user_baskets_balances', jsonEncode(userBasketsBalances));
  }

  Future getBasketTokensBalances(List<FundingPanelItem> fundingPanels,
      {bool creatingConfig}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (prefs.getStringList('favorites') == null)
      prefs.setStringList('favorites', List());

    String userAddress = prefs.getString('address');

    List<Map> userBasketsBalances = List();

    List prevUserBasketsBalancesSharedPref;

    if (prefs.getString('user_baskets_balances') != null) {
      prevUserBasketsBalancesSharedPref =
          jsonDecode(prefs.getString('user_baskets_balances'));
    }

    for (int i = 0; i < fundingPanels.length; i++) {
      String tokenAddress = fundingPanels[i].tokenAddress;
      int decimals = 18;
      String symbol;
      if (prevUserBasketsBalancesSharedPref != null) {
        // Search for previous saved decimals and symbol instead of querying the blockchain
        for (int j = 0; j < prevUserBasketsBalancesSharedPref.length; j++) {
          if (prevUserBasketsBalancesSharedPref[j]['funding_panel_address']
                  .toString()
                  .toLowerCase() ==
              fundingPanels[i].fundingPanelAddress.toLowerCase()) {
            symbol = prevUserBasketsBalancesSharedPref[j]['token_symbol'];
            break;
          }
        }
      }

      if (symbol == null) {
        symbol = await _getTokenSymbol(tokenAddress);
      }

      String balance =
          await _getTokenBalance(userAddress, tokenAddress, decimals);
      bool isWhitelisted =
          await _isWhitelisted(fundingPanels[i].adminToolsAddress, userAddress);
      bool isBlacklisted = isWhitelisted == false
          ? false
          : await _isBlacklisted(
              fundingPanels[i].adminToolsAddress, userAddress, decimals);
      double maxWLAmount = 0.0;

      if (isWhitelisted) {
        maxWLAmount = await _getWLMaxAmount(
            fundingPanels[i].adminToolsAddress, userAddress);
      }

      Map basketBalance = {
        'name': fundingPanels[i].name,
        'funding_panel_address': fundingPanels[i].fundingPanelAddress,
        'quotation': fundingPanels[i].seedExchangeRate,
        'quotation_dex': fundingPanels[i].seedExchangeRateDEX,
        'imgBase64': fundingPanels[i].imgBase64,
        'token_address': tokenAddress,
        'token_symbol': symbol,
        'token_balance': balance,
        'token_decimals': decimals,
        'is_whitelisted': isWhitelisted,
        'is_blacklisted': isBlacklisted,
        'basket_tags': fundingPanels[i].tags,
        'seed_total_raised': fundingPanels[i].seedTotalRaised,
        'max_wl_amount': maxWLAmount
      };

      userBasketsBalances.add(basketBalance);

      // Setting favorite if first start and balance != 0
      if (creatingConfig != null && creatingConfig && balance != '0.00') {
        List favorites = prefs.getStringList('favorites');
        favorites.add(fundingPanels[i].fundingPanelAddress.toLowerCase());
        prefs.setStringList('favorites', favorites);
      }
    }

    prefs.setString('user_baskets_balances', jsonEncode(userBasketsBalances));
  }

  Future<bool> _isBlacklisted(
      String adminToolsAddress, String userAddress, int decimals) async {
    String data = "0xf76912aa";

    userAddress = userAddress.substring(2);

    while (userAddress.length != 64) {
      userAddress = '0' + userAddress;
    }

    data = data + userAddress;

    Map callParams = {
      "id": "1",
      "jsonrpc": "2.0",
      "method": "eth_call",
      "params": [
        {
          "to": adminToolsAddress,
          "data": data,
        },
        "latest"
      ]
    };

    var callResponse = await http.post(infuraHTTP,
        body: jsonEncode(callParams),
        headers: {'content-type': 'application/json'});

    Map resMap = jsonDecode(callResponse.body);

    String hexValue = _getValueFromHex(resMap['result'], decimals);

    return hexValue == '0.00';
  }

  Future<bool> _isWhitelisted(
      String adminToolsAddress, String userAddress) async {
    String data = "0x3af32abf";

    userAddress = userAddress.substring(2);

    while (userAddress.length != 64) {
      userAddress = '0' + userAddress;
    }

    data = data + userAddress;

    Map callParams = {
      "id": "1",
      "jsonrpc": "2.0",
      "method": "eth_call",
      "params": [
        {
          "to": adminToolsAddress,
          "data": data,
        },
        "latest"
      ]
    };

    var callResponse = await http.post(infuraHTTP,
        body: jsonEncode(callParams),
        headers: {'content-type': 'application/json'});

    Map resMap = jsonDecode(callResponse.body);

    return resMap['result'].contains('1');
  }

  Future<double> _getWLMaxAmount(
      String adminToolsAddress, String userAddress) async {
    String data = "0xf76912aa";

    userAddress = userAddress.substring(2);

    while (userAddress.length != 64) {
      userAddress = '0' + userAddress;
    }

    data = data + userAddress;

    Map callParams = {
      "id": "1",
      "jsonrpc": "2.0",
      "method": "eth_call",
      "params": [
        {
          "to": adminToolsAddress,
          "data": data,
        },
        "latest"
      ]
    };

    var callResponse = await http.post(infuraHTTP,
        body: jsonEncode(callParams),
        headers: {'content-type': 'application/json'});

    Map resMap = jsonDecode(callResponse.body);

    String maxWLAmount = _getValueFromHex(resMap['result'].toString(), 18);
    return double.parse(maxWLAmount);
  }

  Future<String> _getTokenSymbol(String tokenAddress) async {
    String data = "0x95d89b41";
    Map callParams = {
      "id": "1",
      "jsonrpc": "2.0",
      "method": "eth_call",
      "params": [
        {
          "to": tokenAddress,
          "data": data,
        },
        "latest"
      ]
    };

    var callResponse = await http.post(infuraHTTP,
        body: jsonEncode(callParams),
        headers: {'content-type': 'application/json'});

    Map resMap = jsonDecode(callResponse.body);

    HexDecoder a = HexDecoder();
    List byteArray = a.convert(resMap['result'].toString().substring(2));

    String res = utf8.decode(byteArray);

    return res.replaceAll(new RegExp('[^A-Za-z0-9]'),
        ''); // replace all non-alphanumeric characters from res string
  }

  Future<String> _getTokenBalance(
      String userAddress, String tokenAddress, int decimals) async {
    userAddress = userAddress.substring(2);

    String data = "0x70a08231";

    while (userAddress.length != 64) {
      userAddress = '0' + userAddress;
    }

    data = data + userAddress;

    Map callParams = {
      "id": "1",
      "jsonrpc": "2.0",
      "method": "eth_call",
      "params": [
        {
          "to": tokenAddress,
          "data": data,
        },
        "latest"
      ]
    };

    var callResponse = await http.post(infuraHTTP,
        body: jsonEncode(callParams),
        headers: {'content-type': 'application/json'});

    Map resMap = jsonDecode(callResponse.body);

    String tokenBalance =
        _getValueFromHex(resMap['result'].toString(), decimals);

    return tokenBalance;
  }

  static String _getValueFromHex(String hexValue, int decimals,
      {bool morePrecision}) {
    hexValue = hexValue.substring(2);
    if (hexValue == '' || hexValue == '0') return '0.00';

    BigInt bigInt = BigInt.parse(hexValue, radix: 16);
    Decimal dec = Decimal.parse(bigInt.toString());
    Decimal x = dec / Decimal.fromInt(pow(10, decimals));
    String value = x.toString();
    if (value == '0') return '0.00';

    double doubleValue = double.parse(value);

    if (morePrecision != null && morePrecision) {
      return doubleValue.toString();
    } else {
      return doubleValue.toStringAsFixed(
          doubleValue.truncateToDouble() == doubleValue ? 0 : 2);
    }
  }
}
