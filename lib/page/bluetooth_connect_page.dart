import 'package:flutter/material.dart';

class BluetoothConnectPage extends StatefulWidget {
  final VoidCallback onConnected;

  const BluetoothConnectPage({super.key, required this.onConnected});

  @override
  State<BluetoothConnectPage> createState() => _BluetoothConnectPageState();
}

class _BluetoothConnectPageState extends State<BluetoothConnectPage> {
  bool _isScanning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      body: SafeArea(
        child: Center(
          child: GestureDetector(
            onTap: _isScanning ? null : _startScan,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4A90D9).withOpacity(0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bluetooth,
                    size: 64,
                    color: const Color(0xFF4A90D9),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isScanning ? '扫描中' : '连接',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D4A6F),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
    });
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        widget.onConnected();
      }
    });
  }
}
