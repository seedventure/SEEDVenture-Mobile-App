import 'package:flutter/material.dart';

class BasketTokenBalanceItem {

  final String balance;
  final String symbol;
  final Image tokenLogo;
  final String imgBase64;
  final bool isWhitelisted;
  final String fpAddress;


  BasketTokenBalanceItem({this.balance, this.symbol, this.tokenLogo, this.imgBase64, this.isWhitelisted, this.fpAddress});

  Color getWhitelistingColor(){
    Color dotColor = this.isWhitelisted == true ? Colors.green : Colors.red;
    return dotColor;
  }
}