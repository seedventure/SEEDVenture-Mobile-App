import 'package:flutter/material.dart';
import 'package:seed_venture/blocs/baskets_bloc.dart';
import 'package:seed_venture/blocs/config_manager_bloc.dart';
import 'package:flutter/cupertino.dart';

class HomeBasketsTokenBalancesPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomeBasketsTokenBalancesPageState();
}

class _HomeBasketsTokenBalancesPageState
    extends State<HomeBasketsTokenBalancesPage> {
  @override
  void initState() {
    configManagerBloc.periodicUpdate();

    basketsBloc.outNotificationsiOS.listen((notificationData) async {
      String title = notificationData[0];
      String body = notificationData[1];

      await showDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text('Ok'),
              onPressed: () async {
                Navigator.of(context, rootNavigator: true).pop();
              },
            )
          ],
        ),
      );
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                child: Column(
                  children: <Widget>[
                    Text('SeedVenture'),
                    /*StreamBuilder(
                      builder: (BuildContext context, AsyncSnapshot snapshot) {
                        if (snapshot.hasData) {
                          return Container(
                            child: Text('Balance: ' + snapshot.data + ' SEED'),
                            margin: const EdgeInsets.all(12.0),
                          );
                        } else {
                          return Container();
                        }
                      },
                      stream: basketsBloc.outSeedBalance,
                    )*/
                  ],
                ),
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
              ),
              ListTile(
                title: Text('Settings'),
                onTap: () {
                  Navigator.pushNamed(context, '/settings');
                },
              ),
              ListTile(
                title: Text('Wallet Info'),
                onTap: () {
                  Navigator.pushNamed(context, '/wallet_info');
                },
              ),
            ],
          ),
        ),
        appBar: new AppBar(
          title: new Text('Baskets Token Balances'),
        ),
        body: new Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    FlatButton(
                        child: Text('Baskets'),
                        onPressed: () =>
                            Navigator.pushNamed(context, '/baskets')),
                    Spacer(),
                    StreamBuilder(
                      builder: (BuildContext context, AsyncSnapshot snapshot) {
                        if (snapshot.hasData) {
                          return Container(
                            child: Row(
                              children: <Widget>[
                                Container(
                                  child: Text(snapshot.data[0] + ' SEED'),
                                  margin: const EdgeInsets.only(right: 8.0),
                                ),
                                Container(
                                  child: Text(snapshot.data[1] + ' ETH'),
                                ),
                              ],
                            ),
                            margin: const EdgeInsets.all(15.0),
                          );
                        } else {
                          return Container();
                        }
                      },
                      stream: basketsBloc.outSeedEthBalance,
                    ),
                    /*StreamBuilder(
                      builder: (BuildContext context, AsyncSnapshot snapshot) {
                        if (snapshot.hasData) {
                          return Container(
                            child: Text(snapshot.data + ' SEED'),
                            margin: const EdgeInsets.all(15.0),
                          );
                        } else {
                          return Container();
                        }
                      },
                      stream: basketsBloc.outSeedBalance,
                    ),*/
                  ],
                ),
                StreamBuilder(
                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                    if (snapshot.hasData) {
                      // Snapshot = List<BasketTokenBalance>

                      return Expanded(
                          child: ListView.builder(
                        itemBuilder: (context, position) {
                          return Container(
                              margin: EdgeInsets.only(bottom: 20.0),
                              child: Column(
                                children: <Widget>[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      Container(
                                        margin:
                                            const EdgeInsets.only(left: 8.0),
                                        child:
                                            snapshot.data[position].tokenLogo,
                                      ),
                                      Container(
                                        child: Text(
                                            snapshot.data[position].symbol,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: false,
                                            style: TextStyle(
                                                color: Color(0xFF333333),
                                                fontSize: 14.0,
                                                fontFamily: 'SF-Pro-Bold')),
                                        margin: EdgeInsets.only(left: 15.0),
                                        width: 60,
                                      ),
                                      Container(
                                        child: Text(
                                            snapshot.data[position].balance,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: false,
                                            style: TextStyle(
                                                color: Color(0xFF333333),
                                                fontSize: 14.0,
                                                fontFamily: 'SF-Pro-Regular')),
                                        margin: EdgeInsets.only(left: 32.0),
                                      ),
                                      Spacer(),
                                      Container(
                                        // controvalore
                                        child: Text('0.00 EUR'),
                                      ),
                                      Spacer(),
                                      Container(
                                        margin:
                                            const EdgeInsets.only(right: 8.0),
                                        child: ClipOval(
                                          child: Container(
                                            color: snapshot.data[position].getWhitelistingColor(),
                                            height: 20.0,
                                            width: 20.0,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                  Container(
                                    margin:
                                        EdgeInsets.only(left: 50.0, top: 15.0),
                                    height: 1.0,
                                    width: double.infinity,
                                    color: Color(0xFFF3F3F3),
                                  ),
                                ],
                              ));
                        },
                        itemCount: snapshot.data.length,
                      ));
                    } else {
                      //return CircularProgressIndicator();
                      return Container();
                    }
                  },
                  stream: basketsBloc.outBasketTokenBalances,
                )
              ],
            )));
  }

}
