import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:seed_venture/blocs/address_manager_bloc.dart';

final HomePageBloc homePageBloc = HomePageBloc();

class HomePageBloc {
  PublishSubject<int> _firstLaunchSubject = PublishSubject<int>();

  Stream<int> get outFirstLaunch => _firstLaunchSubject.stream;
  Sink<int> get _inFirstLaunch => _firstLaunchSubject.sink;

  HomePageBloc() {
    SharedPreferences.getInstance().then((prefs) {
      bool isOnBoardingDone = prefs.getBool('on_boarding_done');
      if (isOnBoardingDone == null || isOnBoardingDone == false) {
        _inFirstLaunch.add(0);
      } else {
        _inFirstLaunch.add(1);
        addressManagerBloc.loadAddressList();
      }
    });
  }

  Future<void> handlePermissions() async {
    var platform = MethodChannel('seedventure.io/permissions');

    await platform.invokeMethod('getPermission', {});
  }

  Future<void> createMainDirIOS() async {
    var platform = MethodChannel('seedventure.io/create_main_dir');

    await platform.invokeMethod('createMainDir', {});
  }

  void dispose() {
    _firstLaunchSubject.close();
  }
}
