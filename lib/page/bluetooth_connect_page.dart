import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothConnectPage extends StatefulWidget {
  final VoidCallback onConnected;

  const BluetoothConnectPage({super.key, required this.onConnected});

  @override
  State<BluetoothConnectPage> createState() => _BluetoothConnectPageState();
}

class _BluetoothConnectPageState extends State<BluetoothConnectPage> {
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  bool _showList = false;
  BluetoothDevice? _connectingDevice;
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;

  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
    _listenAdapterState();
  }

  @override
  void dispose() {
    _adapterStateSubscription?.cancel();
    _scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  Future<void> _initBluetooth() async {
    final isSupported = await FlutterBluePlus.isSupported;
    if (!isSupported) {
      if (mounted) {
        _showError('蓝牙不被支持');
      }
      return;
    }

    await FlutterBluePlus.turnOn();
  }

  void _listenAdapterState() {
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      if (mounted) {
        setState(() {
          _adapterState = state;
        });
        if (state != BluetoothAdapterState.on) {
          _showError('请开启蓝牙');
        }
      }
    });
  }

  Future<void> _startScan() async {
    if (_adapterState != BluetoothAdapterState.on) {
      _showError('请先开启蓝牙');
      return;
    }

    setState(() {
      _isScanning = true;
      _scanResults.clear();
      _showList = true;
    });

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          _scanResults = results.where((r) => r.device.platformName.isNotEmpty).toList();
        });
      }
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    if (mounted) {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _stopScan() async {
    await FlutterBluePlus.stopScan();
    if (mounted) {
      setState(() {
        _isScanning = false;
      });
    }
  }

  void _closeList() {
    _stopScan();
    setState(() {
      _showList = false;
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _connectingDevice = device;
    });

    try {
      await device.connect(timeout: const Duration(seconds: 15));
      
      if (mounted) {
        widget.onConnected();
      }
    } catch (e) {
      if (mounted) {
        _showError('连接失败');
        setState(() {
          _connectingDevice = null;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      body: SafeArea(
        child: _showList ? _buildDeviceListView() : _buildBluetoothButton(),
      ),
    );
  }

  Widget _buildBluetoothButton() {
    return GestureDetector(
      onTap: _startScan,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE8F2FF), Color(0xFFF5FAFF)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4A90D9).withOpacity(0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.bluetooth,
                size: 80,
                color: Color(0xFF4A90D9),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '点击连接蓝牙设备',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D4A6F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceListView() {
    return Column(
      children: [
        // 顶部栏
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF2D4A6F)),
                onPressed: _closeList,
              ),
              const Expanded(
                child: Text(
                  '选择设备',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D4A6F),
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
        // 扫描状态和未找到设备 - 居中显示
        Expanded(
          child: Center(
            child: _isScanning
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF4A90D9),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '正在扫描... (${_scanResults.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF5A7A9A),
                        ),
                      ),
                    ],
                  )
                : _scanResults.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.bluetooth_searching,
                            size: 64,
                            color: Color(0xFFA0BCD6),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '未找到设备',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5A7A9A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _startScan,
                            child: const Text(
                              '重新扫描',
                              style: TextStyle(color: Color(0xFF4A90D9)),
                            ),
                          ),
                        ],
                      )
                    : const SizedBox(),
          ),
        ),
        // 设备列表
        Expanded(
          child: _scanResults.isEmpty
              ? const SizedBox()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _scanResults.length,
                  itemBuilder: (context, index) {
                    return _buildDeviceCard(_scanResults[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDeviceCard(ScanResult result) {
    final device = result.device;
    final isConnecting = _connectingDevice == device;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A90D9).withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F2FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.bluetooth,
            color: Color(0xFF4A90D9),
          ),
        ),
        title: Text(
          device.platformName.isNotEmpty ? device.platformName : '未知设备',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D4A6F),
          ),
        ),
        subtitle: Text(
          device.remoteId.str,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFFA0BCD6),
          ),
        ),
        trailing: isConnecting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF4A90D9),
                ),
              )
            : const Icon(
                Icons.chevron_right,
                color: Color(0xFFA0BCD6),
              ),
        onTap: () => _connectToDevice(device),
      ),
    );
  }
}
