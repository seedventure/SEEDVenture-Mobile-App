import 'package:flutter/material.dart';
import 'package:seed_venture/blocs/members_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:seed_venture/utils/utils.dart';

class SingleStartupPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SingleStartupPageState();
}

class _SingleStartupPageState extends State<SingleStartupPage> {
  final _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        key: _scaffoldKey,
        appBar: new AppBar(
          title: new Text('Startup'),
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
                            Spacer()
                            /*Expanded(
                              flex: 1,
                              child: IconButton(
                                icon: Icon(
                                  Icons.star_border,
                                  color: Colors.blue,
                                  size: 20.0,
                                ),
                                onPressed: () => print('pressed'),
                              ),
                            )*/
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
                  ],
                ),
              ));
            } else {
              return Container();
            }
          },
          stream: membersBloc.outSingleMemberData,
        ));
  }
}
