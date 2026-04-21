import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'device_list_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  final BluetoothDevice? device;
  final VoidCallback onDisconnect;

  const HomePage({
    super.key,
    this.device,
    required this.onDisconnect,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  String get _deviceName {
    if (widget.device == null) return '未知设备';
    final name = widget.device!.platformName;
    return name.isNotEmpty ? name : '未知设备';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      body: SafeArea(
        child: Column(
          children: [
            // 蓝牙状态栏
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4A90D9).withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.bluetooth_connected,
                      color: Color(0xFF4CAF50),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '已连接',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4CAF50),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _deviceName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D4A6F),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showDisconnectDialog(context),
                    icon: const Icon(
                      Icons.link_off,
                      color: Color(0xFF7A9CC6),
                    ),
                    tooltip: '断开连接',
                  ),
                ],
              ),
            ),
            // 页面内容
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  DeviceListPage(isConnected: true, device: widget.device),
                  SettingsPage(isConnected: true, device: widget.device),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A90D9).withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildNavItem(Icons.list_alt, '子设备白名单 (0)', 0),
                ),
                Expanded(
                  child: _buildNavItem(Icons.settings, '参数设置', 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String text, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF4A90D9) : const Color(0xFF7A9CC6),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: TextStyle(
              color: isSelected ? const Color(0xFF4A90D9) : const Color(0xFF7A9CC6),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showDisconnectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('断开连接'),
        content: Text('确定要断开与 "$_deviceName" 的连接吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDisconnect();
            },
            child: const Text(
              '断开',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
