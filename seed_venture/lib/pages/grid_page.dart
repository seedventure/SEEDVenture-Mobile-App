import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class GridPage extends StatelessWidget {
  final List<StaggeredTile> _staggeredTiles = const <StaggeredTile>[
    const StaggeredTile.count(2, 2),
    const StaggeredTile.count(2, 2),
    const StaggeredTile.count(2, 2),
    const StaggeredTile.count(2, 2),
    const StaggeredTile.count(2, 2),
  ];

  final List<Widget> _tiles = const <Widget>[
    const _Example01Tile(i: 1,),
    const _Example01Tile(i: 2,),
    const _Example01Tile(i: 3,),
    const _Example01Tile(i: 4,),
    const _Example01Tile(i: 5,),
  ];

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text('Baskets'),
        ),
        body: new Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: new StaggeredGridView.count(
              crossAxisCount: 4,
              staggeredTiles: _staggeredTiles,
              children: _tiles,
              mainAxisSpacing: 4.0,
              crossAxisSpacing: 4.0,
              padding: const EdgeInsets.all(4.0),
            )));
  }
}

class _Example01Tile extends StatelessWidget {
  const _Example01Tile({this.i});

  final Color backgroundColor = Colors.white70;
  final int i;

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
                child: Text('Name: Basket $i'),
                margin: const EdgeInsets.all(10.0),
              ),
              Container(
                child: Text('Incubator: Marco'),
                margin: const EdgeInsets.all(10.0),
              ),
              Container(
                child: Text('Description: blablabla'),
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
