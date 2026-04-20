// lib/app.dart
import 'package:flutter/material.dart';
import 'page/home.dart';
import 'page/bluetooth_connect_page.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isConnected = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DTU 配置助手',
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
        scaffoldBackgroundColor: const Color(0xFFF0F7FF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90D9),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF0F7FF),
          foregroundColor: Color(0xFF2D4A6F),
          elevation: 0,
        ),
      ),
      home: _isConnected
          ? const HomePage()
          : BluetoothConnectPage(
              onConnected: () {
                setState(() {
                  _isConnected = true;
                });
              },
            ),
      debugShowCheckedModeBanner: false,
    );
  }
}
