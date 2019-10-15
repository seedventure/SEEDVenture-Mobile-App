import 'package:shared_preferences/shared_preferences.dart';

final ChooseNetworkBloc chooseNetworkBloc = ChooseNetworkBloc();

class ChooseNetworkBloc {
  Future saveNetwork(String network) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString("network", network);
  }
}
