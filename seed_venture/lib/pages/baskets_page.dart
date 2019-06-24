import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:seed_venture/blocs/baskets_bloc.dart';
import 'package:seed_venture/models/funding_panel_details.dart';
import 'package:seed_venture/pages/members_page.dart';
import 'package:seed_venture/blocs/members_bloc.dart';
import 'package:seed_venture/blocs/config_manager_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/cupertino.dart';

class BasketsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _BasketsPageState();
}

class _BasketsPageState extends State<BasketsPage> {

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  Widget _buildStaggeredGridView(
      List<FundingPanelDetails> fundingPanelDetails) {
    List<StaggeredTile> _staggeredTiles = <StaggeredTile>[
      /*const StaggeredTile.count(2, 2),
      const StaggeredTile.count(2, 2),
      const StaggeredTile.count(2, 2),
      const StaggeredTile.count(2, 2),
      const StaggeredTile.count(2, 2),*/
    ];

    List<Widget> _tiles = <Widget>[
      /*const _Example01Tile(i: 1,),
      const _Example01Tile(i: 2,),
      const _Example01Tile(i: 3,),
      const _Example01Tile(i: 4,),
      const _Example01Tile(i: 5,),*/
    ];

    for (int i = 0; i < fundingPanelDetails.length; i++) {
      _staggeredTiles.add(StaggeredTile.count(2, 3));
      _tiles.add(_Example01Tile(
        name: fundingPanelDetails[i].name,
        description: fundingPanelDetails[i].description,
        url: fundingPanelDetails[i].url,
        imgBase64: fundingPanelDetails[i].imgBase64,
        fpAddress: fundingPanelDetails[i].address,
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
        appBar: new AppBar(
          title: new Text('Baskets'),
        ),
        body: new Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: StreamBuilder(
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.hasData) {
                  return _buildStaggeredGridView(snapshot.data);
                } else {
                  return CircularProgressIndicator();
                }
              },
              stream: basketsBloc.outFundingPanelsDetails,
            )


        ));
  }
}

class _Example01Tile extends StatelessWidget {
  const _Example01Tile({this.name, this.description, this.url, this.imgBase64, this.fpAddress});

  final Color backgroundColor = Colors.greenAccent;

  final String name;
  final String description;
  final String url;
  final String imgBase64;
  final String fpAddress;

  @override
  Widget build(BuildContext context) {
    return new Card(
      color: backgroundColor,
      child: new InkWell(
        onTap: () {
          membersBloc.getMembers(fpAddress);
          Navigator.pushNamed(context, '/startups');
        },
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
                child: Text('Incubator: ' + name),
                margin: const EdgeInsets.all(10.0),
              )),
              Expanded(
                  child: Container(
                child: Text('Description: ' + description),
                margin: const EdgeInsets.all(10.0),
              )),
              Expanded(
                  child: Container(
                child: Text('Latest Quotation: 0.001 SEED'),
                margin: const EdgeInsets.all(10.0),
              ))
            ],
          ),
        ),
      ),
    );
  }
}
