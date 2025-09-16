import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AppToast {
  static void show(String message, {
    ToastGravity gravity = ToastGravity.BOTTOM,
    Color? backgroundColor,
    Color? textColor,
    double fontSize = 16.0,
    int timeInSecForIosWeb = 2,
  }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: gravity,
      backgroundColor: backgroundColor ?? Colors.black87,
      textColor: textColor ?? Colors.white,
      fontSize: fontSize,
      timeInSecForIosWeb: timeInSecForIosWeb,
    );
  }

  static void showSuccess(String message) {
    show(
      message,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }

  static void showError(String message) {
    show(
      message,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  static void showWarning(String message) {
    show(
      message,
      backgroundColor: Colors.orange,
      textColor: Colors.white,
    );
  }

  static void showInfo(String message) {
    show(
      message,
      backgroundColor: Colors.blue,
      textColor: Colors.white,
    );
  }
}
