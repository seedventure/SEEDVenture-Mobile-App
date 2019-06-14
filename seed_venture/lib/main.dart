import 'package:flutter/material.dart';
import 'package:seed_venture/pages/home_page.dart';
import 'package:seed_venture/pages/baskets_page.dart';
import 'package:flutter/services.dart';

void main() {
  return runApp(SeedVentureApp());
}

class SeedVentureApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            // Define the default Brightness and Colors
            brightness: Brightness.light,
            primaryColor: Colors.lightBlue[800],
            accentColor: Colors.orangeAccent,
            buttonColor: Colors.lightBlue[800],

            // Define the default Font Family
            fontFamily: 'Montserrat',

            // Define the default TextTheme. Use this to specify the default
            // text styling for headlines, titles, bodies of text, and more.
            textTheme: TextTheme(
                headline:
                    TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
                title: TextStyle(fontSize: 36.0, fontStyle: FontStyle.italic),
                body1: TextStyle(fontSize: 14.0, fontFamily: 'Hind'),
                button:
                    TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold))),
        title: 'SeedVenture',
        home: HomePage(),
        routes: <String, WidgetBuilder>{
          '/home': (BuildContext context) {
            return BasketsPage();
          },
        });
  }
}
