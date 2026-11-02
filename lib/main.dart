// lib/main.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
// 引入 Android 平台实现以注册 WebViewPlatform
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'app.dart';

void main() {
  // webview_flutter 4.10+ 必须在使用前显式注册 Android 平台实现
  WebViewPlatform.instance = AndroidWebViewPlatform();
  runApp(const MyApp());
}
