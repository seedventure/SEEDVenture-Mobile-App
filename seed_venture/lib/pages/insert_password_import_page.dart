import 'package:flutter/material.dart';
import 'package:seed_venture/blocs/bloc_provider.dart';
import 'package:seed_venture/blocs/mnemonic_logic_bloc.dart';

class InsertPasswordImportPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _InsertPasswordImportPageState();
}

class _InsertPasswordImportPageState extends State<InsertPasswordImportPage>{

  final TextEditingController passwordController = TextEditingController();



  @override
  Widget build(BuildContext context) {

   /* final MnemonicLogicBloc mnemonicLogicBloc =
    BlocProvider.of<MnemonicLogicBloc>(context);*/



    return Scaffold(
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
                  controller: passwordController,
                  decoration: InputDecoration(
                      border: InputBorder.none, hintText: 'Password...'),
                ),
                margin: const EdgeInsets.only(left: 20.0, right: 20.0, top: 10.0, bottom: 10.0),
              ),
              RaisedButton(
                onPressed: () {

                },
                child: Text('Import', style: TextStyle(color: Colors.white)),
              ),


            ],
          ),
        ));
  }
}
