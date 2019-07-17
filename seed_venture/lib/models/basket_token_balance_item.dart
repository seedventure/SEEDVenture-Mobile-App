import 'package:flutter/material.dart';

class BasketTokenBalanceItem {

  final String name;
  final String balance;
  final String symbol;
  final Image tokenLogo;
  final String imgBase64;
  final bool isWhitelisted;
  final bool isBlacklisted;
  final String fpAddress;
  final List basketTags;


  BasketTokenBalanceItem({this.name, this.balance, this.symbol, this.tokenLogo, this.imgBase64, this.isWhitelisted, this.isBlacklisted, this.fpAddress, this.basketTags});

  Color getWhitelistingColor(){
    if(this.isBlacklisted) return Colors.red;
    Color dotColor = this.isWhitelisted == true ? Colors.green : Colors.yellow;
    return dotColor;
  }
}