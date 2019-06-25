import 'package:flutter/material.dart';

class ProgressBarOverlay extends ModalRoute<void> {
  String title;

  static const int generatingConfig = 0;
  static const int sendingTransaction = 1;

  int _mode;


  @override
  Duration get transitionDuration => Duration(milliseconds: 200);

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => false;

  @override
  Color get barrierColor => Colors.black.withOpacity(0.5);

  @override
  String get barrierLabel => null;

  @override
  bool get maintainState => true;

  ProgressBarOverlay(this._mode);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    // This makes sure that text and other content follows the material style
    return Material(
      type: MaterialType.transparency,
      // make sure that the overlay content is not cut off
      child: SafeArea(
        child: _buildOverlayContent(context),
      ),
    );
  }

  Widget _buildOverlayContent(BuildContext context) {
    return Align(
        alignment: Alignment.center, child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        CircularProgressIndicator(),
        Container(
          child: Text(getTextByMode(_mode), style: TextStyle(color: Theme.of(context).accentColor, fontWeight: FontWeight.bold),),
          margin: const EdgeInsets.only(top: 10.0),
        )
      ],
    ));
  }

  String getTextByMode(int mode){
    switch(mode){
      case ProgressBarOverlay.generatingConfig:
        return 'Generating Keys and Config file...';
        break;
      case ProgressBarOverlay.sendingTransaction:
        return 'Sending Transaction...';
        break;
    }
  }
}
