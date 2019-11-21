import 'package:flutter/material.dart';
import 'package:seed_venture/pages/home_page.dart';
import 'package:flutter/services.dart';
import 'package:seed_venture/pages/settings_page.dart';
import 'package:seed_venture/pages/home_baskets_token_balances_page.dart';
import 'package:seed_venture/pages/wallet_info_page.dart';
import 'package:seed_venture/pages/unlock_account_page.dart';
import 'package:seed_venture/pages/on_boarding_page.dart';
import 'package:seed_venture/pages/single_basket_page.dart';
import 'package:seed_venture/pages/startup_list_page.dart';
import 'package:seed_venture/pages/single_startup_page.dart';
import 'package:seed_venture/pages/my_wallet_page.dart';
import 'package:seed_venture/pages/insert_password_import_page.dart';
import 'package:seed_venture/pages/create_wallet_page.dart';
import 'package:seed_venture/pages/import_wallet_page.dart';
import 'package:seed_venture/pages/insert_password_mnemonic_page.dart';
import 'package:seed_venture/pages/repeat_mnemonic_page.dart';
import 'package:seed_venture/pages/coupons_page.dart';

void main() {
  return runApp(SEEDVentureApp());
}

class SEEDVentureApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: Color(0xFF006B97),
            accentColor: Color(0xFF6fd2fb),
            buttonColor: Color(0xFF006B97),
            fontFamily: 'Poppins-Regular',
            textTheme: TextTheme(
                headline:
                    TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
                title: TextStyle(fontSize: 20.0),
                body1: TextStyle(fontSize: 14.0, fontFamily: 'Hind'),
                button:
                    TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold))),
        title: 'SEED Venture',
        home: HomePage(),
        routes: <String, WidgetBuilder>{
          '/unlock_account': (BuildContext context) {
            return UnlockAccountPage();
          },
          '/on_boarding': (BuildContext context) {
            return OnBoardingPage();
          },
          '/create_wallet_page': (BuildContext context) {
            return CreateWalletPage();
          },
          '/import_wallet_page': (BuildContext context) {
            return ImportWalletPage();
          },
          '/insert_password_import_page': (BuildContext context) {
            return InsertPasswordImportPage();
          },
          '/insert_password_mnemonic_page': (BuildContext context) {
            return InsertPasswordMnemonicPage();
          },
          '/repeat_mnemonic_page': (BuildContext context) {
            return RepeatMnemonicPage();
          },
          '/home': (BuildContext context) {
            return HomeBasketsTokenBalancesPage();
          },
          '/my_wallet': (BuildContext context) {
            return MyWalletPage();
          },
          '/single_basket': (BuildContext context) {
            return SingleBasketPage();
          },
          '/single_startup': (BuildContext context) {
            return SingleStartupPage();
          },
          '/startups': (BuildContext context) {
            return StartupListPage();
          },
          '/settings': (BuildContext context) {
            return SettingsPage();
          },
          '/wallet_info': (BuildContext context) {
            return WalletInfoPage();
          },
          '/coupons': (BuildContext context) {
            return CouponsPage();
          }
        });
  }
}
