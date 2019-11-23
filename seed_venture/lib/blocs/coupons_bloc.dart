import 'package:barcode_scan/barcode_scan.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:seed_venture/blocs/address_manager_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:web3dart/web3dart.dart';
import 'package:seed_venture/blocs/config_manager_bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:web3dart/src/io/rawtransaction.dart';
import 'package:seed_venture/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:seed_venture/utils/constants.dart';
import "package:web3dart/src/utils/numbers.dart" as numbers;
import 'package:http/http.dart' as http;
import 'dart:math';
import 'dart:async';
import 'package:hex/hex.dart';

final couponsBloc = CouponsBloc();

class CouponsBloc {
  String couponCode;
  String codeAndAddressHash;

  PublishSubject<bool> _passwordDialog = PublishSubject<bool>();

  Stream<bool> get outPasswordDialog => _passwordDialog.stream;
  Sink<bool> get _inPasswordDialog => _passwordDialog.sink;

  PublishSubject<bool> _wrongPassword = PublishSubject<bool>();

  Stream<bool> get outWrongPassword => _wrongPassword.stream;
  Sink<bool> get _inWrongPassword => _wrongPassword.sink;

  PublishSubject<bool> _redeemError = PublishSubject<bool>();

  Stream<bool> get outRedeemError => _redeemError.stream;
  Sink<bool> get _inRedeemError => _redeemError.sink;

  PublishSubject<bool> _wrongRedeemCode = PublishSubject<bool>();

  Stream<bool> get outWrongRedeemCode => _wrongRedeemCode.stream;
  Sink<bool> get _inWrongRedeemCode => _wrongRedeemCode.sink;

  PublishSubject<String> _redeemSuccess = PublishSubject<String>();

  Stream<String> get outRedeemSuccess => _redeemSuccess.stream;
  Sink<String> get _inRedeemSuccess => _redeemSuccess.sink;

  void initStreams() {
    this._redeemError = PublishSubject<bool>();
    this._wrongPassword = PublishSubject<bool>();
    this._passwordDialog = PublishSubject<bool>();
    this._redeemSuccess = PublishSubject<String>();
    this._wrongRedeemCode = PublishSubject<bool>();
  }

  Future scan() async {
    try {
      String barcode = await BarcodeScanner.scan();
      this.couponCode = barcode;
      await _computeCodeAndAddressHash(this.couponCode);
      _inPasswordDialog.add(true);
    } on Exception catch (e) {
      print(e.toString());
    }
  }

  void setCouponCode(String couponCode) async {
    this.couponCode = couponCode;
    await _computeCodeAndAddressHash(this.couponCode);
  }

  Future _computeCodeAndAddressHash(String couponCode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String address = prefs.getString('address');
    this.codeAndAddressHash = crypto.sha256
        .convert(utf8.encode(couponCode + address.toLowerCase()))
        .toString();
  }

  Future<String> _preRedeem(
      Credentials credentials, String codeAndAddressHash) async {
    String address = credentials.address.hex;
    String nonceResponse = await Utils.postNonce(address);
    BigInt nonce = await compute(Utils.parseNonceJSON, nonceResponse);

    String data = "0x598064c8";

    data = data + codeAndAddressHash;

    int gasLimit = await Utils.estimateGas(
        address, addressManagerBloc.couponAddress, '0x0', data);

    RawTransaction rawTx = new RawTransaction(
      nonce: nonce.toInt(),
      gasPrice: DefaultGasPrice * pow(10, 9),
      gasLimit: gasLimit,
      to: EthereumAddress(addressManagerBloc.couponAddress).number,
      value: BigInt.from(0),
      data: numbers.hexToBytes(data),
    );

    var signed = rawTx.sign(numbers.numberToBytes(credentials.privateKey),
        addressManagerBloc.chainID);

    Map sendParams = {
      "id": "1",
      "jsonrpc": "2.0",
      "method": "eth_sendRawTransaction",
      "params": [numbers.bytesToHex(signed, include0x: true)]
    };
    var response = await http.post(addressManagerBloc.infuraEndpoint,
        body: jsonEncode(sendParams),
        headers: {'content-type': 'application/json'});
    return response.body;
  }

