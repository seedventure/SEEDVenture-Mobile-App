import 'package:web3dart/web3dart.dart';
import 'package:hex/hex.dart';
import 'package:flutter/services.dart';
import 'package:seed_venture/models/funding_panel_item.dart';
import 'package:seed_venture/utils/address_constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import "package:web3dart/src/utils/numbers.dart" as numbers;
import 'package:crypto/crypto.dart' as crypto;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seed_venture/models/funding_panel_details.dart';
import 'package:seed_venture/blocs/onboarding_bloc.dart';
import 'dart:async';
import 'package:seed_venture/blocs/baskets_bloc.dart';

final ConfigManagerBloc configManagerBloc = ConfigManagerBloc();

class ConfigManagerBloc {
  Future createConfiguration(
      Credentials walletCredentials, String password) async {
    Map configurationMap = Map();
    List<FundingPanelItem> fundingPanelItems = List();
    List<FundingPanelDetails> fundingPanelDetails = List();

    Map localMap = {
      'lang_config_stuff': {'name': 'English (England)', 'code': 'en_EN'}
    };
    configurationMap.addAll(localMap);

    int currentBlockNumber = await getCurrentBlockNumber();
    Map lastCheckedBlockNumberMap = {
      'lastCheckedBlockNumber': currentBlockNumber
    };
    configurationMap.addAll(lastCheckedBlockNumberMap);

    await getFundingPanelItems(
        fundingPanelItems, fundingPanelDetails, configurationMap);

    Map userMapDecrypted = {
      'user': {
        'privateKey': walletCredentials.privateKey.toRadixString(16),
        'wallet': walletCredentials.address.hex,
        'list': []
      }
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

    OnBoardingBloc.setOnBoardingDone();
  }

  void saveConfigurationFile(Map configurationMap) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    String path = documentsDir.path;
    String configFilePath = '$path/configuration.json';
    File configFile = File(configFilePath);
    configFile.writeAsStringSync(jsonEncode(configurationMap));
  }

  String generateMd5(String input) {
    return crypto.md5.convert(utf8.encode(input)).toString();
  }

  Future<int> getCurrentBlockNumber() async {
    var url = "https://ropsten.infura.io/v3/2f35010022614bcb9dd4c5fefa9a64fd";
    Map callParams = {
      "id": "1",
      "jsonrpc": "2.0",
      "method": "eth_blockNumber",
      "params": []
    };

    var callResponse = await http.post(url,
        body: jsonEncode(callParams),
        headers: {'content-type': 'application/json'});

    Map resMap = jsonDecode(callResponse.body);

    return numbers.hexToInt(resMap['result']).toInt();
  }

  Future getFundingPanelItems(
      List<FundingPanelItem> fundingPanelItems,
      List<FundingPanelDetails> fundingPanelDetails,
      Map configurationMap) async {
    int length = await getLastDeployersLength();
    for (int index = 0; index < length; index++) {
      List<String> basketContracts = await getBasketContractsByIndex(
          index); // 0: Deployer, 1: AdminTools, 2: Token, 3: FundingPanel
      int exchangeRateSeed =
          await getBasketSeedExchangeRate(basketContracts[3]);
      Map latestOwnerData = await getLatestOwnerData(basketContracts[3]);
      List<Map> fpData = List();
      fpData.add(latestOwnerData);
      FundingPanelItem FPItem = FundingPanelItem(
          basketContracts[1],
          basketContracts[3],
          basketContracts[2],
          exchangeRateSeed.toString(),
          fpData);
      fundingPanelItems.add(FPItem);
    }

    List<Map> maps = List();

    for (int i = 0; i < fundingPanelItems.length; i++) {
      Map map = {
        'tokenAddress': fundingPanelItems[i].tokenAddress,
        'fundingPanelAddress': fundingPanelItems[i].fundingPanelAddress,
        'adminsToolsAddress': fundingPanelItems[i].adminToolsAddress,
        'lastDEXPrice': fundingPanelItems[i].lastDEXPrice,
        'fundingPanelUpdates': fundingPanelItems[i].fundingPanelUpdates
      };

      bool success = await getFundingPanelDetails(
          fundingPanelItems[i].fundingPanelUpdates[0]['url'],
          fundingPanelDetails,
          fundingPanelItems[i].fundingPanelAddress);

      if (success) {
        maps.add(map);
      }
    }
    Map FPListMap = {'list': maps};

    configurationMap.addAll(FPListMap);

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    List<Map> fpDetailsListMap = List();

    for (int i = 0; i < fundingPanelDetails.length; i++) {
      List<Map> members =
          await getMembersOfFundingPanel(fundingPanelDetails[i].address);

      Map map = {
        'name': fundingPanelDetails[i].name,
        'description': fundingPanelDetails[i].description,
        'url': fundingPanelDetails[i].url,
        'imgBase64': fundingPanelDetails[i].imgBase64,
        'funding_panel_address': fundingPanelDetails[i].address,
        'members': members
      };

      fpDetailsListMap.add(map);
    }

    sharedPreferences.setString(
        'funding_panels_details', jsonEncode(fpDetailsListMap));
  }

