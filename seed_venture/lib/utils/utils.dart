import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import "package:web3dart/src/utils/numbers.dart" as numbers;
import 'package:seed_venture/blocs/address_manager_bloc.dart';

class Utils {
  static Image getImageFromBase64(String base64) {
    if (base64 != '') {
      return Image.memory(base64Decode(base64), width: 35.0, height: 35.0);
    } else {
      return Image.asset(
        'assets/watermelon.png',
        height: 35.0,
        width: 35.0,
      );
    }
  }

  /// commons crypto calls and operations

  static Future<int> estimateGas(
      String from, String to, String value, String data) async {
    Map txCountParams = {
      "id": "1",
      "jsonrpc": "2.0",
      "method": "eth_estimateGas",
      "params": [
        {
          "from": from,
          "to": to,
          "value": value,
          "data": data,
        }
      ]
    };

    var response = await http.post(addressManagerBloc.infuraEndpoint,
        body: jsonEncode(txCountParams),
        headers: {'content-type': 'application/json'});

    return numbers.hexToInt(jsonDecode(response.body)['result']).toInt();
  }

  static Future<String> postNonce(String address) async {
    Map txCountParams = {
      "id": "1",
      "jsonrpc": "2.0",
      "method": "eth_getTransactionCount",
      "params": ["$address", "latest"]
    };

    var response = await http.post(addressManagerBloc.infuraEndpoint,
        body: jsonEncode(txCountParams),
        headers: {'content-type': 'application/json'});

    return response.body;
  }

  static BigInt parseNonceJSON(String nonceResponseBody) {
    return (numbers.hexToInt(jsonDecode(nonceResponseBody)['result']));
  }

  static String parseTxHashJSON(String sendResponseBody) {
    return jsonDecode(sendResponseBody)['result'];
  }
}
