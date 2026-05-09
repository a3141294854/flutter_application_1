// lib/app.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'page/home.dart';
import 'page/bluetooth_connect_page.dart';
import 'protocol/protocol.dart';
import 'theme/app_theme.dart';

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

  /// DTU 协议服务
  DtuService get _dtuService => DtuServiceManager().service;

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }

  void _onDeviceConnected(BluetoothDevice device) async {
    _connectedDevice = device;
    _listenConnectionState(device);

    // 连接后读取设备信息获取角色
    try {
      await _dtuService.connect(device);
      await _dtuService.readDeviceInfo();
    } catch (e) {
      debugPrint('读取设备信息失败: $e');
    }

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

  void _onDeviceDisconnected() async {
    _connectionSubscription?.cancel();
    _connectedDevice = null;
    await _dtuService.disconnect();
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
          backgroundColor: NeuTheme.warning,
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
      theme: NeuThemeData.light,
      home: _isConnected
          ? HomePage(
              device: _connectedDevice,
              dtuService: _dtuService,
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
