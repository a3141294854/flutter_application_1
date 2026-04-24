import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../protocol/protocol.dart';
import 'device_list_page.dart';
import 'settings_page.dart';
import 'child_settings_page.dart';
import 'send_options_page.dart';
import 'debug_panel_page.dart';

enum NodeType { root, child }

class HomePage extends StatefulWidget {
  final BluetoothDevice? device;
  final DtuService dtuService;
  final VoidCallback onDisconnect;

  const HomePage({
    super.key,
    this.device,
    required this.dtuService,
    required this.onDisconnect,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  /// 根据设备配置中的角色自动确定节点类型
  NodeType get _nodeType {
    // 如果有设备信息，使用设备信息的角色
    final deviceInfo = widget.dtuService.deviceInfo;
    if (deviceInfo != null) {
      return deviceInfo.isRoot ? NodeType.root : NodeType.child;
    }
    // 默认使用根节点
    return NodeType.root;
  }

  /// 获取设备角色名称
  String get _roleName {
    final deviceInfo = widget.dtuService.deviceInfo;
    return deviceInfo?.roleName ?? '未知';
  }

  String get _deviceName {
    if (widget.device == null) return '未知设备';
    final name = widget.device!.platformName;
    return name.isNotEmpty ? name : '未知设备';
  }

  String get _deviceMac {
    // 优先使用协议层获取的 MAC
    final deviceInfo = widget.dtuService.deviceInfo;
    if (deviceInfo != null && deviceInfo.mac.isNotEmpty) {
      return deviceInfo.mac;
    }
    if (widget.device == null) return '00:00:00:00:00:00';
    return 'AA:BB:CC:DD:EE:FF';
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
                        Row(
                          children: [
                            const Text(
                              '已连接',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4CAF50),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _nodeType == NodeType.root
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFFFF9800),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _nodeType == NodeType.root ? Icons.hub : Icons.device_hub,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _roleName,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                        const SizedBox(height: 2),
                        Text(
                          _deviceMac,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFA0BCD6),
                          ),
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
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DebugPanelPage()),
                      );
                    },
                    icon: const Icon(
                      Icons.bug_report,
                      color: Color(0xFF4A90D9),
                    ),
                    tooltip: '调试面板',
                  ),
                ],
              ),
            ),
            // 页面内容
            Expanded(
              child: _nodeType == NodeType.root
                  ? IndexedStack(
                      index: _currentIndex,
                      children: [
                        DeviceListPage(isConnected: true, dtuService: widget.dtuService),
                        SettingsPage(isConnected: true, dtuService: widget.dtuService),
                        SendOptionsPage(isConnected: true, dtuService: widget.dtuService),
                      ],
                    )
                  : IndexedStack(
                      index: _currentIndex,
                      children: [
                        ChildSettingsPage(isConnected: true, dtuService: widget.dtuService),
                        SendOptionsPage(isConnected: true, dtuService: widget.dtuService),
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
                if (_nodeType == NodeType.root)
                  Expanded(
                    child: _buildNavItem(Icons.list_alt, '子设备白名单', 0),
                  ),
                Expanded(
                  child: _buildNavItem(Icons.settings, '参数设置', _nodeType == NodeType.child ? 0 : 1),
                ),
                Expanded(
                  child: _buildNavItem(Icons.send, '发送', _nodeType == NodeType.child ? 1 : 2),
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
