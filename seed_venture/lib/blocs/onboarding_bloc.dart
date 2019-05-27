import 'package:seed_venture/blocs/bloc_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/rxdart.dart';

class OnBoardingBloc implements BlocBase {

  PublishSubject subject = PublishSubject();


  void setOnBoardingDone(){
    SharedPreferences.getInstance().then((prefs){
      prefs.setBool('on_boarding_done', true);
    });
  }



  void dispose() {
    subject.close();
  }

}