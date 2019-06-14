import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:seed_venture/blocs/baskets_bloc.dart';
import 'package:seed_venture/models/funding_panel_details.dart';

class BasketsPage extends StatelessWidget {
  Widget _buildStaggeredGridView(List<FundingPanelDetails> fundingPanelDetails) {
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
      _staggeredTiles.add(StaggeredTile.count(2, 2));
      _tiles.add(_Example01Tile(
        name: fundingPanelDetails[i].name,
        description: fundingPanelDetails[i].description,
        url: fundingPanelDetails[i].url,
        imgBase64: fundingPanelDetails[i].imgBase64,
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

            /* new StaggeredGridView.count(
              crossAxisCount: 4,
              staggeredTiles: _staggeredTiles,
              children: _tiles,
              mainAxisSpacing: 4.0,
              crossAxisSpacing: 4.0,
              padding: const EdgeInsets.all(4.0),
            )*/
            ));
  }
}

class _Example01Tile extends StatelessWidget {
  const _Example01Tile({this.name, this.description, this.url, this.imgBase64});

  final Color backgroundColor = Colors.white70;

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
              Container(
                child: Text('Name: ' + name),
                margin: const EdgeInsets.all(10.0),
              ),
              Container(
                child: Text('Incubator: ' + name),
                margin: const EdgeInsets.all(10.0),
              ),
              Container(
                child: Text('Description: ' + description),
                margin: const EdgeInsets.all(10.0),
              ),
              Container(
                child: Text('Latest Quotation: 0.001 SEED'),
                margin: const EdgeInsets.all(10.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
