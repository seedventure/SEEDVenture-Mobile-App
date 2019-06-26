import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:seed_venture/utils/address_constants.dart';
import "package:web3dart/src/utils/numbers.dart" as numbers;
import 'dart:math';
import 'package:seed_venture/blocs/config_manager_bloc.dart';
import 'package:web3dart/web3dart.dart';
import 'package:flutter/foundation.dart';
import 'package:web3dart/src/io/rawtransaction.dart';
import 'dart:async';
import 'package:rxdart/rxdart.dart';

final ContributionBloc contributionBloc = ContributionBloc();

class ContributionBloc {
  PublishSubject<bool> _configurationWrongPassword = PublishSubject<bool>();

  Stream<bool> get outConfigurationWrongPassword =>
      _configurationWrongPassword.stream;
  Sink<bool> get _inConfigurationWrongPassword =>
      _configurationWrongPassword.sink;

  PublishSubject<bool> _errorInContributionTransaction = PublishSubject<bool>();

  Stream<bool> get outErrorInContributionTransaction =>
      _errorInContributionTransaction.stream;
  Sink<bool> get _inErrorInContributionTransaction =>
      _errorInContributionTransaction.sink;

  PublishSubject<bool> _transactionSuccess = PublishSubject<bool>();

  Stream<bool> get outTransactionSuccess => _transactionSuccess.stream;
  Sink<bool> get _inTransactionSuccess => _transactionSuccess.sink;

  Future contribute(
      String seedAmount, String configPassword, String fpAddress) async {
    Credentials credentials =
        await configManagerBloc.checkConfigPassword(configPassword);
    if (credentials == null) {
      _inConfigurationWrongPassword.add(true);
      return;
    }

    String approveTxHash = await approve(credentials, seedAmount, fpAddress);

    if (approveTxHash != null) {
      print('approve ok!!!');

      Timer waitForApproveTimer = await waitForApproveTx(approveTxHash);

      const oneSec = const Duration(seconds: 1);
      Timer.periodic(oneSec, (Timer thisTimer) async {
        if (!waitForApproveTimer.isActive) {
          thisTimer.cancel();
          String txHash =
              await holderSendSeeds(credentials, seedAmount, fpAddress);

          if (txHash == null) {
            _inErrorInContributionTransaction.add(true);
          } else {
            //  await waitForHolderSendSeedsTx(txHash); Da gestire track transaction HolderSendSeeds: notifica quando completata?

            _inTransactionSuccess.add(true);
          }
        }
      });
    } else {
      _inErrorInContributionTransaction.add(true);
    }
  }

  Future<String> _postNonce(String address) async {
    var url = "https://ropsten.infura.io/v3/2f35010022614bcb9dd4c5fefa9a64fd";

    Map txCountParams = {
      "id": "1",
      "jsonrpc": "2.0",
      "method": "eth_getTransactionCount",
      "params": ["$address", "latest"]
    };

    var response = await http.post(url,
        body: jsonEncode(txCountParams),
        headers: {'content-type': 'application/json'});

    return response.body;
  }

  static BigInt _parseNonceJSON(String nonceResponseBody) {
    return (numbers.hexToInt(jsonDecode(nonceResponseBody)['result']));
  }

  static String _parseTxHashJSON(String sendResponseBody) {
    return jsonDecode(sendResponseBody)['result'];
  }

  Future<String> _sendApproveTransaction(Credentials credentials,
      String fpAddress, String amountToApprove, BigInt nonce) async {


    amountToApprove = amountToApprove.replaceAll(',', '.');

    if (amountToApprove.contains('.')) {
      int i;
      for (i = 0; i != amountToApprove.indexOf('.'); i++) {}

      amountToApprove = amountToApprove.replaceAll('.', '');

      int amountToApproveLength = amountToApprove.length;

      for (int k = 0; k < 18 - (amountToApproveLength - i); k++) {
        amountToApprove += '0';
      }
    } else {
      amountToApprove = amountToApprove + '000000000000000000';
    }

    String approveValuePowed = amountToApprove;

    String hex = BigInt.parse(approveValuePowed).toRadixString(16);

    while (hex.length != 64) {
      hex = '0' + hex;
    }

    var url = "https://ropsten.infura.io/v3/2f35010022614bcb9dd4c5fefa9a64fd";
    String data = "0x095ea7b3000000000000000000000000";

    data = data + fpAddress.substring(2);

    data = data + hex;

    RawTransaction rawTx = new RawTransaction(
      nonce: nonce.toInt(),
      gasPrice: 10000000000,
      gasLimit: 70000,
      to: EthereumAddress(SeedTokenAddress).number,
      value: BigInt.from(0),
      data: numbers.hexToBytes(data),
    );

    var signed = rawTx.sign(numbers.numberToBytes(credentials.privateKey), 3);

    Map sendParams = {
      "id": "1",
      "jsonrpc": "2.0",
      "method": "eth_sendRawTransaction",
      "params": [numbers.bytesToHex(signed, include0x: true)]
    };
    var response = await http.post(url,
        body: jsonEncode(sendParams),
        headers: {'content-type': 'application/json'});
    return response.body;
  }

