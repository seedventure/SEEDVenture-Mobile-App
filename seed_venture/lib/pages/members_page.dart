import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:seed_venture/blocs/members_bloc.dart';
import 'package:seed_venture/models/member_item.dart';
import 'package:seed_venture/blocs/contribution_bloc.dart';
import 'package:seed_venture/widgets/progress_bar_overlay.dart';
import 'package:flutter_html/flutter_html.dart';

class MembersPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MemberPageState();
}

class _Example01Tile extends StatelessWidget {
  const _Example01Tile({this.name, this.description, this.url, this.imgBase64});

  final Color backgroundColor = Colors.redAccent;

  final String name;
  final String description;
  final String url;
  final String imgBase64;

  @override
  Widget build(BuildContext context) {
    return new Card(
      color: backgroundColor,
      child: new InkWell(
        onTap: () {},
        child: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                  child: Container(
                child: Text('Name: ' + name),
                margin: const EdgeInsets.all(10.0),
              )),
              Expanded(
                  child: Container(
                child: Html(
                  data: description,
                ),
                margin: const EdgeInsets.all(10.0),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberPageState extends State<MembersPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  Widget _buildStaggeredGridView(List<MemberItem> members) {
    List<StaggeredTile> _staggeredTiles = <StaggeredTile>[];

    List<Widget> _tiles = <Widget>[];

    for (int i = 0; i < members.length; i++) {
      _staggeredTiles.add(StaggeredTile.count(2, 3));
      _tiles.add(_Example01Tile(
         name: members[i].name,
        description: members[i].description,
        url: members[i].url,
        imgBase64: members[i].imgBase64,
      ));
    }

    return StaggeredGridView.count(
      crossAxisCount: 4,
      staggeredTiles: _staggeredTiles,
      children: _tiles,
      mainAxisSpacing: 4.0,
      crossAxisSpacing: 4.0,
      padding: const EdgeInsets.all(4.0),
    );
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
        SnackBar contributedSnackBar =
            SnackBar(content: Text('You have contributed to this project! Your balance is being updated...'));
        _scaffoldKey.currentState.showSnackBar(contributedSnackBar);
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    membersBloc.closeSubjects();
    super.dispose();
  }

  Future showConfigPasswordDialog(String seedAmount) async {
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
                            membersBloc.getFundingPanelAddress());
                      },
                      child: const Text(
                        'Contribute to Basket',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.0,
                            fontFamily: 'SF-Pro-Bold'),
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

  Future showContributeDialog() async {
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
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
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

                        if(contributionBloc.hasEnoughFunds(amountController.text)){
                          showConfigPasswordDialog(amountController.text);
                        }
                        else {
                          SnackBar error = SnackBar(
                              content: Text(
                                  'Insufficient Funds'));
                          _scaffoldKey.currentState.showSnackBar(error);
                        }

                      },
                      child: const Text(
                        'Next',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.0,
                            fontFamily: 'SF-Pro-Bold'),
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
  Widget build(BuildContext context) {
    return new Scaffold(
        key: _scaffoldKey,
        appBar: new AppBar(
          title: new Text('Startups'),
          actions: <Widget>[
            InkWell(
              child: Padding(
                child: Icon(Icons.send),
                padding: const EdgeInsets.only(right: 16.0, left: 32.0),
              ),
              onTap: () => showContributeDialog(),
            ),

          ],
        ),
        body: new Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: StreamBuilder(
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.hasData) {
                  if(snapshot.data.length > 0){
                    return _buildStaggeredGridView(snapshot.data);
                  }
                  else{
                    return Center(
                      child: Text('This baskets does not have any startup'),
                    );
                  }
                } else {
                  return CircularProgressIndicator();
                }
              },
              stream: membersBloc.outMembers,
            )));
  }
}
