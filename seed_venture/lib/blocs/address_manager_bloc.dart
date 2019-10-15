import 'package:shared_preferences/shared_preferences.dart';
import 'package:seed_venture/utils/constants.dart';

final AddressManagerBloc addressManagerBloc = AddressManagerBloc();

class AddressManagerBloc {
  String _factoryAddress;
  String _seedTokenAddress;
  String _dexAddress;
  String _infuraEndpoint;
  String _etherscanURL;

  Future loadAddressList() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String network = sharedPreferences.getString("network");

    switch (network) {
      case Mainnet:
        _factoryAddress = MainnetGlobalFactoryAddress;
        _seedTokenAddress = MainnetSeedTokenAddress;
        _dexAddress = MainnetDexAddress;
        _infuraEndpoint = MainnetInfuraHTTP;
        _etherscanURL = MainnetEtherscanURL;
        break;
      case Ropsten:
        _factoryAddress = RopstenGlobalFactoryAddress;
        _seedTokenAddress = RopstenSeedTokenAddress;
        _dexAddress = RopstenDexAddress;
        _infuraEndpoint = RopstenInfuraHTTP;
        _etherscanURL = RopstenEtherscanURL;
        break;
    }
  }

  String get factoryAddress => _factoryAddress;
  String get seedTokenAddress => _seedTokenAddress;
  String get dexAddress => _dexAddress;
  String get infuraEndpoint => _infuraEndpoint;
  String get etherscanURL => _etherscanURL;
}
