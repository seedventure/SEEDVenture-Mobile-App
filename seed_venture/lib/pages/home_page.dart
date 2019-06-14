import 'package:flutter/material.dart';
import 'package:seed_venture/blocs/home_page_bloc.dart';
import 'package:seed_venture/pages/on_boarding_page.dart';
import 'package:seed_venture/pages/baskets_page.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).platform == TargetPlatform.android) {
      homePageBloc.handlePermissions();
    }

    return StreamBuilder(
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data == 1) {
            return BasketsPage();
          } else {
            return OnBoardingPage();
          }
        } else {
          return CircularProgressIndicator();
        }
      },
      stream: homePageBloc.outFirstLaunch,
    );
  }
}
