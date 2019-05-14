import 'package:flutter/material.dart';
import 'package:seed_venture/blocs/createconfig_bloc.dart';
import 'package:seed_venture/blocs/bloc_provider.dart';

class CreateConfigPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final CreateConfigBloc createConfigBloc =
        BlocProvider.of<CreateConfigBloc>(context);

    createConfigBloc.getRandomMnemonic();

    return Scaffold(
      appBar: AppBar(
        title: Text('Create Config'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(bottom: 30.0),
            child: Row(
              children: <Widget>[
                Expanded(
                    child: Container(
                        height: 20.0,
                        child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Center(
                                child: Text(
                                    'Copy these words and DON\'T FORGET THEM!')))))
              ],
            ),
          ),
          StreamBuilder(
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                return Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                            child: Container(
                          child: Text(snapshot.data),
                          margin: EdgeInsets.all(20.0),
                        ))
                      ],
                    ),
                    RaisedButton(
                      onPressed: () {
                        createConfigBloc.copyMnemonicToClipboard(snapshot.data);

                        SnackBar copySnack = SnackBar(
                            content: Text('Address copied on clipboard!'));
                        Scaffold.of(context).showSnackBar(copySnack);
                      },
                      child:
                          Text('COPY', style: TextStyle(color: Colors.white)),
                    )
                  ],
                );
              } else {
                return CircularProgressIndicator();
              }
            },
            stream: createConfigBloc.subject,
          )
        ],
      ),
    );
  }
}
