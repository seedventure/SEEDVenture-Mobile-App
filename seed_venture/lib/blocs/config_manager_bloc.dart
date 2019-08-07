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

final ConfigManagerBloc configManagerBloc = ConfigManagerBloc();

class ConfigManagerBloc {
  Map _previousConfigurationMap;
  List<FundingPanelItem> _fundingPanelItems;
  int _fromBlockAgain;
  int _toBlockForced;
  Map _resMapLogsDEX;
  bool _logsResultsExceeded = false;

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

    int currentBlockNumber = await _getCurrentBlockNumber();
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

    await _getFundingPanelItems(
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

    await _getBasketTokensBalances(fundingPanelItems, creatingConfig: true);

    OnBoardingBloc.setOnBoardingDone();
  }

  String _generateMd5(String input) {
    return crypto.md5.convert(utf8.encode(input)).toString();
  }

  Future<String> _getSeedMaxSupplyFromPreviousSharedPref(
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

  Future<double> _getExchangeRateSeedFromPreviousSharedPref(
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

  Future<double> _getExchangeRateSeedDEXFromPreviousSharedPref(
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

  Future<double> _getWLThresholdFromPreviousSharedPref(
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

  Future<List<MemberItem>> _getMembersFromPreviousSharedPref(
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

  Future<MemberItem> _getSingleMemberFromPreviousSharedPref(
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

  Future<List<String>> _getMembersAddressListFromPreviousSharedPref(
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

  Future<Map> _getLatestOwnerDataFromPreviousSharedPref(
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

  Future<String> _getSeedTotalRaisedFromPreviousSharedPref(
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

  Future<FundingPanelItem> _handleNewPanel(
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

    double exchangeRateSeedDEX = await _getBasketSeedExchangeRateFromDEX(
        tokenAddress, fromBlock, toBlock, logResponseMap);
    double exchangeRateSeed =
        await _getBasketSeedExchangeRate(fundingPanelAddress);

    String seedTotalRaised = await _getSeedTotalRaised(fundingPanelAddress);
    String seedLiquidity = await _getSeedLiquidity(fundingPanelAddress);

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
        seedLiquidity: seedLiquidity,
        adminToolsAddress: adminToolsAddress,
        tokenAddress: tokenAddress,
        fundingPanelAddress: fundingPanelAddress,
        latestOwnerData: latestOwnerData,
        seedMaxSupply: seedMaxSupply,
        seedExchangeRate: exchangeRateSeed,
        seedExchangeRateDEX: exchangeRateSeedDEX,
        name: fundingPanelVisualData[0],
        description: fundingPanelVisualData[1],
        url: fundingPanelVisualData[2],
        imgBase64: fundingPanelVisualData[3],
        members: members,
        tags: tags,
        documents: documents);

    return FPItem;
  }

  void _addToFPCheckAgainList(String fundingPanelAddress,
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

  void _addToMembersCheckAgainList(
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

  Future<List<MemberItem>> _checkAgainMembers(
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
  Future<List<FundingPanelItem>> _getLogsUpdate(
      List addressMaps,
      List addressList,
      int fromBlock,
      int toBlock,
      Map configurationMap) async {
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

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

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
            'fundingPanelData': FPItem.latestOwnerData,
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
            'tags': FPItem.tags,
            'whitelist_threshold': FPItem.whitelistThreshold,
            'seed_total_raised': FPItem.seedTotalRaised,
            'seed_max_supply': FPItem.seedMaxSupply,
            'seed_liquidity': FPItem.seedLiquidity,
            'total_unlocked': FPItem.totalUnlockedForStartup,
            'documents': FPItem.documents,
            'members': membersMapsSharedPrefs
          };

          fpMapsSharedPrefs.add(fpMapSP);
        }
      } else {
        Map latestOwnerData;
        String seedMaxSupply;
        List fundingPanelVisualData;
        double exchangeRateSeed;
        double exchangeRateSeedDEX;
        String seedTotalRaised;
        String seedLiquidity;
        double WLThreshold;
        List<MemberItem> members;

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
        } else {
          seedMaxSupply = await _getSeedMaxSupplyFromPreviousSharedPref(
              fundingPanelAddress);
        }

        if (seedMaxSupply == null || seedMaxSupply == '0.00') {
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
        } else {
          exchangeRateSeed = await _getExchangeRateSeedFromPreviousSharedPref(
              fundingPanelAddress);
        }

        if (exchangeRateSeed == null) {
          _addToFPCheckAgainList(
              fundingPanelAddress, adminToolsAddress, tokenAddress);
          continue;
        }

        // check for token exchange rate changes (DEX)
        changed = false;

        for (int j = 0; j < result.length; j++) {
          if (result[j]['topics'].contains(tradeTopic)) {
            String tokenGetAddress =
                EthereumAddress(result[i]['data'].toString().substring(2, 66))
                    .hex;
            String tokenGiveAddress = EthereumAddress(
                    result[i]['data'].toString().substring(130, 194))
                .hex;

            if (tokenGetAddress.toLowerCase() == tokenAddress.toLowerCase() ||
                tokenGiveAddress.toLowerCase() == tokenAddress.toLowerCase()) {
              changed = true;
              break;
            }
          }
        }

        if (changed) {
          print('exchangeRateSeed changed (DEX)');

          exchangeRateSeedDEX = await _getBasketSeedExchangeRateFromDEX(
              tokenAddress, fromBlock, toBlock, resMap);
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

        seedLiquidity = await _getSeedLiquidity(fundingPanelAddress);

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
              MemberItem member = await _getSingleMemberFromPreviousSharedPref(
                  fundingPanelAddress, membersAddressList[j]);
              members.add(member);
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
            name: fundingPanelVisualData[0],
            description: fundingPanelVisualData[1],
            url: fundingPanelVisualData[2],
            imgBase64: fundingPanelVisualData[3],
            tags: tags,
            documents: documents,
            members: members);

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
          'fundingPanelData': FPItem.latestOwnerData,
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
          'tags': FPItem.tags,
          'whitelist_threshold': WLThreshold,
          'seed_total_raised': FPItem.seedTotalRaised,
          'seed_max_supply': seedMaxSupply,
          'seed_liquidity': seedLiquidity,
          'total_unlocked': FPItem.totalUnlockedForStartup,
          'documents': FPItem.documents,
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

    return fundingPanelItems;
  }

  Future _getFundingPanelItems(List<FundingPanelItem> fundingPanelItems,
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
        double exchangeRateSeedDEX = await _getBasketSeedExchangeRateFromDEX(
            basketContracts[2], 0, currentBlockNumber, _resMapLogsDEX);

        double exchangeRateSeed =
            await _getBasketSeedExchangeRate(basketContracts[3]);

        String seedTotalRaised = await _getSeedTotalRaised(basketContracts[3]);
        String seedLiquidity = await _getSeedLiquidity(basketContracts[3]);

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
            name: fundingPanelVisualData[0],
            description: fundingPanelVisualData[1],
            url: fundingPanelVisualData[2],
            imgBase64: fundingPanelVisualData[3],
            members: members,
            tags: tags,
            documents: documents);

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
          'fundingPanelData': FPItem.latestOwnerData,
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
          'tags': FPItem.tags,
          'whitelist_threshold': threshold,
          'seed_total_raised': FPItem.seedTotalRaised,
          'seed_max_supply': seedMaxSupply,
          'seed_liquidity': seedLiquidity,
          'total_unlocked': FPItem.totalUnlockedForStartup,
          'documents': FPItem.documents,
          'members': membersMapsSharedPrefs
        };

        fpMapsSharedPrefs.add(fpMapSP);
      } else {
        // Funding Panel was not added, maybe because of an IPFS or Server error, save it for check again later

        _addToFPCheckAgainList(
            basketContracts[3], basketContracts[1], basketContracts[2]);
      }
    }

    Map FPListMap = {'list': fpMapsConfigFile};

    configurationMap.addAll(FPListMap);

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    sharedPreferences.setString(
        'funding_panels_data', jsonEncode(fpMapsSharedPrefs));

    sharedPreferences.setStringList('favorites', List());
  }

  Future<List<MemberItem>> _getMembersOfFundingPanel(
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

  Future<List<String>> _getMemberJSONDataFromIPFS(String ipfsURL) async {
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

  Future<List> _getFundingPanelDetails(String ipfsUrl) async {
    try {
      print('AAAAA IPFS: ' + ipfsUrl);
      var response = await http.get(ipfsUrl).timeout(Duration(seconds: 10));
      print('BBBBBBB');

      if (response.statusCode != 200) {
        return null;
      }
      Map responseMap = jsonDecode(response.body);

      List returnFpDetails = List();

      returnFpDetails.add(responseMap['name']);

      // 'Description' is base64 encoded and html encoded
      try {
        //returnFpDetails.add(
        //  utf8.decode(base64.decode(responseMap['description'].toString())));

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
      }
      returnFpDetails.add('');

      return returnFpDetails;
    } catch (e) {
      print('error http get ' + e.toString() + ' FROM ' + ipfsUrl);
      return null;
    }
  }

  Future<List<String>> _loadFundingPanelVisualDataFromPreviousSharedPref(
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
        return ret;
      }
    }

    return null;
  }

  // Used in _update to load fundingPanelItems from previous sp before actually updating, so that updateHoldings() can be called
  Future<List<FundingPanelItem>>
      _getFundingPanelItemsFromPrevSharedPref() async {
    List<FundingPanelItem> fundingPanelItems = List();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString('funding_panels_data') == null) return null;

    List maps = jsonDecode(prefs.getString('funding_panels_data'));
    for (int i = 0; i < maps.length; i++) {
      // I only set parameters used by updateHoldings()
      fundingPanelItems.add(FundingPanelItem(
          seedTotalRaised: maps[i]['seed_total_raised'],
          seedExchangeRate: maps[i]['seed_exchange_rate'],
          seedExchangeRateDEX: maps[i]['seed_exchange_rate_dex'],
          tokenAddress: maps[i]['token_address'],
          adminToolsAddress: maps[i]['admin_tools_address'],
          fundingPanelAddress: maps[i]['funding_panel_address'],
          imgBase64: maps[i]['imgBase64'],
          tags: maps[i]['tags'],
          documents: maps[i]['documents']));
    }

    return fundingPanelItems;
  }

  Future _update() async {
    if (_previousConfigurationMap == null) {
      _previousConfigurationMap = await _loadPreviousConfigFile();
      this._fundingPanelItems = await _getFundingPanelItemsFromPrevSharedPref();
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
      currentBlockNumber = await _getCurrentBlockNumber();
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

      fundingPanelItems = await _getLogsUpdate(addressMaps, addressList,
          fromBlock, currentBlockNumber, configurationMap);

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

      bool areNotificationsEnabled =
          await SettingsBloc.areNotificationsEnabled();

      if (areNotificationsEnabled) {
        await _checkDifferencesBetweenConfigurations(
            _previousConfigurationMap, configurationMap);
      }

      _previousConfigurationMap = configurationMap;
    }
  }

  Future _checkDifferencesBetweenConfigurations(
      Map previous, Map actual) async {
    // Search for FundingPanels changes

    List previousFPList = previous['list'];
    List actualFPList = actual['list'];

    SharedPreferences prefs = await SharedPreferences.getInstance();

    List maps = jsonDecode(prefs.getString('funding_panels_data'));
    List<FundingPanelItem> fundingPanelItems = List();

    List favorites = prefs.getStringList('favorites');

    for (int i = 0; i < maps.length; i++) {
      fundingPanelItems.add(FundingPanelItem(
          // I only need name + fpAddress for notifications
          name: maps[i]['name'],
          fundingPanelAddress: maps[i]['funding_panel_address']));
    }

    List<int> actualListUsedIndexes =
        List(); // Contains used indexes; the unused indexes will represent new added Baskets

    for (int i = 0; i < previousFPList.length; i++) {
      Map prevFP = previousFPList[i];
      Map actualFP;

      for (int k = 0; k < actualFPList.length; k++) {
        if (actualFPList[k]['fundingPanelAddress'].toString().toLowerCase() ==
            prevFP['fundingPanelAddress'].toString().toLowerCase()) {
          actualFP = actualFPList[k];
          actualListUsedIndexes.add(k);
          break;
        }
      }

      if (actualFP != null) {
        // check if the basket is being disabled (set to zero-supply)

        if (prevFP['fundingPanelData']['hash'].toString().toLowerCase() !=
            actualFP['fundingPanelData']['hash'].toString().toLowerCase()) {
          // Something changed because the hashes are different

          // check if fp is favorite
          if (favorites.contains(
              prevFP['fundingPanelAddress'].toString().toLowerCase())) {
            String notificationData = 'Documents by basket ' +
                prevFP['fundingPanelName'] +
                ' changed!';
            basketsBloc.notification(notificationData);
          }
        }

        // here I check important changes (quotation)

        if (prevFP['seedExchangeRate'].toString() !=
                actualFP['seedExchangeRate'].toString() ||
            prevFP['seedExchangeRateDEX'].toString() !=
                actualFP['seedExchangeRateDEX'].toString()) {
          // include DEX quotation changes?
          String notificationData =
              'Quotation by basket ' + prevFP['fundingPanelName'] + ' changed!';
          basketsBloc.notification(notificationData);
        }

        // checks for fp's specific members

        List<int> actualListUsedIndexesForMembers = List();

        List previousMemberList = prevFP['members'];
        List actualMemberList = actualFP['members'];

        String incubatorName = fundingPanelItems[i].name;
        String fpAddress = fundingPanelItems[i].fundingPanelAddress;

        for (int i = 0; i < previousMemberList.length; i++) {
          Map prevMember = previousMemberList[i];
          Map actualMember;

          for (int k = 0; k < actualMemberList.length; k++) {
            if (actualMemberList[k]['memberAddress'].toString().toLowerCase() ==
                prevMember['memberAddress'].toString().toLowerCase()) {
              actualMember = actualMemberList[k];
              actualListUsedIndexesForMembers.add(k);
              break;
            }
          }

          if (actualMember != null) {
            // check if the member disappeared from list on blockchain
            if (prevMember['latestHash'].toString().toLowerCase() !=
                actualMember['latestHash'].toString().toLowerCase()) {
              if (favorites.contains(fpAddress.toLowerCase())) {
                String notificationData = 'Documents by startup ' +
                    prevMember['memberName'] +
                    ' changed! (Incubator ' +
                    incubatorName +
                    ')';
                basketsBloc.notification(notificationData);
              }
            }
          }
        }

        if (actualListUsedIndexesForMembers.length < actualMemberList.length) {
          for (int i = 0; i < actualMemberList.length; i++) {
            if (!actualListUsedIndexesForMembers.contains(i)) {
              String notificationData = 'Startup ' +
                  actualMemberList[i]['memberName'] +
                  ' added! (Basket ' +
                  incubatorName +
                  ')';
              basketsBloc.notification(notificationData);
            }
          }
        }
      } else {
        String notificationData =
            'Basket ' + prevFP['fundingPanelName'] + ' disabled (zero-supply)!';
        basketsBloc.notification(notificationData);
      }
    }

    if (actualListUsedIndexes.length < actualFPList.length) {
      for (int i = 0; i < actualFPList.length; i++) {
        if (!actualListUsedIndexes.contains(i)) {
          String notificationData =
              'Basket ' + actualFPList[i]['fundingPanelName'] + ' added!';
          basketsBloc.notification(notificationData);
        }
      }
    }
  }

  void configurationPeriodicUpdate() async {
    _update().whenComplete(() {
      new Timer(const Duration(milliseconds: 200), configurationPeriodicUpdate);
    });
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

  Future<double> _getBasketSeedExchangeRateFromDEX(
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

    this._resMapLogsDEX = resMap;

    List result = resMap['result'];

    for (int i = 0; i < result.length; i++) {
      String tokenGetAddress =
          EthereumAddress(result[i]['data'].toString().substring(2, 66)).hex;
      String tokenGiveAddress =
          EthereumAddress(result[i]['data'].toString().substring(130, 194)).hex;

      if (tokenGetAddress.toLowerCase() == tokenAddress.toLowerCase() ||
          tokenGiveAddress.toLowerCase() == tokenAddress.toLowerCase()) {
        String amountGetHex = result[i]['data'].toString().substring(66, 130);
        String amountGiveHex = result[i]['data'].toString().substring(194, 258);

        while (amountGetHex.codeUnitAt(0) == '0'.codeUnitAt(0)) {
          amountGetHex = amountGetHex.substring(1);
        }

        while (amountGiveHex.codeUnitAt(0) == '0'.codeUnitAt(0)) {
          amountGiveHex = amountGiveHex.substring(1);
        }

        amountGetHex += '0x';
        amountGiveHex += '0x';

        double amountGet = double.parse(_getValueFromHex(amountGetHex, 18));
        double amountGive = double.parse(_getValueFromHex(amountGiveHex, 18));

        if (tokenGetAddress.toLowerCase() == tokenAddress.toLowerCase()) {
          // Baskets token was bought
          return amountGive / amountGet;
        } else {
          return amountGet / amountGive;
        }
      }
    }

    return null;
  }

  Future<double> _getBasketSeedExchangeRate(String fundingPanelAddress) async {
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

  Future<Map> _getLatestOwnerData(String fundingPanelAddress) async {
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

  Future<List<String>> _getMemberDataByAddress(
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

  Future<String> _getMemberAddressByIndex(
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

  Future<int> _getMembersLength(String fundingPanelAddress) async {
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

  Future<String> _getSeedTotalRaised(String fundingPanelAddress) async {
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

  Future<String> _getSeedLiquidity(String fundingPanelAddress) async {
    fundingPanelAddress = fundingPanelAddress.substring(2);

    String data = "0x70a08231";

    while (fundingPanelAddress.length != 64) {
      fundingPanelAddress = '0' + fundingPanelAddress;
    }

    data = data + fundingPanelAddress;

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

    String tokenBalance = _getValueFromHex(resMap['result'].toString(), 18);

    return tokenBalance;
  }

  Future<double> _getWhitelistThreshold(
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

  Future<String> _getSeedMaxSupply(String fundingPanelAddress) async {
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
        _getValueFromHex(resMap['result'].toString(), 18, seedMaxSupply: true);

    if (seedMaxSupply.codeUnitAt(seedMaxSupply.length - 1) ==
            '0'.codeUnitAt(0) &&
        seedMaxSupply.codeUnitAt(seedMaxSupply.length - 2) ==
            '.'.codeUnitAt(0)) {
      seedMaxSupply = seedMaxSupply.substring(0, seedMaxSupply.length - 2);
    }

    return seedMaxSupply;
  }

  Future<int> _getCurrentBlockNumber() async {
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

  Future<Map> _loadPreviousConfigFile() async {
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
    new Timer.periodic(secs, (Timer t) => _updateHoldings());
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
      await _getBasketTokensBalances(_fundingPanelItems);
      basketsBloc.getBasketsTokenBalances();
    }
  }

  // used after contribute
  Future _getSingleBasketTokenBalance(String fundingPanelAddress) async {
    if (_fundingPanelItems == null) return;
    String tokenAddress;
    String adminToolsAddress;
    List tags;
    for (int i = 0; i < _fundingPanelItems.length; i++) {
      if (_fundingPanelItems[i].fundingPanelAddress.toLowerCase() ==
          fundingPanelAddress.toLowerCase()) {
        tokenAddress = _fundingPanelItems[i].tokenAddress;
        adminToolsAddress = _fundingPanelItems[i].adminToolsAddress;
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
        String balance =
            await _getTokenBalance(userAddress, tokenAddress, decimals);
        bool isWhitelisted =
            await _isWhitelisted(adminToolsAddress, userAddress);
        bool isBlacklisted = isWhitelisted == false
            ? false
            : await _isBlacklisted(adminToolsAddress, userAddress, decimals);

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
          'basket_tags': tags
        };

        userBasketsBalances.add(basketBalance);
      } else {
        userBasketsBalances.add(prevUserBasketsBalancesSharedPref[i]);
      }
    }

    prefs.setString('user_baskets_balances', jsonEncode(userBasketsBalances));
  }

  Future _getBasketTokensBalances(List<FundingPanelItem> fundingPanels,
      {bool creatingConfig}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

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
        'seed_total_raised': fundingPanels[i].seedTotalRaised
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

  String _getValueFromHex(String hexValue, int decimals, {bool seedMaxSupply}) {
    hexValue = hexValue.substring(2);
    if (hexValue == '' || hexValue == '0') return '0.00';

    BigInt bigInt = BigInt.parse(hexValue, radix: 16);
    Decimal dec = Decimal.parse(bigInt.toString());
    Decimal x = dec / Decimal.fromInt(pow(10, decimals));
    String value = x.toString();
    if (value == '0') return '0.00';

    double doubleValue = double.parse(value);

    if (seedMaxSupply != null && seedMaxSupply) {
      return doubleValue.toString();
    } else {
      return doubleValue.toStringAsFixed(
          doubleValue.truncateToDouble() == doubleValue ? 0 : 2);
    }
  }
}
