import 'package:flutter/material.dart';
import 'package:seed_venture/blocs/baskets_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:seed_venture/utils/utils.dart';
import 'package:seed_venture/blocs/members_bloc.dart';
import 'package:seed_venture/blocs/contribution_bloc.dart';
import 'package:seed_venture/widgets/progress_bar_overlay.dart';
import 'package:seed_venture/models/funding_panel_item.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:intl/intl.dart';
import 'package:seed_venture/utils/constants.dart';

class SingleBasketPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SingleBasketPageState();
}

class _SingleBasketPageState extends State<SingleBasketPage> {
  final _scaffoldKey = new GlobalKey<ScaffoldState>();
  final formatter = new NumberFormat("#,###.##");

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

  Future _showContributeDialog(FundingPanelItem fundingPanel) async {
    TextEditingController amountControllerSEED = TextEditingController();
    TextEditingController amountControllerBasketToken = TextEditingController();

    double rate = fundingPanel.seedExchangeRateDEX != null
        ? fundingPanel.seedExchangeRateDEX
        : fundingPanel.seedExchangeRate;

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
                            'Remember that you have to be whitelisted to contribute to this basket above to the WL threshold!',
                            textAlign: TextAlign.center,
                          ),
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
                          border: InputBorder.none, hintText: 'SEED...'),
                      controller: amountControllerSEED,
                      onChanged: (value) {
                        if (value.isEmpty)
                          amountControllerBasketToken.text = '';
                        else
                          amountControllerBasketToken.text =
                              (double.parse(value) / rate).toString();
                      },
                    ),
                    height: 50,
                    width: double.infinity,
                    margin: EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0),
                  ),
                  Container(
                    child: TextField(
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Basket Token...'),
                      controller: amountControllerBasketToken,
                      onChanged: (value) {
                        if (value.isEmpty)
                          amountControllerSEED.text = '';
                        else
                          amountControllerSEED.text =
                              (double.parse(value) * rate).toString();
                      },
                    ),
                    height: 50,
                    width: double.infinity,
                    margin:
                        EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
                  ),
                  Container(
                    margin:
                        EdgeInsets.only(right: 20.0, left: 20.0, bottom: 20.0),
                    child: RaisedButton(
                      onPressed: () {
                        Navigator.pop(context);

                        if (contributionBloc.checkWhitelisting(
                            amountControllerSEED.text, fundingPanel)) {
                          if (contributionBloc
                              .hasEnoughFunds(amountControllerSEED.text)) {
                            _showConfigPasswordDialog(
                                amountControllerSEED.text);
                          } else {
                            SnackBar error =
                                SnackBar(content: Text('Insufficient Funds'));
                            _scaffoldKey.currentState.showSnackBar(error);
                          }
                        } else {
                          SnackBar error = SnackBar(
                              content: Text('You are not whitelisted'));
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

    contributionBloc.outTransactionSuccess.listen((txHash) {
      if (txHash != null) {
        Navigator.pop(context);
        SnackBar contributedSnackBar = SnackBar(
            duration: const Duration(seconds: 15),
            content: Text('You have contributed to this basket!'),
            action: SnackBarAction(
              label: 'View Tx',
              onPressed: () {
                launch(EtherscanURL + 'tx/$txHash');
              },
            ));
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
                        color: Colors.white,
                        padding: const EdgeInsets.only(bottom: 15.0, top: 8.0),
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
                                  style: TextStyle(
                                      color: Theme.of(context).primaryColor),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: _getFavoriteIcon(snapshot),
                            )
                          ],
                        )),
                    Container(
                      height: 1.0,
                      width: double.infinity,
                      color: Color(0xFFF3F3F3),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          margin: const EdgeInsets.only(left: 8.0, top: 8.0),
                          child: Text(
                            'Main Info',
                            style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).primaryColor),
                          ),
                        )
                      ],
                    ),
                    Container(
                      child: SingleChildScrollView(
                          child: Html(
                        useRichText: true,
                        data: snapshot.data.description,
                      )),
                      margin: const EdgeInsets.only(
                          left: 8.0, right: 8.0, bottom: 8.0),
                    ),
                    /* Container(
                      margin: EdgeInsets.only(top: 8.0),
                      height: 1.0,
                      width: double.infinity,
                      color: Color(0xFFF3F3F3),
                    ), */
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
                    Container(
                      margin: EdgeInsets.only(top: 8.0),
                      height: 1.0,
                      width: double.infinity,
                      color: Color(0xFFF3F3F3),
                    ),
                    _getTagsHeader(snapshot),
                    _getTagsWidget(snapshot),
                    Container(
                      margin: EdgeInsets.only(top: 8.0),
                      height: 1.0,
                      width: double.infinity,
                      color: Color(0xFFF3F3F3),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          margin: const EdgeInsets.only(left: 8.0, top: 8.0),
                          child: Text(
                            'Economic Info',
                            style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).primaryColor),
                          ),
                        )
                      ],
                    ),
                    Container(
                      child: Text('Exchange Rate: ' +
                          snapshot.data.seedExchangeRate.toStringAsFixed(
                              snapshot.data.seedExchangeRate
                                          .truncateToDouble() ==
                                      snapshot.data.seedExchangeRate
                                  ? 0
                                  : 2) +
                          ' SEED'),
                      margin: const EdgeInsets.only(
                          top: 15.0, left: 8.0, right: 8.0),
                    ),
                    Container(
                      child: Text('Exchange Rate On Top: ' +
                          snapshot.data.exchangeRateOnTop.toStringAsFixed(
                              snapshot.data.exchangeRateOnTop
                                          .truncateToDouble() ==
                                      snapshot.data.exchangeRateOnTop
                                  ? 0
                                  : 2) +
                          ' ' +
                          snapshot.data.tokenSymbol),
                      margin: const EdgeInsets.only(
                          top: 15.0, left: 8.0, right: 8.0),
                    ),
                    Container(
                      child: Text('WL Threshold Balance: ' +
                          snapshot.data.whitelistThreshold.toStringAsFixed(
                              snapshot.data.whitelistThreshold
                                          .truncateToDouble() ==
                                      snapshot.data.whitelistThreshold
                                  ? 0
                                  : 2) +
                          ' ' +
                          snapshot.data.tokenSymbol),
                      margin: const EdgeInsets.only(
                          top: 15.0, left: 8.0, right: 8.0),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 8.0),
                      height: 1.0,
                      width: double.infinity,
                      color: Color(0xFFF3F3F3),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          margin: const EdgeInsets.only(left: 8.0, top: 8.0),
                          child: Text(
                            'Basket Info',
                            style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).primaryColor),
                          ),
                        )
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 8.0, top: 12.0),
                      child: Text('Total Supply: ' +
                          _getSeedMaxSupplyText(snapshot.data.seedMaxSupply) +
                          ' SEED'),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 8.0, top: 12.0),
                      child: Text('Total Raised: ' +
                          formatter.format(
                              double.parse(snapshot.data.seedTotalRaised)) +
                          ' SEED'),
                    ),
                    /*Container(
                      margin: const EdgeInsets.only(left: 8.0, top: 12.0),
                      child: Text('SEED Liquidity: ' +
                          formatter.format(
                              double.parse(snapshot.data.seedLiquidity)) +
                          ' SEED'),
                    ),*/
                    Container(
                      margin: const EdgeInsets.only(left: 8.0, top: 12.0),
                      child: Text('Total SEED Unlocked: ' +
                          formatter.format(double.parse(
                              snapshot.data.totalUnlockedForStartup)) +
                          ' SEED'),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 8.0, top: 12.0),
                      child: Text('Max WL Amount: ' +
                          formatter.format(snapshot.data.WLMaxAmount) +
                          ' ' +
                          snapshot.data.tokenSymbol),
                    ),
                    Container(
                      child: Text('Latest Quotation: ' +
                          _getQuotation(snapshot) +
                          ' SEED'),
                      margin: const EdgeInsets.only(
                          top: 15.0, left: 8.0, right: 8.0),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 15.0),
                      height: 1.0,
                      width: double.infinity,
                      color: Color(0xFFF3F3F3),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                            margin: EdgeInsets.only(top: 20.0),
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
                    _getSendSeedButtonIfNotBlacklisted(snapshot)
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

  Widget _getTagsHeader(AsyncSnapshot snapshot) {
    if (snapshot.data.tags == null || snapshot.data.tags.length == 0)
      return Container();

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Container(
          margin: const EdgeInsets.only(left: 8.0, top: 8.0),
          child: Text(
            'Tags',
            style:
                TextStyle(fontSize: 16, color: Theme.of(context).primaryColor),
          ),
        )
      ],
    );
  }

  Widget _getTagsWidget(AsyncSnapshot snapshot) {
    if (snapshot.data.tags == null || snapshot.data.tags.length == 0)
      return Container();

    List<StaggeredTile> _staggeredTiles = <StaggeredTile>[];

    List<Widget> _tiles = <Widget>[];

    for (int i = 0; i < snapshot.data.tags.length; i++) {
      _staggeredTiles.add(StaggeredTile.count(1, 1));
      _tiles.add(Center(
        child: AutoSizeText(
          snapshot.data.tags[i],
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        ),
      ));
    }

    return StaggeredGridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      staggeredTiles: _staggeredTiles,
      children: _tiles,
      padding: const EdgeInsets.all(4.0),
    );
  }

  IconButton _getFavoriteIcon(AsyncSnapshot snapshot) {
    if (snapshot.data.favorite) {
      return IconButton(
        icon: Icon(
          Icons.star,
          color: Theme.of(context).primaryColor,
          size: 20.0,
        ),
        onPressed: () => basketsBloc.removeFromFavorites(),
      );
    } else {
      return IconButton(
        icon: Icon(
          Icons.star_border,
          color: Theme.of(context).primaryColor,
          size: 20.0,
        ),
        onPressed: () => basketsBloc.setFavorite(),
      );
    }
  }

  Widget _getSendSeedButtonIfNotBlacklisted(AsyncSnapshot snapshot) {
    if (snapshot.data.blacklisted) return Container();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
            margin: EdgeInsets.only(top: 20.0),
            child: RaisedButton(
              elevation: 0,
              onPressed: () => _showContributeDialog(snapshot.data),
              child: const Text(
                'Send SEED',
                style: TextStyle(color: Colors.white),
              ),
            ))
      ],
    );
  }

  String _getSeedMaxSupplyText(String maxSupply) {
    if (!maxSupply.contains('e'))
      return formatter.format(double.parse(maxSupply));
    else {
      String numStr = maxSupply.substring(maxSupply.length - 2);
      int num = int.parse(numStr) - 1;
      String mSupply = '0.';
      for (int i = 0; i < num; i++) {
        mSupply += '0';
      }
      mSupply += '1';
      return mSupply;
    }
  }

  String _getQuotation(AsyncSnapshot snapshot) {
    double rate = snapshot.data.seedExchangeRateDEX != null
        ? snapshot.data.seedExchangeRateDEX
        : snapshot.data.seedExchangeRate;

    int k = 2;
    String s = '0.00';
    while(rate.toStringAsFixed(rate.truncateToDouble() == rate ? 0 : k) == s && k <= 10) {
      s += '0';
      k++;
    }

    return rate.toStringAsFixed(rate.truncateToDouble() == rate ? 0 : k);
  }
}
