import 'package:flutter/material.dart';
import 'package:seed_venture/blocs/baskets_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:seed_venture/utils/utils.dart';
import 'package:seed_venture/blocs/members_bloc.dart';
import 'package:seed_venture/blocs/contribution_bloc.dart';
import 'package:seed_venture/widgets/progress_bar_overlay.dart';

class SingleBasketPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SingleBasketPageState();
}

class _SingleBasketPageState extends State<SingleBasketPage> {
  final _scaffoldKey = new GlobalKey<ScaffoldState>();

  Future _showConfigPasswordDialog(String seedAmount) async {
    TextEditingController passwordController = TextEditingController();

    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return new SimpleDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  child: Text('Insert Password'),
                  margin: EdgeInsets.only(bottom: 10.0),
                )
              ],
            ),
            children: <Widget>[
              Column(
                children: <Widget>[
                  Container(
                    child: TextField(
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                          border: InputBorder.none, hintText: 'Password...'),
                      controller: passwordController,
                      obscureText: true,
                    ),
                    height: 50,
                    width: double.infinity,
                    margin: EdgeInsets.all(20.0),
                  ),
                  Container(
                    margin:
                        EdgeInsets.only(right: 20.0, left: 20.0, bottom: 20.0),
                    child: RaisedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(ProgressBarOverlay(
                            ProgressBarOverlay.sendingTransaction));
                        contributionBloc.contribute(
                            seedAmount,
                            passwordController.text,
                            basketsBloc.getCurrentFundingPanelAddress());
                      },
                      child: const Text(
                        'Contribute to Basket',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                ],
                crossAxisAlignment: CrossAxisAlignment.center,
              )
            ],
          );
        });
  }

  Future _showContributeDialog() async {
    TextEditingController amountController = TextEditingController();

    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return new SimpleDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  child: Text('Contribute to Basket'),
                  margin: EdgeInsets.only(bottom: 10.0),
                )
              ],
            ),
            children: <Widget>[
              Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          child: Text(
                              'Remember that you have to be whitelisted to contribute to this basket!'),
                          margin: const EdgeInsets.only(left: 8.0, right: 8.0),
                        ),
                      )
                    ],
                  ),
                  Container(
                    child: TextField(
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                          border: InputBorder.none, hintText: 'Amount...'),
                      controller: amountController,
                    ),
                    height: 50,
                    width: double.infinity,
                    margin: EdgeInsets.all(20.0),
                  ),
                  Container(
                    margin:
                        EdgeInsets.only(right: 20.0, left: 20.0, bottom: 20.0),
                    child: RaisedButton(
                      onPressed: () {
                        Navigator.pop(context);

                        if (contributionBloc
                            .hasEnoughFunds(amountController.text)) {
                          _showConfigPasswordDialog(amountController.text);
                        } else {
                          SnackBar error =
                              SnackBar(content: Text('Insufficient Funds'));
                          _scaffoldKey.currentState.showSnackBar(error);
                        }
                      },
                      child: const Text(
                        'Next',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                ],
                crossAxisAlignment: CrossAxisAlignment.center,
              )
            ],
          );
        });
  }

  @override
  void initState() {
    contributionBloc.outConfigurationWrongPassword.listen((wrong) {
      if (wrong) {
        Navigator.pop(context);
        SnackBar wrongPasswordSnackBar =
            SnackBar(content: Text('Wrong Password'));
        _scaffoldKey.currentState.showSnackBar(wrongPasswordSnackBar);
      }
    });

    contributionBloc.outErrorInContributionTransaction.listen((error) {
      if (error) {
        Navigator.pop(context);
        SnackBar txErrorSnackBar = SnackBar(
            content: Text(
                'There was an error in your transaction: check your funds or whitelisting!'));
        _scaffoldKey.currentState.showSnackBar(txErrorSnackBar);
      }
    });

    contributionBloc.outTransactionSuccess.listen((success) {
      if (success) {
        Navigator.pop(context);
        SnackBar contributedSnackBar = SnackBar(
            content: Text(
                'You have contributed to this project! Your balance is being updated...'));
        _scaffoldKey.currentState.showSnackBar(contributedSnackBar);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        key: _scaffoldKey,
        appBar: new AppBar(
          title: new Text('Basket'),
        ),
        body: StreamBuilder(
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.hasData) {
              return Container(
                  child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                        margin: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              flex: 1,
                              child: Utils.getImageFromBase64(
                                  snapshot.data.imgBase64),
                            ),
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: Text(
                                  snapshot.data.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: IconButton(
                                icon: Icon(
                                  Icons.star_border,
                                  color: Colors.blue,
                                  size: 20.0,
                                ),
                                onPressed: () => print('pressed'),
                              ),
                            )
                          ],
                        )),
                    Container(
                      margin: EdgeInsets.only(top: 15.0),
                      height: 1.0,
                      width: double.infinity,
                      color: Color(0xFFF3F3F3),
                    ),
                    Container(
                      child: RichText(
                        text: TextSpan(
                          text: snapshot.data.url,
                          style: new TextStyle(
                              color: Colors.blue,
                              fontFamily: 'Poppins-Regular'),
                          recognizer: new TapGestureRecognizer()
                            ..onTap = () {
                              launch(snapshot.data.url);
                            },
                        ),
                      ),
                      margin: const EdgeInsets.only(
                          top: 15.0, left: 8.0, right: 8.0),
                    ),
                    _getAdditionalLinksUI(snapshot),
                    _getTagsWidget(snapshot),
                    Container(
                      margin: EdgeInsets.only(top: 15.0),
                      height: 1.0,
                      width: double.infinity,
                      color: Color(0xFFF3F3F3),
                    ),
                    Container(
                      child: Text('Latest Quotation: ' +
                          snapshot.data.latestDexQuotation),
                      margin: const EdgeInsets.only(
                          top: 15.0, left: 8.0, right: 8.0),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 15.0),
                      height: 1.0,
                      width: double.infinity,
                      color: Color(0xFFF3F3F3),
                    ),
                    Container(
                      child: SingleChildScrollView(
                          child: Html(
                        useRichText: true,
                        data: snapshot.data.description,
                      )),
                      margin: const EdgeInsets.all(8.0),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                            margin: EdgeInsets.only(top: 50.0),
                            child: RaisedButton(
                              onPressed: () {
                                membersBloc.getMembers(
                                    snapshot.data.fundingPanelAddress);
                                Navigator.pushNamed(context, '/startups');
                              },
                              child: const Text(
                                'View Startup',
                                style: TextStyle(color: Colors.white),
                              ),
                            ))
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                            margin: EdgeInsets.only(top: 20.0),
                            child: RaisedButton(
                              elevation: 0,
                              onPressed: () => _showContributeDialog(),
                              child: const Text(
                                'Send SEED',
                                style: TextStyle(color: Colors.white),
                              ),
                            ))
                      ],
                    ),
                  ],
                ),
              ));
            } else {
              return Container();
            }
          },
          stream: basketsBloc.outSingleFundingPanelData,
        ));
  }

  Widget _getAdditionalLinksUI(AsyncSnapshot snapshot) {
    if (snapshot.data.documents == null || snapshot.data.documents.length == 0)
      return Container();

    List<Widget> elements = List();

    for (int i = 0; i < snapshot.data.documents.length; i++) {
      Map document = snapshot.data.documents[i];
      elements.add(Container(
          margin: const EdgeInsets.only(top: 10.0, bottom: 15.0),
          child: RichText(
            text: TextSpan(
              text: document['name'],
              style: new TextStyle(color: Colors.blue),
              recognizer: new TapGestureRecognizer()
                ..onTap = () {
                  launch(document['link']);
                },
            ),
          )));
    }

    return Container(
      margin: const EdgeInsets.only(top: 15.0, left: 8.0, right: 8.0),
      child: Column(
        children: elements,
      ),
    );
  }

  Widget _getTagsWidget(AsyncSnapshot snapshot) {
    if(snapshot.data.tags == null || snapshot.data.tags.length == 0) return Container();
    List<Widget> tags = List();
    for(int i = 0; i < snapshot.data.tags.length; i++) {
      tags.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Container(
                  decoration: new BoxDecoration(
                      color: Color(0xFF006B97),
                      borderRadius: new BorderRadius.only(
                          bottomLeft: const Radius.circular(5.0),
                          bottomRight: const Radius.circular(5.0),
                          topLeft: const Radius.circular(5.0),
                          topRight: const Radius.circular(5.0))),
                  height: 22,
                  margin: const EdgeInsets.only(
                      right: 30.0, bottom: 10.0, top: 15.0, left: 8.0),
                  child: Center(
                    child: Text(
                      snapshot.data.tags[i],
                      style: TextStyle(color: Colors.white),
                    ),
                  )),
            ),
            Spacer(),
            Spacer(),
          ],
        ),
      );
    }
    return Column(
        children: tags,
    );
  }
}