  Future<List<Map>> getMembersOfFundingPanel(String fundingPanelAddress) async {
    List<Map> members = List();
    int membersLength = await getMembersLength(fundingPanelAddress);

    for (int i = 0; i < membersLength; i++) {
      String memberAddress =
          await getMemberAddressByIndex(i, fundingPanelAddress);
      List<String> memberData =
          await getMemberDataByAddress(fundingPanelAddress, memberAddress);
      List<String> memberJsonData =
          await getMemberJSONDataFromIPFS(memberData[0]);

      Map member = {
        'member_address': memberAddress,
        'ipfsUrl': memberData[0],
        'hash': memberData[1],
        'name': memberJsonData[0],
        'description': memberJsonData[1],
        'url': memberJsonData[2],
        'imgBase64': memberJsonData[3]
      };

      members.add(member);
    }

    return members;
  }

  Future<List<String>> getMemberJSONDataFromIPFS(String ipfsURL) async {
    List<String> memberJsonData = List();
    var response = await http.get(ipfsURL);
    /*if (response.statusCode != 200) { // Gestire caso URL irraggiungibile?
      return false;
    }*/
    Map responseMap = jsonDecode(response.body);

    memberJsonData.add(responseMap['name']);
    memberJsonData.add(responseMap['description']);
    memberJsonData.add(responseMap['url']);
    memberJsonData.add(responseMap['image']);

    return memberJsonData;
  }

  Future<List<String>> getMemberDataByAddress(
      String fundingPanelAddress, String memberAddress) async {
    String data = "0xca87a8a1000000000000000000000000";

    data = data + memberAddress.substring(2);

    print(data);

    var url = "https://ropsten.infura.io/v3/2f35010022614bcb9dd4c5fefa9a64fd";
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

    var callResponse = await http.post(url,
        body: jsonEncode(callParams),
        headers: {'content-type': 'application/json'});

    Map resMap = jsonDecode(callResponse.body);

    String hash = resMap['result'].toString().substring(194, 258);

    HexDecoder a = HexDecoder();
    List byteArray = a.convert(resMap['result'].toString().substring(258));

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

    var url = "https://ropsten.infura.io/v3/2f35010022614bcb9dd4c5fefa9a64fd";
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

    var callResponse = await http.post(url,
        body: jsonEncode(callParams),
        headers: {'content-type': 'application/json'});

    Map resMap = jsonDecode(callResponse.body);

    String address = EthereumAddress(resMap['result'].toString()).hex;

    return address;
  }

  Future<int> getMembersLength(String fundingPanelAddress) async {
    String data = "0x7351262f"; // get deployerListLength
    var url = "https://ropsten.infura.io/v3/2f35010022614bcb9dd4c5fefa9a64fd";
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

    var callResponse = await http.post(url,
        body: jsonEncode(callParams),
        headers: {'content-type': 'application/json'});

    Map resMap = jsonDecode(callResponse.body);

    return numbers.hexToInt(resMap['result']).toInt();
  }

