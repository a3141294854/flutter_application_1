import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../widget/qr_scanner_dialog.dart';

// TODO [DEV ONLY]: 上线时删除此类
class _DevSkipButton extends StatelessWidget {
  final VoidCallback onSkip;

  const _DevSkipButton({required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSkip,
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.developer_mode, color: Colors.white, size: 18),
                SizedBox(width: 4),
                Text(
                  '开发跳过',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BluetoothConnectPage extends StatefulWidget {
  final void Function(BluetoothDevice device) onConnected;
  // TODO [DEV ONLY]: 上线时删除此参数
  final VoidCallback? onDevSkip;

  const BluetoothConnectPage({
    super.key,
    required this.onConnected,
    this.onDevSkip,
  });

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

  /// 通过二维码扫描连接设备
  Future<void> _scanQrAndConnect() async {
    if (_adapterState != BluetoothAdapterState.on) {
      _showError('请先开启蓝牙');
      return;
    }

    final result = await showDialog<({String name, String mac})>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const QrScannerDialog(),
    );

    if (result == null) return;

    final name = result.name;
    final mac = result.mac;
    
    // 显示正在尝试连接
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text('正在连接 $name ($mac)...'),
            ],
          ),
          backgroundColor: const Color(0xFF4A90D9),
          duration: const Duration(seconds: 10),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    // 搜索匹配 MAC 地址的设备
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 10),
      withServices: [], // 不过滤服务
    );

    BluetoothDevice? targetDevice;
    await for (final results in FlutterBluePlus.scanResults) {
      for (final result in results) {
        if (result.device.remoteId.str.toUpperCase().replaceAll('-', ':') == mac ||
            result.device.remoteId.str.toUpperCase() == mac) {
          targetDevice = result.device;
          await FlutterBluePlus.stopScan();
          break;
        }
      }
      if (targetDevice != null) break;
    }

    if (targetDevice != null) {
      await _connectToDevice(targetDevice, deviceName: name);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showError('未找到设备 $name，请确保设备在范围内且蓝牙已开启');
      }
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device, {String? deviceName}) async {
    setState(() {
      _connectingDevice = device;
    });

    try {
      await device.connect(timeout: const Duration(seconds: 15));
      
      if (mounted) {
        _showSuccess(device, overrideName: deviceName);
      }
    } on Exception catch (e) {
      if (mounted) {
        _showError(_getErrorMessage(e));
        setState(() {
          _connectingDevice = null;
        });
      }
    }
  }

  String _getErrorMessage(Exception e) {
    final errorStr = e.toString().toLowerCase();
    if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
      return '连接超时，请确保设备在范围内并重试';
    } else if (errorStr.contains('already connected')) {
      return '设备已连接';
    } else if (errorStr.contains('bond')) {
      return '配对失败，请先在手机蓝牙设置中配对该设备';
    } else if (errorStr.contains('permission')) {
      return '蓝牙权限不足，请检查应用权限设置';
    } else if (errorStr.contains('state')) {
      return '蓝牙状态异常，请检查蓝牙是否开启';
    }
    return '连接失败: ${e.toString()}';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(BluetoothDevice device, {String? overrideName}) {
    final deviceName = overrideName ?? (device.platformName.isNotEmpty 
        ? device.platformName 
        : '设备');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('已连接 $deviceName'),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        widget.onConnected(device);
      }
    });
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
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 二维码扫描入口
              _buildQrScanButton(),
              const SizedBox(height: 24),
              // 蓝牙扫描入口
              GestureDetector(
                onTap: _startScan,
                child: Container(
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
                        color: const Color(0xFF4A90D9).withValues(alpha: 0.15),
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
        // TODO [DEV ONLY]: 上线时删除此按钮
        Positioned(
          bottom: 24,
          right: 24,
          child: _DevSkipButton(onSkip: () => _skipToConnected()),
        ),
      ],
    );
  }

  // TODO [DEV ONLY]: 上线时删除此方法
  void _skipToConnected() {
    widget.onDevSkip?.call();
  }

  /// 构建二维码扫描按钮
  Widget _buildQrScanButton() {
    return GestureDetector(
      onTap: _scanQrAndConnect,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A90D9).withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: const Color(0xFF4A90D9).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.qr_code_scanner,
              size: 20,
              color: Color(0xFF4A90D9),
            ),
            SizedBox(width: 10),
            Text(
              '扫码连接',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F7FF),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4A90D9).withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF2D4A6F)),
                onPressed: _closeList,
              ),
              Expanded(
                child: Text(
                  '选择设备',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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
        // 扫描状态栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isScanning)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF4A90D9),
                  ),
                ),
              if (_isScanning) const SizedBox(width: 10),
              Text(
                _isScanning
                    ? '正在扫描... (${_scanResults.length})'
                    : _scanResults.isEmpty
                        ? '点击重新扫描'
                        : '共 ${_scanResults.length} 个设备',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF5A7A9A),
                ),
              ),
              if (!_isScanning && !_scanResults.isEmpty) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _startScan,
                  child: const Text(
                    '刷新',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4A90D9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        // 设备列表或空状态
        Expanded(
          child: _scanResults.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.bluetooth_searching,
                        size: 64,
                        color: Color(0xFFA0BCD6),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isScanning ? '正在搜索附近设备...' : '未找到设备',
                        style: const TextStyle(
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
                  ),
                )
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
            color: const Color(0xFF4A90D9).withValues(alpha: 0.06),
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
