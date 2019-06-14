import 'package:shared_preferences/shared_preferences.dart';

class OnBoardingBloc {
  static void setOnBoardingDone() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('on_boarding_done', true);
    });
  }
}
