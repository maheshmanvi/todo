import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class MyUtils {

  static bool isTitleEmpty(String title) {
    return title.trim().isEmpty;
  }

  static bool isTitleInvalid(String title) {
    if (title.isEmpty) return false;
    return !RegExp(r'^[A-Za-z]').hasMatch(title);
  }

  // Shows a toast message
  static void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: Colors.grey[800],
      // backgroundColor: Color(0xFFC80036),
    );
  }

  String formatTime(String timeStr) {
    try {
      final timeParts = timeStr.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final period = hour >= 12 ? 'PM' : 'AM';

      final formattedHour = hour > 12 ? hour - 12 : hour == 0 ? 12 : hour;
      return '${formattedHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      log('ERROR MyUtils.formatTime: $e');
      return 'Invalid Time';
    }
  }
}
