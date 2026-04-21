// lib/app.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'page/home.dart';
import 'page/bluetooth_connect_page.dart';

// TODO [DEV ONLY]: 上线时删除此变量
const bool kDevMode = true;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isConnected = false;
  BluetoothDevice? _connectedDevice;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }

  void _onDeviceConnected(BluetoothDevice device) {
    _connectedDevice = device;
    _listenConnectionState(device);
    setState(() {
      _isConnected = true;
    });
  }

  // TODO [DEV ONLY]: 上线时删除此方法
  void _onDevSkipConnected() {
    setState(() {
      _isConnected = true;
    });
  }

  void _listenConnectionState(BluetoothDevice device) {
    _connectionSubscription?.cancel();
    _connectionSubscription = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _onDeviceDisconnected();
      }
    });
  }

  void _onDeviceDisconnected() {
    _connectionSubscription?.cancel();
    _connectedDevice = null;
    if (mounted) {
      setState(() {
        _isConnected = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.bluetooth_disabled, color: Colors.white),
              SizedBox(width: 8),
              Text('蓝牙连接已断开'),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _disconnectAndReturn() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
    }
    _onDeviceDisconnected();
  }

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
          ? HomePage(
              device: _connectedDevice,
              onDisconnect: _disconnectAndReturn,
            )
          : BluetoothConnectPage(
              onConnected: _onDeviceConnected,
              // TODO [DEV ONLY]: 上线时删除此参数
              onDevSkip: _onDevSkipConnected,
            ),
      debugShowCheckedModeBanner: false,
    );
  }
}
