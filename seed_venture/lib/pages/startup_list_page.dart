import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:seed_venture/blocs/members_bloc.dart';
import 'package:seed_venture/models/member_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:seed_venture/utils/utils.dart';

class StartupListPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _StartupListPageState();
}

class _StartupListPageState extends State<StartupListPage> {
  Widget _buildStaggeredGridView(List<MemberItem> members) {
    List<StaggeredTile> _staggeredTiles = <StaggeredTile>[];

    List<Widget> _tiles = <Widget>[];

    for (int i = 0; i < members.length; i++) {
      _staggeredTiles.add(StaggeredTile.count(2, 3));
      _tiles.add(_StartupTile(
        name: members[i].name,
        description: members[i].description,
        url: members[i].url,
        imgBase64: members[i].imgBase64,
        memberAddress: members[i].memberAddress,
        fpAddress: members[i].fundingPanelAddress,
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
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text('Startup List'),
        ),
        body: new Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: StreamBuilder(
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.hasData) {
                  if (snapshot.data.length > 0) {
                    return _buildStaggeredGridView(snapshot.data);
                  } else {
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

class _StartupTile extends StatelessWidget {
  const _StartupTile(
      {this.name,
      this.description,
      this.url,
      this.imgBase64,
      this.fpAddress,
      this.memberAddress});

  final Color backgroundColor = Colors.white;

  final String name;
  final String description;
  final String url;
  final String imgBase64;
  final String memberAddress;
  final String fpAddress;

  @override
  Widget build(BuildContext context) {
    return new Card(
      color: backgroundColor,
      child: new InkWell(
        onTap: () {
          membersBloc.getSingleMemberData(fpAddress, memberAddress);
          Navigator.pushNamed(context, '/single_startup');
        },
        child: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                  flex: 1,
                  child: Container(
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: Utils.getImageFromBase64(imgBase64),
                        ),
                        Expanded(
                          flex: 2,
                          child: Container(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                            ),
                            margin: EdgeInsets.only(left: 8.0),
                          ),
                        ),
                      ],
                    ),
                    margin:
                        const EdgeInsets.only(left: 8.0, bottom: 8.0, top: 8.0),
                  )),
              Expanded(
                  flex: 2,
                  child: Container(
                    child: SingleChildScrollView(
                        child: Html(
                      useRichText: true,
                      data: description,
                    )),
                    margin: const EdgeInsets.all(8.0),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
