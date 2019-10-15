import 'package:flutter/material.dart';
import 'package:seed_venture/blocs/import_logic_bloc.dart';
import 'package:seed_venture/widgets/progress_bar_overlay.dart';
import 'package:seed_venture/pages/choose_network_page.dart';

class InsertPasswordImportPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _InsertPasswordImportPageState();
}

class _InsertPasswordImportPageState extends State<InsertPasswordImportPage> {
  final TextEditingController passwordController = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    importLogicBloc.outImportStatus.listen((done) {
      if (done) {
        Navigator.pop(context);
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (Route<dynamic> route) => false);
      }
    });

    importLogicBloc.outWrongPassword.listen((wrong) {
      if (wrong) {
        Navigator.pop(context);
        SnackBar wrongPasswordSnackBar =
            SnackBar(content: Text('Wrong Password'));
        _scaffoldKey.currentState.showSnackBar(wrongPasswordSnackBar);
      } else {
        Navigator.pop(context);
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (BuildContext context) {
          return ChooseNetworkPage(mode: ChooseNetworkPage.FromImport);
        }));
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text('Insert Password'),
        ),
        body: Container(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                child: TextField(
                  obscureText: true,
                  controller: passwordController,
                  decoration: InputDecoration(
                      border: InputBorder.none, hintText: 'Password...'),
                ),
                margin: const EdgeInsets.only(
                    left: 20.0, right: 20.0, top: 10.0, bottom: 10.0),
              ),
              RaisedButton(
                onPressed: () {
                  Navigator.of(context).push(
                      ProgressBarOverlay(ProgressBarOverlay.checkingPassword));
                  importLogicBloc.import(passwordController.text);
                },
                child: Text('Import', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ));
  }
}