  Future<String> _redeem(Credentials credentials, String couponCode) async {
    String address = credentials.address.hex;
    String nonceResponse = await Utils.postNonce(address);
    BigInt nonce = await compute(Utils.parseNonceJSON, nonceResponse);

    String data =
        "0xb77e081c0000000000000000000000000000000000000000000000000000000000000020";

    String hexLength = couponCode.length.toRadixString(16);

    while (hexLength.length < 64) {
      hexLength = '0$hexLength';
    }

    String hexCode = HEX.encode(utf8.encode(couponCode));

    while (hexCode.length < 64) {
      hexCode = hexCode + '0';
    }

    data = data + hexLength + hexCode;

    int gasLimit;
    try {
      gasLimit = await Utils.estimateGas(
          address, addressManagerBloc.couponAddress, '0x0', data);
    } catch (e) {
      _inWrongRedeemCode.add(
          true); // if estimateGas fails, the transactions can't be executed
      return null;
    }

    RawTransaction rawTx = new RawTransaction(
      nonce: nonce.toInt(),
      gasPrice: DefaultGasPrice * pow(10, 9),
      gasLimit: gasLimit,
      to: EthereumAddress(addressManagerBloc.couponAddress).number,
      value: BigInt.from(0),
      data: numbers.hexToBytes(data),
    );

    var signed = rawTx.sign(numbers.numberToBytes(credentials.privateKey),
        addressManagerBloc.chainID);

    Map sendParams = {
      "id": "1",
      "jsonrpc": "2.0",
      "method": "eth_sendRawTransaction",
      "params": [numbers.bytesToHex(signed, include0x: true)]
    };
    var response = await http.post(addressManagerBloc.infuraEndpoint,
        body: jsonEncode(sendParams),
        headers: {'content-type': 'application/json'});
    return response.body;
  }

  Future redeemCode(String password) async {
    Credentials credentials =
        await configManagerBloc.checkConfigPassword(password);
    if (credentials == null) {
      _inWrongPassword.add(true);
      return;
    }

    String txResponse = await _preRedeem(credentials, this.codeAndAddressHash);
    if (txResponse.contains('error')) {
      _inRedeemError.add(true);
      return;
    }

    String txHash = await compute(Utils.parseTxHashJSON, txResponse);

    Timer waitForPreRedeemTimer = await _waitForPreRedeemTx(txHash);
    const oneSec = const Duration(seconds: 1);
    Timer.periodic(oneSec, (Timer thisTimer) async {
      if (!waitForPreRedeemTimer.isActive) {
        thisTimer.cancel();

        String txResponse = await _redeem(credentials, couponCode);

        if (txResponse == null) return;

        if (txResponse.contains('error')) {
          _inRedeemError.add(true);
          return;
        }

        String txHash = await compute(Utils.parseTxHashJSON, txResponse);

        if (txHash != null) {
          _inRedeemSuccess.add(txHash);
        }
      }
    });
  }

  Future<Timer> _waitForPreRedeemTx(String txHash) async {
    const fiveSec = const Duration(seconds: 3);
    return Timer.periodic(fiveSec, (Timer t) {
      trackTransaction(txHash, t);
    });
  }

  Future<void> trackTransaction(String txHash, Timer t) async {
    Map sendParams = {
      "id": "1",
      "jsonrpc": "2.0",
      "method": "eth_getTransactionReceipt",
      "params": [txHash]
    };
    var response = await http.post(addressManagerBloc.infuraEndpoint,
        body: jsonEncode(sendParams),
        headers: {'content-type': 'application/json'});
    Map jsonResponse = jsonDecode(response.body);

    if (jsonResponse['result'] != null) {
      t.cancel();
    }
  }

  void dispose() {
    _wrongRedeemCode.close();
    _redeemSuccess.close();
    _redeemError.close();
    _passwordDialog.close();
    _wrongPassword.close();
  }
}