  Future<String> approve(
      Credentials credentials, String seedAmount, String fpAddress) async {
    String address = credentials.address.hex;
    String nonceResponse = await _postNonce(address);
    BigInt nonce = await compute(_parseNonceJSON, nonceResponse);
    String txResponse = await _sendApproveTransaction(
        credentials, fpAddress, seedAmount, nonce);
    if (!txResponse.contains('error')) {
      String txHash = await compute(_parseTxHashJSON, txResponse);
      return txHash;
    } else {
      return null;
    }
  }

  Future<String> _holderSendSeedsTransaction(Credentials credentials,
      String fpAddress, String seed, BigInt nonce) async {

    seed = seed.replaceAll(',', '.');

    if (seed.contains('.')) {
      int i;
      for (i = 0; i != seed.indexOf('.'); i++) {}

      seed = seed.replaceAll('.', '');

      int amountToApproveLength = seed.length;

      for (int k = 0; k < 18 - (amountToApproveLength - i); k++) {
        seed += '0';
      }
    } else {
      seed = seed + '000000000000000000';
    }

    String seedPowed = seed;

    String hex = BigInt.parse(seedPowed).toRadixString(16);

    while (hex.length != 64) {
      hex = '0' + hex;
    }

    var url = "https://ropsten.infura.io/v3/2f35010022614bcb9dd4c5fefa9a64fd";
    String data = "0x05f5c1b1";

    data = data + hex;

    RawTransaction rawTx = new RawTransaction(
      nonce: nonce.toInt(),
      gasPrice: 10000000000,
      gasLimit: 150000,
      to: EthereumAddress(fpAddress).number,
      value: BigInt.from(0),
      data: numbers.hexToBytes(data),
    );

    var signed = rawTx.sign(numbers.numberToBytes(credentials.privateKey), 3);

    Map sendParams = {
      "id": "1",
      "jsonrpc": "2.0",
      "method": "eth_sendRawTransaction",
      "params": [numbers.bytesToHex(signed, include0x: true)]
    };
    var response = await http.post(url,
        body: jsonEncode(sendParams),
        headers: {'content-type': 'application/json'});
    return response.body;
  }

  Future<Timer> waitForHolderSendSeedsTx(String txHash) async {
    const fiveSec = const Duration(seconds: 3);
    return Timer.periodic(fiveSec, (Timer t) {
      trackTransaction(txHash, t);
    });
  }

  Future<Timer> waitForApproveTx(String txHash) async {
    const fiveSec = const Duration(seconds: 3);
    return Timer.periodic(fiveSec, (Timer t) {
      trackTransaction(txHash, t);
    });
  }

  Future<void> trackTransaction(String txHash, Timer t) async {
    var url = "https://ropsten.infura.io/v3/2f35010022614bcb9dd4c5fefa9a64fd";
    Map sendParams = {
      "id": "1",
      "jsonrpc": "2.0",
      "method": "eth_getTransactionReceipt",
      "params": [txHash]
    };
    var response = await http.post(url,
        body: jsonEncode(sendParams),
        headers: {'content-type': 'application/json'});
    Map jsonResponse = jsonDecode(response.body);

    if (jsonResponse['result'] != null) {
      t.cancel();
    }
  }

  Future<String> holderSendSeeds(
      Credentials credentials, String seedAmount, String fpAddress) async {
    String address = credentials.address.hex;
    String nonceResponse = await _postNonce(address);
    BigInt nonce = await compute(_parseNonceJSON, nonceResponse);
    String txResponse = await _holderSendSeedsTransaction(
        credentials, fpAddress, seedAmount, nonce);
    if (!txResponse.contains('error')) {
      String txHash = await compute(_parseTxHashJSON, txResponse);
      return txHash;
    } else {
      return null;
    }
  }
}
