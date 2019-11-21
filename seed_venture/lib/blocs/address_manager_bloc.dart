import 'package:shared_preferences/shared_preferences.dart';
import 'package:seed_venture/utils/constants.dart';

final AddressManagerBloc addressManagerBloc = AddressManagerBloc();

class AddressManagerBloc {
  String _network;
  String _factoryAddress;
  String _seedTokenAddress;
  String _dexAddress;
  String _couponAddress;
  String _infuraEndpoint;
  String _etherscanURL;
  int _chainID;

  Future loadAddressList() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String network = sharedPreferences.getString("network");

    this._network = network;

    switch (network) {
      case Mainnet:
        _factoryAddress = MainnetGlobalFactoryAddress;
        _seedTokenAddress = MainnetSeedTokenAddress;
        _dexAddress = MainnetDexAddress;
        _couponAddress = MainnetCouponAddress;
        _infuraEndpoint = MainnetInfuraHTTP;
        _etherscanURL = MainnetEtherscanURL;
        _chainID = MainnetChainID;
        break;
      case Ropsten:
        _factoryAddress = RopstenGlobalFactoryAddress;
        _seedTokenAddress = RopstenSeedTokenAddress;
        _dexAddress = RopstenDexAddress;
        _couponAddress = RopstenCouponAddress;
        _infuraEndpoint = RopstenInfuraHTTP;
        _etherscanURL = RopstenEtherscanURL;
        _chainID = RopstenChainID;
        break;
    }
  }

  int get chainID => _chainID;
  String get factoryAddress => _factoryAddress;
  String get seedTokenAddress => _seedTokenAddress;
  String get dexAddress => _dexAddress;
  String get couponAddress => _couponAddress;
  String get infuraEndpoint => _infuraEndpoint;
  String get etherscanURL => _etherscanURL;
  String get network => _network;
}
