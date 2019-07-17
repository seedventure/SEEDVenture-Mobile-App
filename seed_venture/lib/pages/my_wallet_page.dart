import 'package:flutter/material.dart';
import 'package:seed_venture/blocs/baskets_bloc.dart';
import 'package:auto_size_text/auto_size_text.dart';

class MyWalletPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MyWalletPageState();
}

class _MyWalletPageState extends State<MyWalletPage> {
  final _scaffoldKey = new GlobalKey<ScaffoldState>();

  final TextEditingController _filter = new TextEditingController();
  String _searchText = "";
  String filterText = ''; // names filtered by search text
  Icon _searchIcon = new Icon(Icons.search);
  Widget _appBarTitle = new Text('My Wallet');

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
        this._appBarTitle = new Text('My Wallet');
        filterText = '';
        _filter.clear();
      }
    });
  }

  _MyWalletPageState() {
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
  Widget build(BuildContext context) {
    return new Scaffold(
        key: _scaffoldKey,
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
        body: StreamBuilder(
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.hasData) {
              // Snapshot -> List<BasketTokenBalance>
              return _getUIFavorites(this.filterText);
            } else {
              return Container();
            }
          },
          stream: basketsBloc.outFavoritesBasketsTokenBalances,
        ));
  }

  Widget _getUIFavorites(String filteredText) {
    List data = basketsBloc.getFilteredItemsFavorites(filteredText);
    if (data.length != 0) {
      return Column(
        children: <Widget>[
          Container(
              margin: const EdgeInsets.only(bottom: 8.0, top: 12.0),
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
                        //height: 16.0,
                      )),
                  Spacer(),
                  Expanded(
                    flex: 3,
                    child: Container(
                      child: AutoSizeText(
                        'QUANTITY',
                        style: TextStyle(color: Color(0xFFAEAEAE)),
                        maxLines: 1,
                      ),
                      margin: EdgeInsets.only(left: 8.0),
                      //height: 16.0,
                    ),
                  ),
                  Spacer(),
                  Expanded(
                      flex: 2,
                      child: Container(
                          //margin: EdgeInsets.only(right: 8.0),
                          child: AutoSizeText(
                        'VALUE',
                        style: TextStyle(color: Color(0xFFAEAEAE)),
                        maxLines: 1,
                      ))),
                  Spacer(),
                  Expanded(
                    flex: 1,
                    child: Container(
                        //margin: EdgeInsets.only(left: 8.0),
                        child: AutoSizeText(
                      'WL',
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
                  margin: EdgeInsets.only(bottom: 20.0),
                  child: Column(
                    children: <Widget>[
                      InkWell(
                        onTap: () {
                          basketsBloc
                              .getSingleBasketData(data[position].fpAddress);
                          Navigator.pushNamed(context, '/single_basket');
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              margin: const EdgeInsets.only(left: 8.0),
                              child: data[position].tokenLogo,
                            ),
                            Expanded(
                              child: Container(
                                child: AutoSizeText(
                                  data[position].symbol,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                  style: TextStyle(color: Color(0xFF333333)),
                                  maxLines: 1,
                                ),
                                margin: EdgeInsets.only(left: 8.0),
                              ),
                            ),
                            Spacer(),
                            Expanded(
                              child: Container(
                                child: Text(data[position].balance,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                    style: TextStyle(
                                      color: Color(0xFF333333),
                                      fontSize: 14.0,
                                    )),
                              ),
                            ),
                            Spacer(),
                            Expanded(
                              flex: 2,
                              child: Container(
                                child: AutoSizeText(
                                  '0.00 SEED',
                                  style: TextStyle(color: Color(0xFF333333)),
                                  maxLines: 1,
                                ),
                              ),
                            ),
                            Spacer(),
                            Container(
                                margin:
                                    const EdgeInsets.only(right: 10.0), // 8.0
                                child: ClipOval(
                                  child: Container(
                                    color:
                                        data[position].getWhitelistingColor(),
                                    height: 20.0,
                                    width: 20.0,
                                  ),
                                )),
                          ],
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(left: 50.0, top: 15.0),
                        height: 1.0,
                        width: double.infinity,
                        color: Color(0xFFF3F3F3),
                      ),
                    ],
                  ));
            },
            itemCount: data.length,
          ))
        ],
      );
    } else if (filteredText == '') {
      return Center(
        child: Text('You don\'t have any favorite basket'),
      );
    } else
      return Center(
        child: Text('No basket matches your search'),
      );
  }
}
