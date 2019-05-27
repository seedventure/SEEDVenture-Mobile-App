import 'package:rxdart/rxdart.dart';
import 'package:seed_venture/blocs/bloc_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';


class HomePageBloc implements BlocBase {

  PublishSubject subject = PublishSubject();

  HomePageBloc(){




    SharedPreferences.getInstance().then((prefs){
      if(prefs.getBool('on_boarding_done') != null){
        subject.add(1);
      }
      else{
        subject.add(0);
      }

    });
  }


  Future<void> handlePermissions() async {
    var platform = MethodChannel('seedventure.io/permissions');

    await platform.invokeMethod('getPermission', {});
  }



  void dispose(){
    subject.close();
  }
}