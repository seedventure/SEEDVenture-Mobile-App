import 'package:flutter/material.dart';
import 'package:seed_venture/blocs/baskets_bloc.dart';
import 'package:flutter_html/flutter_html.dart';

class SingleBasketPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SingleBasketPageState();
}

class _SingleBasketPageState extends State<SingleBasketPage> {
  final _scaffoldKey = new GlobalKey<ScaffoldState>();

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
                          child: basketsBloc
                              .getImageFromBase64(snapshot.data.imgBase64),
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
                            //margin: EdgeInsets.only(left: 8.0),
                            //width: 100,
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
                    )
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
}
