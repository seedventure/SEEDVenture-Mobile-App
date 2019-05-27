import 'package:flutter/material.dart';
import 'package:seed_venture/blocs/homepage_bloc.dart';
import 'package:seed_venture/blocs/bloc_provider.dart';
import 'package:seed_venture/pages/on_boarding_page.dart';
import 'package:seed_venture/blocs/onboarding_bloc.dart';
import 'package:seed_venture/pages/grid_page.dart';
import 'package:seed_venture/blocs/gridpage_bloc.dart';



class HomePage extends StatelessWidget {



  @override
  Widget build(BuildContext context) {

    final HomePageBloc homePageBloc = BlocProvider.of<HomePageBloc>(context);

    if (Theme.of(context).platform == TargetPlatform.android) {
      homePageBloc.handlePermissions();
    }

    return StreamBuilder(builder: (BuildContext context, AsyncSnapshot snapshot) {
      if (snapshot.hasData) {

        homePageBloc.subject.close();

        Widget returnedPage = snapshot.data == 1 ? GridPage() : OnBoardingPage();
        BlocBase blocBase = snapshot.data == 1 ? GridPageBloc() : OnBoardingBloc();
        return BlocProvider(child: returnedPage, bloc: blocBase);


      } else {
        return CircularProgressIndicator();
      }
    },

    stream: homePageBloc.subject,);
  }
}