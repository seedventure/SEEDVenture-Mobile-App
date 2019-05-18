import 'package:flutter/material.dart';
import 'package:seed_venture/blocs/createconfig_bloc.dart';
import 'package:seed_venture/blocs/bloc_provider.dart';
import 'package:seed_venture/pages/repeat_mnemonic_page.dart';
import 'package:seed_venture/blocs/repeatmnemonic_bloc.dart';

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
        body: Container(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                  margin: const EdgeInsets.only(
                      left: 10.0, top: 10.0, right: 10.0, bottom: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: Center(
                            child: Text(
                                'Copy these words and DON\'T FORGET THEM!')),
                      )
                    ],
                  )),
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
                            createConfigBloc
                                .copyMnemonicToClipboard(snapshot.data);

                            final snackBar = SnackBar(
                                content: Text('Mnemonic Words copied!'));
                            Scaffold.of(context).showSnackBar(snackBar);
                          },
                          child: Text('COPY',
                              style: TextStyle(color: Colors.white)),
                        ),
                        RaisedButton(
                          onPressed: () {
                            createConfigBloc.dispose();
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (BuildContext context) {
                              return BlocProvider<RepeatMnemonicBloc>(
                                bloc: RepeatMnemonicBloc(),
                                child: RepeatMnemonicPage(
                                  rightMnemonic: snapshot.data,
                                ),
                              );
                            })
                            );
                          },
                          child: Text('Continue',
                              style: TextStyle(color: Colors.white)),
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
        ));
  }
}
