import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:seed_venture/blocs/members_bloc.dart';
import 'package:seed_venture/models/member_item.dart';

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
                child: Text('Description: ' + description),
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



  Widget _buildStaggeredGridView(List<MemberItem> members) {
    List<StaggeredTile> _staggeredTiles = <StaggeredTile>[
      /*const StaggeredTile.count(2, 2),
      const StaggeredTile.count(2, 2),
      const StaggeredTile.count(2, 2),
      const StaggeredTile.count(2, 2),
      const StaggeredTile.count(2, 2),*/
    ];

    List<Widget> _tiles = <Widget>[

    ];

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
  void dispose() {
    membersBloc.closeSubjects();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text('Startups'),
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
              stream: membersBloc.outMembers,
            )));
  }
}
