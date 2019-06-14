import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

final HomePageBloc homePageBloc = HomePageBloc();

class HomePageBloc  {
  PublishSubject<int> _firstLaunchSubject = PublishSubject<int>();

  Stream<int> get outFirstLaunch => _firstLaunchSubject.stream;
  Sink<int> get _inFirstLaunch => _firstLaunchSubject.sink;

  HomePageBloc() {
    SharedPreferences.getInstance().then((prefs) {
      if (prefs.getBool('on_boarding_done') != null) {
        _inFirstLaunch.add(1);
      } else {
        _inFirstLaunch.add(0);
      }
    });
  }

  Future<void> handlePermissions() async {
    var platform = MethodChannel('seedventure.io/permissions');

    await platform.invokeMethod('getPermission', {});
  }

  void dispose() {
    _firstLaunchSubject.close();
  }
}
