import 'package:flutter/material.dart';
import 'package:seed_venture/blocs/baskets_bloc.dart';
import 'package:seed_venture/blocs/config_manager_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:intl/intl.dart';

class HomeBasketsTokenBalancesPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomeBasketsTokenBalancesPageState();
}

class _HomeBasketsTokenBalancesPageState
    extends State<HomeBasketsTokenBalancesPage> {
  final TextEditingController _filter = new TextEditingController();
  String _searchText = "";
  String filterText = '';
  Icon _searchIcon = new Icon(Icons.search);
  Widget _appBarTitle = new Text('Baskets Tokens');

  final formatter = new NumberFormat("#,###.##");

  void _searchPressed() {
    setState(() {
      if (this._searchIcon.icon == Icons.search) {
        this._searchIcon = new Icon(Icons.close);
        this._appBarTitle = new TextField(
          style: TextStyle(color: Colors.white),
          controller: _filter,
          decoration: new InputDecoration(
              hintStyle: TextStyle(color: Colors.white),
              labelStyle: new TextStyle(color: Colors.white),
              border: new UnderlineInputBorder(
                  borderSide: new BorderSide(color: Colors.white)),
              prefixIcon: new Icon(Icons.search),
              hintText: 'Search...'),
        );
      } else {
        this._searchIcon = new Icon(Icons.search);
        this._appBarTitle = new Text('Baskets Tokens');
        filterText = '';
        _filter.clear();
      }
    });
  }

  _HomeBasketsTokenBalancesPageState() {
    _filter.addListener(() {
      if (_filter.text.isEmpty) {
        setState(() {
          _searchText = "";
          filterText = '';
        });
      } else {
        setState(() {
          _searchText = _filter.text;
          filterText = _searchText;
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
        backgroundColor: Colors.white,
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                child: Column(
                  children: <Widget>[
                    Container(
                        margin: const EdgeInsets.only(top: 10.0),
                        child: Image.asset(
                          'assets/seed-logo.png',
                          height: 100,
                          width: 100,
                        ))
                  ],
                ),
                decoration: BoxDecoration(
                  color: Color(0xFF6fd2fb),
                ),
              ),
              ListTile(
                title: Text('My Wallet'),
                onTap: () {
                  basketsBloc.getFavoritesBasketsTokenBalances();
                  Navigator.pushNamed(context, '/my_wallet');
                },
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
        /*body: new Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: StreamBuilder(
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.hasData) {
                  // Snapshot -> List<BasketTokenBalance>

                  return _getUI(this.filterText);
                } else {
                  return Container();
                }
              },
              stream: basketsBloc.outBasketTokenBalances,
            )
        )*/
        body: StreamBuilder(
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.hasData) {
              // Snapshot -> List<BasketTokenBalance>

              return _getUI(this.filterText);
            } else {
              return Container();
            }
          },
          stream: basketsBloc.outBasketTokenBalances,
        )
    );
  }

  Widget _getUI(String filteredText) {
    List data = basketsBloc.getFilteredItems(filteredText);
    if (data.length != 0) {
      return Column(
        children: <Widget>[

          Container(
            color: Theme.of(context).accentColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Spacer(),
                Spacer(),
                StreamBuilder(
                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                    if (snapshot.hasData) {
                      return Container(
                        child: Row(
                          children: <Widget>[
                            Container(
                              child: Text(_getFormattedQuantity(
                                      double.parse(snapshot.data[0])) +
                                  ' SEED', style: TextStyle(color: Colors.white, fontSize: 15.0),),
                              margin: const EdgeInsets.only(right: 8.0),
                            ),
                            Container(
                              child: Text(_getFormattedQuantity(
                                      double.parse(snapshot.data[1])) +
                                  ' ETH', style: TextStyle(color: Colors.white, fontSize: 15.0)),
                            ),
                          ],
                        ),
                        margin:
                            const EdgeInsets.only(right: 15.0, bottom: 15.0, top: 12.0),
                      );
                    } else {
                      return Container();
                    }
                  },
                  stream: basketsBloc.outSeedEthBalance,
                ),
              ],
            ),
          ),
          Container(
              margin: const EdgeInsets.only(bottom: 8.0, top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                      flex: 2,
                      child: Container(
                        child: AutoSizeText(
                          'TOKEN',
                          style: TextStyle(color: Color(0xFFAEAEAE)),
                          maxLines: 1,
                        ),
                        margin: EdgeInsets.only(left: 8.0),
                      )),
                  Spacer(),
                  Expanded(
                    flex: 3,
                    child: Container(
                      child: AutoSizeText(
                        'QUANTITY',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFFAEAEAE)),
                        maxLines: 1,
                      ),
                    ),
                  ),
                  Expanded(
                      flex: 3,
                      child: Container(
                          child: AutoSizeText(
                        'VALUE (SEED)',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFFAEAEAE)),
                        maxLines: 1,
                      ))),
                  Spacer(),
                  Expanded(
                    flex: 1,
                    child: Container(
                        margin: EdgeInsets.only(right: 8.0),
                        child: AutoSizeText(
                          'WL',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFFAEAEAE)),
                          maxLines: 1,
                        )),
                  ),
                ],
              )),
          Expanded(
              child: ListView.builder(
            itemBuilder: (context, position) {
              return Container(
                  color: _getRowColorByIndex(position),
                  padding: EdgeInsets.only(bottom: 20.0, top: 20.0),
                  child: Column(
                    children: <Widget>[
                      InkWell(
                          onTap: () {
                            basketsBloc
                                .getSingleBasketData(data[position].fpAddress);
                            Navigator.pushNamed(context, '/single_basket');
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[
                                  Container(
                                    margin: const EdgeInsets.only(left: 8.0),
                                    child: data[position].tokenLogo,
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      child: AutoSizeText(
                                        data[position].symbol,
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: false,
                                        style: _getTextStyle(
                                            data[position].isHighlighted),
                                        maxLines: 1,
                                      ),
                                      margin: EdgeInsets.only(left: 8.0),
                                    ),
                                  ),
                                  Spacer(),
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                      child: AutoSizeText(
                                        _getFormattedQuantity(double.parse(
                                            data[position].balance)),
                                        textAlign: TextAlign.center,
                                        style: _getTextStyle(
                                            data[position].isHighlighted),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: false,
                                      ),
                                    ),
                                  ),
                                  Spacer(),
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                      child: AutoSizeText(
                                        _getFormattedQuantity(double.parse(
                                                data[position].balance) *
                                            data[position].quotation),
                                        textAlign: TextAlign.center,
                                        style: _getTextStyle(
                                            data[position].isHighlighted),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: false,
                                      ),
                                    ),
                                  ),
                                  Spacer(),
                                  Spacer(),
                                  Container(
                                      margin:
                                          const EdgeInsets.only(right: 10.0),
                                      child: ClipOval(
                                        child: Container(
                                          color: data[position]
                                              .getWhitelistingColor(),
                                          height: 20.0,
                                          width: 20.0,
                                        ),
                                      )),
                                ],
                              ),
                              Container(
                                margin:
                                    const EdgeInsets.only(left: 8.0, top: 8.0),
                                child: Text('Total Raised: ' +
                                    _getFormattedQuantity(double.parse(data[position].seedTotalRaised)) +
                                    ' SEED'),
                              )
                            ],
                          )),
                    ],
                  ));
            },
            itemCount: data.length,
          ))
        ],
      );
    } else if (filteredText == '') {
      return Center(
        child: Text('No basket found'),
      );
    } else {
      return Center(
        child: Text('No basket matches your search'),
      );
    }
  }

  Color _getRowColorByIndex(int index) {
    if (index % 2 == 0) return Colors.white;
    return Color(0xFFf2f2f2);
  }

  String _getFormattedQuantity(double quantity) {
    if (quantity == 0) return '0.00';

    return formatter.format(quantity);
  }

  TextStyle _getTextStyle(bool isHighlighted) {
    TextStyle style = isHighlighted
        ? TextStyle(color: Color(0xFF333333), fontWeight: FontWeight.bold)
        : TextStyle(color: Color(0xFF333333));
    return style;
  }
}
