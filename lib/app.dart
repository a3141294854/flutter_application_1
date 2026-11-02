// lib/app.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'page/home.dart';
import 'page/bluetooth_connect_page.dart';
import 'page/mode_select_page.dart';
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
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

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

    // 从蓝牙连接页跳转到 HomePage
    _navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomePage(
          device: _connectedDevice,
          dtuService: _dtuService,
          onDisconnect: _disconnectAndReturn,
          onBack: () => _onBackFromHome(),
        ),
      ),
    );
  }

  // TODO [DEV ONLY]: 上线时删除此方法
  void _onDevSkipConnected() {
    // 从蓝牙连接页跳转到 HomePage
    _navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomePage(
          device: null,
          dtuService: _dtuService,
          onDisconnect: _disconnectAndReturn,
          onBack: () => _onBackFromHome(),
        ),
      ),
    );
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
      // pop 回模式选择页
      _navigatorKey.currentState?.pop();
    }
  }

  void _onBackFromHome() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
    }
    _connectionSubscription?.cancel();
    _connectedDevice = null;
    await _dtuService.disconnect();
    _navigatorKey.currentState?.pop();
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
      navigatorKey: _navigatorKey,
      home: ModeSelectPage(
        onBluetoothConfig: () {
          _navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => BluetoothConnectPage(
                onConnected: _onDeviceConnected,
                onDevSkip: _onDevSkipConnected,
              ),
            ),
          );
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
