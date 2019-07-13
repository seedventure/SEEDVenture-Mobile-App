import 'dart:convert';
import 'package:flutter/material.dart';

class Utils {
  static Image getImageFromBase64(String base64) {
    if (base64 != '') {
      return Image.memory(base64Decode(base64), width: 35.0, height: 35.0);
    } else {
      return Image.asset(
        'assets/watermelon.png',
        height: 35.0,
        width: 35.0,
      );
    }
  }
}