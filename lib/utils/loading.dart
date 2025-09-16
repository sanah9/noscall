import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class AppLoading {
  static void show([String? status]) {
    EasyLoading.show(status: status);
  }

  static void showProgress(double progress, [String? status]) {
    EasyLoading.showProgress(progress, status: status);
  }

  static void showSuccess([String? status]) {
    EasyLoading.showSuccess(status ?? 'Success!');
  }

  static void showError([String? status]) {
    EasyLoading.showError(status ?? 'Error!');
  }

  static void showInfo([String? status]) {
    EasyLoading.showInfo(status ?? 'Info');
  }

  static void showWarning([String? status]) {
    EasyLoading.showInfo(status ?? 'Warning');
  }

  static void dismiss() {
    EasyLoading.dismiss();
  }

  static bool get isShow => EasyLoading.isShow;

  static void configLoading() {
    EasyLoading.instance
      ..displayDuration = const Duration(milliseconds: 2000)
      ..indicatorType = EasyLoadingIndicatorType.fadingCircle
      ..loadingStyle = EasyLoadingStyle.dark
      ..maskType = EasyLoadingMaskType.black
      ..dismissOnTap = false
      ..userInteractions = true;
  }

  static void customConfig({
    Duration? displayDuration,
    EasyLoadingIndicatorType? indicatorType,
    EasyLoadingStyle? loadingStyle,
    EasyLoadingMaskType? maskType,
    bool? dismissOnTap,
    bool? userInteractions,
    Color? backgroundColor,
    Color? indicatorColor,
    Color? textColor,
    double? fontSize,
    double? radius,
  }) {
    EasyLoading.instance
      ..displayDuration = displayDuration ?? const Duration(milliseconds: 2000)
      ..indicatorType = indicatorType ?? EasyLoadingIndicatorType.fadingCircle
      ..loadingStyle = loadingStyle ?? EasyLoadingStyle.dark
      ..maskType = maskType ?? EasyLoadingMaskType.black
      ..dismissOnTap = dismissOnTap ?? false
      ..userInteractions = userInteractions ?? true
      ..backgroundColor = backgroundColor
      ..indicatorColor = indicatorColor
      ..textColor = textColor
      ..fontSize = fontSize ?? 18.0
      ..radius = radius ?? 10.0;
  }
}