  Future<bool> getFundingPanelDetails(
      String url,
      List<FundingPanelDetails> fundingPanelDetailsList,
      String fundingPanelAddress) async {
    try {
      var response = await http.get(url);
      if (response.statusCode != 200) {
        return false;
      }
      Map responseMap = jsonDecode(response.body);
      fundingPanelDetailsList.add(FundingPanelDetails(
          responseMap['name'],
          responseMap['description'],
          responseMap['url'],
          responseMap['image'],
          fundingPanelAddress));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<int> getLastDeployersLength() async {
    String data = "0xe0118a53"; // get deployerListLength
    var url = "https://ropsten.infura.io/v3/2f35010022614bcb9dd4c5fefa9a64fd";
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

    var callResponse = await http.post(url,
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

    var url = "https://ropsten.infura.io/v3/2f35010022614bcb9dd4c5fefa9a64fd";
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

    var callResponse = await http.post(url,
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

  Future<int> getBasketSeedExchangeRate(String fundingPanelAddress) async {
    String data = "0x18bf6abc"; // get exchangeRateSeed
    var url = "https://ropsten.infura.io/v3/2f35010022614bcb9dd4c5fefa9a64fd";
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

    var callResponse = await http.post(url,
        body: jsonEncode(callParams),
        headers: {'content-type': 'application/json'});

    Map resMap = jsonDecode(callResponse.body);

    return numbers.hexToInt(resMap['result']).toInt();
  }

  Future<Map> getLatestOwnerData(String fundingPanelAddress) async {
    String data = "0xe4b85399"; // getOwnerData
    var url = "https://ropsten.infura.io/v3/2f35010022614bcb9dd4c5fefa9a64fd";
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

    var callResponse = await http.post(url,
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

  Future<String> getSingleFundingPanelContractAddress(int index) async {
    String data = "0x384a0df9";

    String indexHex = numbers.toHex(index);

    for (int i = 0; i < 64 - indexHex.length; i++) {
      data += "0";
    }

    data += indexHex;

    print(data);

    var url = "https://ropsten.infura.io/v3/2f35010022614bcb9dd4c5fefa9a64fd";
    Map callParams = {
      "id": "1",
      "jsonrpc": "2.0",
      "method": "eth_call",
      "params": [
        {
          "to": FPFactoryContractAddress,
          "data": data,
        },
        "latest"
      ]
    };

    var callResponse = await http.post(url,
        body: jsonEncode(callParams),
        headers: {'content-type': 'application/json'});

    Map resMap = jsonDecode(callResponse.body);

    print(callResponse.body);

    return EthereumAddress(resMap['result']).hex;
  }

  Future<String> getSingleFundingPanelTokenAddress(
      String fundingPanelContractAddress) async {
    String data = "0x10fe9ae8";

    var url = "https://ropsten.infura.io/v3/2f35010022614bcb9dd4c5fefa9a64fd";
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

    var callResponse = await http.post(url,
        body: jsonEncode(callParams),
        headers: {'content-type': 'application/json'});

    Map resMap = jsonDecode(callResponse.body);

    print(callResponse.body);

    return EthereumAddress(resMap['result']).hex;
  }

  Future<List<String>> getEncryptedParamsFromConfigFile() async {
    final documentsDir = await getApplicationDocumentsDirectory();
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

  void _update() async {
    Map configurationMap = Map();
    List<FundingPanelItem> fundingPanelItems = List();
    List<FundingPanelDetails> fundingPanelDetails = List();

    Map localMap = {
      'lang_config_stuff': {'name': 'English (England)', 'code': 'en_EN'}
    };
    configurationMap.addAll(localMap);

    int currentBlockNumber = await getCurrentBlockNumber();
    Map lastCheckedBlockNumberMap = {
      'lastCheckedBlockNumber': currentBlockNumber
    };
    configurationMap.addAll(lastCheckedBlockNumberMap);

    await getFundingPanelItems(
        fundingPanelItems, fundingPanelDetails, configurationMap);

    List<String> encryptedParams = await getEncryptedParamsFromConfigFile();

    // Da sostituire solo i campi dei fundingPanels in futuro
    Map userMapEncrypted = {
      'user' : {
        'data' : encryptedParams[0],
        'hash' : encryptedParams[1]
      }
    };

    configurationMap.addAll(userMapEncrypted);

    saveConfigurationFile(configurationMap);

    basketsBloc.updateBaskets();

    print('configuration updated!');


  }

  void periodicUpdate() {
    const fiveSec = const Duration(seconds: 45);
    Timer _timer = new Timer.periodic(fiveSec, (Timer t) => _update());
  }
}
