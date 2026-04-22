import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'device_list_page.dart';
import 'settings_page.dart';
import 'child_settings_page.dart';
import 'send_options_page.dart';

enum NodeType { root, child }

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
  NodeType _nodeType = NodeType.root;

  String get _deviceName {
    if (widget.device == null) return '未知设备';
    final name = widget.device!.platformName;
    return name.isNotEmpty ? name : '未知设备';
  }

  String get _deviceMac {
    if (widget.device == null) return '00:00:00:00:00:00';
    // 开发模式或无法获取MAC时显示默认值
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
                            GestureDetector(
                              onTap: _showNodeTypeDialog,
                              child: Container(
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
                                      _nodeType == NodeType.root ? '根节点' : '子节点',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(
                                      Icons.arrow_drop_down,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ],
                                ),
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
                ],
              ),
            ),
            // 页面内容
            Expanded(
              child: _nodeType == NodeType.root
                  ? IndexedStack(
                      index: _currentIndex,
                      children: [
                        DeviceListPage(isConnected: true, device: widget.device),
                        SettingsPage(isConnected: true, device: widget.device),
                        SendOptionsPage(isConnected: true, device: widget.device),
                      ],
                    )
                  : IndexedStack(
                      index: _currentIndex,
                      children: [
                        ChildSettingsPage(isConnected: true, device: widget.device),
                        SendOptionsPage(isConnected: true, device: widget.device),
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

  void _showNodeTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF0F7FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.settings_input_antenna, color: Color(0xFF4A90D9)),
            SizedBox(width: 8),
            Text(
              '选择节点类型',
              style: TextStyle(color: Color(0xFF2D4A6F), fontSize: 15),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNodeTypeOption(
              '根节点',
              '主机节点，可配置子设备白名单',
              Icons.hub,
              const Color(0xFF4CAF50),
              NodeType.root,
            ),
            const SizedBox(height: 10),
            _buildNodeTypeOption(
              '子节点',
              '从设备节点，仅可配置串口参数',
              Icons.device_hub,
              const Color(0xFFFF9800),
              NodeType.child,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNodeTypeOption(String title, String desc, IconData icon, Color color, NodeType type) {
    final isSelected = _nodeType == type;
    return GestureDetector(
      onTap: () {
        setState(() => _nodeType = type);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE8F2FF),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : const Color(0xFF2D4A6F),
                    ),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFA0BCD6),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
