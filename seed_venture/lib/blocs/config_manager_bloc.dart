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

    int currentBlockNumber = await getCurrentBlockNumber();
    Map lastCheckedBlockNumberMap = {
      'lastCheckedBlockNumber': currentBlockNumber
    };
    configurationMap.addAll(lastCheckedBlockNumberMap);

    Map additionalInfo = {
      'seedTokenAddress': SeedTokenAddress,
      'factoryAddress': GlobalFactoryAddress,
      'dexAddress': DexAddress,
      'web3Provider': 'assets/scripts/blockchain.provider.web3.js',
      'etherscanURL': EtherscanURL,
      'web3URL': infuraWSS,
      'ipfsProvider': 'assets/scripts/ipfs.provider.http.js',
      'ipfsHost': 'ipfs.infura.io',
      'ipfsPort': '5001',
      'ipfsProtocol': 'https',
      'ipfsUrlTemplate': 'https://ipfs.io/ipfs/',
      'gasPrice': DefaultGasPrice,
      'gasLimit': DefaultGasLimit,
    };
    configurationMap.addAll(additionalInfo);

    await getFundingPanelItems(fundingPanelItems, configurationMap);

    Map userMapDecrypted = {
      'privateKey': walletCredentials.privateKey.toRadixString(16),
      'wallet': walletCredentials.address.hex,
      'list': []
    };

    String realPass = generateMd5(password);
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

    saveConfigurationFile(configurationMap);

    this._fundingPanelItems = fundingPanelItems;

    await _getBasketTokensBalances(fundingPanelItems, creatingConfig: true);

    OnBoardingBloc.setOnBoardingDone();
  }

  void saveConfigurationFile(Map configurationMap) async {
    final documentsDir = await getApplicationSupportDirectory();
    String path = documentsDir.path;
    String configFilePath = '$path/configuration.json';
    File configFile = File(configFilePath);
    configFile.writeAsStringSync(jsonEncode(configurationMap));
  }

  String generateMd5(String input) {
    return crypto.md5.convert(utf8.encode(input)).toString();
  }

  // returns a list, [0] -> seedTotalRaised, [1] -> lastCheckedBlockNumberTotalRaised, todo?
  /*Future<double> _getSeedTotalRaisedPREV(String fundingPanelAddress, int fromBlock, double exchangeRateSeed, double prevTotalRaised) async {
    double totalRaised = prevTotalRaised;
    String indexHex = numbers.toHex(fromBlock);

    Map callParams = {
      "id": "1",
      "jsonrpc": "2.0",
      "method": "eth_getLogs",
      "params": [
        {
          "fromBlock": '0x' + indexHex,
          "address": fundingPanelAddress,
          "topics" : [
            "0xa010600a2b0cad80fbba6228184e39b1090d487cbcde96700c76857648fa6479"
          ]

        },
      ]
    };

    var callResponse = await http.post(infuraHTTP,
        body: jsonEncode(callParams),
        headers: {'content-type': 'application/json'});

    //int lastCheckedBlockNumberTotalRaised = await getCurrentBlockNumber();

    Map resMap = jsonDecode(callResponse.body);
    List result = resMap['result'];

    for(int i = 0; i < result.length; i++) {
      String data = result[i]['data'].toString().substring(0, 66);

      int div = 18;
      if(exchangeRateSeed != 1.0) {
        String a = exchangeRateSeed.toString();
        div = div - (a.allMatches('0').length - 1);
      }

      String valueStr = _getValueFromHex(data, div);

      totalRaised += double.parse(valueStr);
    }



    return totalRaised * exchangeRateSeed;

  }*/

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

  Future<double> _getSeedWhitelistThreshold(
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
    double seedThreshold = double.parse(threshold) * exchangeRateSeed;

    return seedThreshold;
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

    String seedMaxSupply = _getValueFromHex(resMap['result'].toString(), 18);

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

  Future<String> _getPrevFundingPanelHash(String fundingPanelAddress) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List maps = jsonDecode(prefs.getString('funding_panels_data'));

    for (int i = 0; i < maps.length; i++) {
      if (maps[i]['funding_panel_address'].toString().toLowerCase() ==
          fundingPanelAddress.toLowerCase()) {
        List ownerData = maps[i]['latest_owner_data'];
        return ownerData[0]['hash'];
      }
    }
    return null;
  }

  Future<String> _getPrevMemberHash(
      String fundingPanelAddress, String memberAddress) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List maps = jsonDecode(prefs.getString('funding_panels_data'));

    for (int i = 0; i < maps.length; i++) {
      if (maps[i]['funding_panel_address'].toString().toLowerCase() ==
          fundingPanelAddress.toLowerCase()) {
        List members = maps[i]['members'];

        for (int j = 0; j < members.length; j++) {
          if (members[j]['member_address'].toString().toLowerCase() ==
              memberAddress.toLowerCase()) {
            return members[j]['hash'];
          }
        }
      }
    }
    return null;
  }

  Future getFundingPanelItemsForUpdate(
      List<FundingPanelItem> fundingPanelItems, Map configurationMap) async {
    List<Map> fpMapsConfigFile = List();
    List<Map> fpMapsSharedPrefs = List();
    int length = await getLastDeployersLength();

    for (int index = 0; index < length; index++) {
      List<String> basketContracts = await getBasketContractsByIndex(
          index); // 0: Deployer, 1: AdminTools, 2: Token, 3: FundingPanel

      String seedMaxSupply = await _getSeedMaxSupply(basketContracts[3]);

      if (seedMaxSupply == '0.00') continue; // skip zero-supply funding panels

      Map latestOwnerData = await getLatestOwnerData(basketContracts[3]);
      List<Map> fpData = List();
      fpData.add(latestOwnerData);

      String prevHash = await _getPrevFundingPanelHash(basketContracts[3]);

      List fundingPanelVisualData;

      // Avoid downloading documents from IPFS if hash hasn't changed
      if (prevHash != null &&
          prevHash.toLowerCase() ==
              fpData[0]['hash'].toString().toLowerCase()) {
        fundingPanelVisualData =
            await loadFundingPanelVisualDataFromPreviousSharedPref(
                basketContracts[3]);
      } else {
        fundingPanelVisualData =
            await getFundingPanelDetails(latestOwnerData['url']);

        if (fundingPanelVisualData == null) {
          // IPFS error, check if data is available in previous saved data (shared_prefs)
          fundingPanelVisualData =
              await loadFundingPanelVisualDataFromPreviousSharedPref(
                  basketContracts[3]);
        }
      }

      if (fundingPanelVisualData != null) {
        double exchangeRateSeed =
            await getBasketSeedExchangeRate(basketContracts[3]);

        String seedTotalRaised = await _getSeedTotalRaised(basketContracts[3]);
        String seedLiquidity = await _getSeedLiquidity(basketContracts[3]);

        double threshold = await _getSeedWhitelistThreshold(
            basketContracts[1], exchangeRateSeed);

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

        List<MemberItem> members =
            await getMembersOfFundingPanelForUpdate(basketContracts[3]);

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
            fundingPanelUpdates: fpData,
            latestDexQuotation: exchangeRateSeed,
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
          'lastDEXPrice': FPItem.latestDexQuotation,
          'fundingPanelUpdates': FPItem.fundingPanelUpdates,
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
          'latest_owner_data': FPItem.fundingPanelUpdates,
          'latest_dex_price': FPItem.latestDexQuotation,
          'seed_whitelist_threshold': threshold,
          'seed_total_raised': FPItem.seedTotalRaised,
          'seed_max_supply': seedMaxSupply,
          'seed_liquidity': seedLiquidity,
          'total_unlocked': FPItem.totalUnlockedForStartup,
          'tags': FPItem.tags,
          'documents': FPItem.documents,
          'members': membersMapsSharedPrefs
        };

        fpMapsSharedPrefs.add(fpMapSP);
      }
    }

    Map FPListMap = {'list': fpMapsConfigFile};

    configurationMap.addAll(FPListMap);

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    sharedPreferences.setString(
        'funding_panels_data', jsonEncode(fpMapsSharedPrefs));
  }

  Future getFundingPanelItems(
      List<FundingPanelItem> fundingPanelItems, Map configurationMap) async {
    List<Map> fpMapsConfigFile = List();
    List<Map> fpMapsSharedPrefs = List();
    int length = await getLastDeployersLength();

    for (int index = 0; index < length; index++) {
      List<String> basketContracts = await getBasketContractsByIndex(
          index); // 0: Deployer, 1: AdminTools, 2: Token, 3: FundingPanel

      String seedMaxSupply = await _getSeedMaxSupply(basketContracts[3]);

      if (seedMaxSupply == '0.00') continue; // skip zero-supply funding panels

      Map latestOwnerData = await getLatestOwnerData(basketContracts[3]);
      List<Map> fpData = List();
      fpData.add(latestOwnerData);

      List fundingPanelVisualData =
          await getFundingPanelDetails(latestOwnerData['url']);

      if (fundingPanelVisualData == null) {
        // IPFS error, check if data is available in previous saved data (shared_prefs)
        fundingPanelVisualData =
            await loadFundingPanelVisualDataFromPreviousSharedPref(
                basketContracts[3]);
      }

      if (fundingPanelVisualData != null) {
        double exchangeRateSeed =
            await getBasketSeedExchangeRate(basketContracts[3]);

        String seedTotalRaised = await _getSeedTotalRaised(basketContracts[3]);
        String seedLiquidity = await _getSeedLiquidity(basketContracts[3]);

        double threshold = await _getSeedWhitelistThreshold(
            basketContracts[1], exchangeRateSeed);

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
            await getMembersOfFundingPanel(basketContracts[3]);

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
            fundingPanelUpdates: fpData,
            latestDexQuotation: exchangeRateSeed,
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
          'lastDEXPrice': FPItem.latestDexQuotation,
          'fundingPanelUpdates': FPItem.fundingPanelUpdates,
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
          'latest_owner_data': FPItem.fundingPanelUpdates,
          'latest_dex_price': FPItem.latestDexQuotation,
          'tags': FPItem.tags,
          'seed_whitelist_threshold': threshold,
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

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    sharedPreferences.setString(
        'funding_panels_data', jsonEncode(fpMapsSharedPrefs));

    sharedPreferences.setStringList('favorites', List());
  }

  Future<List<String>> loadMemberDataFromPreviousSharedPref(
      String fundingPanelAddress, String memberAddress) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (prefs.getString('funding_panels_data') == null) return null;

    List maps = jsonDecode(prefs.getString('funding_panels_data'));

    for (int i = 0; i < maps.length; i++) {
      if (maps[i]['funding_panel_address'].toString().toLowerCase() ==
          fundingPanelAddress.toLowerCase()) {
        List members = maps[i]['members'];

        for (int j = 0; j < members.length; j++) {
          if (members[j]['member_address'].toString().toLowerCase() ==
              memberAddress.toLowerCase()) {
            List<String> ret = List();
            ret.add(members[j]['name']);
            ret.add(members[j]['description']);
            ret.add(members[j]['url']);
            ret.add(members[j]['imgBase64']);
            ret.add(jsonEncode(members[j]['documents']));
            return ret;
          }
        }
      }
    }

    return null;
  }

  Future<List<MemberItem>> getMembersOfFundingPanelForUpdate(
      String fundingPanelAddress) async {
    List<MemberItem> members = List();
    int membersLength = await getMembersLength(fundingPanelAddress);

    for (int i = 0; i < membersLength; i++) {
      String memberAddress =
          await getMemberAddressByIndex(i, fundingPanelAddress);
      List<String> memberData =
          await getMemberDataByAddress(fundingPanelAddress, memberAddress);

      String prevHash =
          await _getPrevMemberHash(fundingPanelAddress, memberAddress);

      List<String> memberJsonData;

      // prev documents hash for member hasn't changed, there is no need for re-download data
      if (prevHash != null &&
          prevHash.toLowerCase() == memberData[1].toLowerCase()) {
        memberJsonData = await loadMemberDataFromPreviousSharedPref(
            fundingPanelAddress, memberAddress);
      } else {
        memberJsonData = await getMemberJSONDataFromIPFS(memberData[0]);
      }

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
            documents: documents,
            imgBase64: memberJsonData[3]));
      }
    }

    return members;
  }

  Future<List<MemberItem>> getMembersOfFundingPanel(
      String fundingPanelAddress) async {
    List<MemberItem> members = List();
    int membersLength = await getMembersLength(fundingPanelAddress);

    for (int i = 0; i < membersLength; i++) {
      String memberAddress =
          await getMemberAddressByIndex(i, fundingPanelAddress);
      List<String> memberData =
          await getMemberDataByAddress(fundingPanelAddress, memberAddress);
      List<String> memberJsonData =
          await getMemberJSONDataFromIPFS(memberData[0]);

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
      }
    }

    return members;
  }

  Future<List<String>> getMemberJSONDataFromIPFS(String ipfsURL) async {
    List<String> memberJsonData = List();

    try {
      var response = await http.get(ipfsURL).timeout(Duration(seconds: 10));
      if (response.statusCode != 200) {
        return null;
      }
      Map responseMap = jsonDecode(response.body);

      memberJsonData.add(responseMap['name']);

      try {
        memberJsonData
            .add(utf8.decode(base64.decode(responseMap['description'])));
      } catch (e) {
        memberJsonData.add(responseMap['description']);
      }

      memberJsonData.add(responseMap['url']);
      memberJsonData.add(responseMap['image']);

      if (responseMap['documents'] != null) {
        memberJsonData.add(jsonEncode(responseMap['documents']));
      } else
        memberJsonData.add('');

      return memberJsonData;
    } catch (e) {
      return null;
    }
  }

  Future<List<String>> getMemberDataByAddress(
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
        '00' + resMap['result'].toString().substring(386, 450), 18);

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

  Future<String> getMemberAddressByIndex(
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

  Future<int> getMembersLength(String fundingPanelAddress) async {
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

  Future<List> getFundingPanelDetails(String ipfsUrl) async {
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
        returnFpDetails.add(
            utf8.decode(base64.decode(responseMap['description'].toString())));
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

  Future<int> getLastDeployersLength() async {
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

  Future<List<String>> getBasketContractsByIndex(int index) async {
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

  Future<double> getBasketSeedExchangeRate(String fundingPanelAddress) async {
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

  Future<Map> getLatestOwnerData(String fundingPanelAddress) async {
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

  Future<String> getSingleFundingPanelTokenAddress(
      String fundingPanelContractAddress) async {
    String data = "0x10fe9ae8";

    Map callParams = {
      "id": "1",
      "jsonrpc": "2.0",
      "method": "eth_call",
      "params": [
        {
          "to": fundingPanelContractAddress,
          "data": data,
        },
        "latest"
      ]
    };

    var callResponse = await http.post(infuraHTTP,
        body: jsonEncode(callParams),
        headers: {'content-type': 'application/json'});

    Map resMap = jsonDecode(callResponse.body);

    print(callResponse.body);

    return EthereumAddress(resMap['result']).hex;
  }

  Future<List<String>> getEncryptedParamsFromConfigFile() async {
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

  Future<List<String>> loadFundingPanelVisualDataFromPreviousSharedPref(
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
          latestDexQuotation: maps[i]['latest_dex_price'],
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
      _previousConfigurationMap = await loadPreviousConfigFile();
      this._fundingPanelItems = await _getFundingPanelItemsFromPrevSharedPref();
    }

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

    await getFundingPanelItemsForUpdate(
        fundingPanelItems, configurationMap); // Optimized (hash-based checks)

    List<String> encryptedParams = await getEncryptedParamsFromConfigFile();

    Map userMapEncrypted = {
      'user': {'data': encryptedParams[0], 'hash': encryptedParams[1]}
    };

    configurationMap.addAll(userMapEncrypted);

    saveConfigurationFile(configurationMap);

    this._fundingPanelItems = fundingPanelItems;

    print('configuration updated!');

    bool areNotificationsEnabled = await SettingsBloc.areNotificationsEnabled();

    if (areNotificationsEnabled) {
      await checkDifferencesBetweenConfigurations(
          _previousConfigurationMap, configurationMap);
    }

    _previousConfigurationMap = configurationMap;
  }

  Future checkDifferencesBetweenConfigurations(Map previous, Map actual) async {
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

        if (prevFP['fundingPanelUpdates'][0]['hash'].toString().toLowerCase() !=
            actualFP['fundingPanelUpdates'][0]['hash']
                .toString()
                .toLowerCase()) {
          // Something changed because the hashes are different

          // Here I check changes that are not so important (name, description, image, url) // aggiungere url

          /*if(prevFP['name'].toString() != actualFP['name'].toString() ||
            prevFP['description'].toString() != actualFP['description'].toString() ||
            prevFP['imgBase64'].toString() != actualFP['imgBase64'].toString()){

            String notificationData = 'Documents by basket ' +
                prevFP['fundingPanelName'] +
                ' changed!';
            basketsBloc.notification(notificationData);

          }*/

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

        if (prevFP['lastDEXPrice'].toString() !=
            actualFP['lastDEXPrice'].toString()) {
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
          } else {
            /*String notificationData =
                'member' + prevMember['memberName'] +
                    ' removed! (Incubator ' + incubatorName + ' )';
            basketsBloc.notification(notificationData);*/
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
    await _update();
    const secs = const Duration(seconds: 10);
    new Timer.periodic(secs, (Timer t) => _update());
  }

  void updateSingleBalanceAfterContribute(String fundingPanelAddress) async {
    await _getSingleBasketTokenBalance(fundingPanelAddress);
    basketsBloc.getBasketsTokenBalances(
        fpAddressToHighlight: fundingPanelAddress);
    basketsBloc.setFavorite();
  }

  void balancesPeriodicUpdate() async {
    const secs = const Duration(seconds: 5);
    new Timer.periodic(secs, (Timer t) => updateHoldings());
  }

  // Used to contribute to a basket
  Future<Credentials> checkConfigPassword(String password) async {
    List<String> encryptedParams = await getEncryptedParamsFromConfigFile();
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

  void updateHoldings() async {
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
    //double seedTotalRaised;
    for (int i = 0; i < _fundingPanelItems.length; i++) {
      if (_fundingPanelItems[i].fundingPanelAddress.toLowerCase() ==
          fundingPanelAddress.toLowerCase()) {
        tokenAddress = _fundingPanelItems[i].tokenAddress;
        adminToolsAddress = _fundingPanelItems[i].adminToolsAddress;
        tags = _fundingPanelItems[i].tags;
        //seedTotalRaised = _fundingPanelItems[i].seedTotalRaised;
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
        'quotation': fundingPanels[i].latestDexQuotation,
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
}
