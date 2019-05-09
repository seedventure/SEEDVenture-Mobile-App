import 'package:flutter/material.dart';
import 'package:seed_venture/blocs/homepage_bloc.dart';
import 'package:seed_venture/blocs/bloc_provider.dart';
import 'package:seed_venture/pages/on_boarding_page.dart';
import 'package:seed_venture/pages/grid_page.dart';



class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    final HomePageBloc homePageBloc = BlocProvider.of<HomePageBloc>(context);

    return StreamBuilder(builder: (BuildContext context, AsyncSnapshot snapshot) {
      if (snapshot.hasData) {

        Widget returnedPage = snapshot.data == 1 ? GridPage() : OnBoardingPage();
        return returnedPage;


      } else {
        return CircularProgressIndicator();
      }
    },

    stream: homePageBloc.subject,);
  }
}