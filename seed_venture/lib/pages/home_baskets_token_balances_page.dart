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


  final TextEditingController _filter = new TextEditingController();
  String _searchText = "";
  String filteredTag = ''; // names filtered by search text
  Icon _searchIcon = new Icon(Icons.search);
  Widget _appBarTitle = new Text('Baskets Tokens');

  void _searchPressed() {
    setState(() {
      if (this._searchIcon.icon == Icons.search) {
        this._searchIcon = new Icon(Icons.close);
        this._appBarTitle = new TextField(
          style: TextStyle(color: Colors.white),
          controller: _filter,
          decoration: new InputDecoration(
              hintStyle: TextStyle(
                  color: Colors.white),
              labelStyle: new TextStyle(
                  color: Colors.white),
              border: new UnderlineInputBorder(
                  borderSide: new BorderSide(
                      color: Colors.white)),
              prefixIcon: new Icon(Icons.search),
              hintText: 'Search...'
          ),
        );
      } else {
        this._searchIcon = new Icon(Icons.search);
        this._appBarTitle = new Text('Baskets Tokens');
        filteredTag = '';
        _filter.clear();
      }
    });
  }

  _HomeBasketsTokenBalancesPageState() {
    _filter.addListener(() {
      if (_filter.text.isEmpty) {
        setState(() {
          _searchText = "";
          filteredTag = '';
        });
      } else {
        setState(() {
          _searchText = _filter.text;
          filteredTag = _searchText;
        });
      }
    });
  }

  @override
  void initState() {
    configManagerBloc.configurationPeriodicUpdate();
    configManagerBloc.balancesPeriodicUpdate();

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
          actions: <Widget>[
            InkWell(
              child: Padding(
                child: _searchIcon,
                padding: const EdgeInsets.only(right: 16.0, left: 32.0),
              ),
              onTap: _searchPressed,
            ),

          ],
          title: _appBarTitle,
        ),
        body: new Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    FlatButton(
                      child: Text('Tokens'),
                    ),
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
                  ],
                ),
                StreamBuilder(
                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                    if (snapshot.hasData) {
                      // Snapshot -> List<BasketTokenBalance>

                      return Expanded(
                          child: _getListView(this.filteredTag)
                      );
                    } else {
                      return Container();
                    }
                  },
                  stream: basketsBloc.outBasketTokenBalances,
                )
              ],
            )));
  }


  ListView _getListView(String filteredTag) {
    List data = basketsBloc.getFilteredItems(filteredTag);
    return ListView.builder(
      itemBuilder: (context, position) {
        return Container(
            margin: EdgeInsets.only(bottom: 20.0),
            child: Column(
              children: <Widget>[
                InkWell(
                  onTap: () {
                    basketsBloc.getSingleBasketData(
                        data[position].fpAddress);
                    Navigator.pushNamed(
                        context, '/single_basket');
                  },
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        margin:
                        const EdgeInsets.only(left: 8.0),
                        child:
                       data[position].tokenLogo,
                      ),
                      Container(
                        child: Text(
                            data[position].symbol,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            style: TextStyle(
                              color: Color(0xFF333333),
                              fontSize: 14.0,
                            )),
                        margin: EdgeInsets.only(left: 15.0),
                        width: 60,
                      ),
                      Container(
                        child: Text(
                            data[position].balance,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            style: TextStyle(
                              color: Color(0xFF333333),
                              fontSize: 14.0,
                            )),
                        margin: EdgeInsets.only(left: 32.0),
                      ),
                      Spacer(),
                      Spacer(),
                      /*Container(
                                          // controvalore
                                          child: Text('0.00 EUR'),
                                        ),*/
                      Spacer(),
                      Container(
                        margin:
                        const EdgeInsets.only(right: 8.0),
                        child: ClipOval(
                          child: Container(
                            color: data[position]
                                .getWhitelistingColor(),
                            height: 20.0,
                            width: 20.0,
                          ),
                        ),
                      )
                    ],
                  ),
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
      itemCount: data.length,
    );
  }
}
