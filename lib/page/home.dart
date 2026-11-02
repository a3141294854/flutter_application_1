import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../protocol/protocol.dart';
import '../theme/app_theme.dart';
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
  final VoidCallback? onBack;

  const HomePage({
    super.key,
    this.device,
    required this.dtuService,
    required this.onDisconnect,
    this.onBack,
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
      backgroundColor: NeuTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // 蓝牙状态栏
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: NeuTheme.card,
                boxShadow: NeuTheme.shadowRaisedSm,
              ),
              child: Row(
                children: [
                  // 返回按钮
                  IconButton(
                    onPressed: widget.onBack ?? widget.onDisconnect,
                    icon: const Icon(
                      Icons.arrow_back,
                      color: NeuTheme.textMuted,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: NeuTheme.successBg,
                      borderRadius: BorderRadius.circular(NeuTheme.radiusSm),
                    ),
                    child: const Icon(
                      Icons.bluetooth_connected,
                      color: NeuTheme.success,
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
                                color: NeuTheme.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _nodeType == NodeType.root
                                    ? NeuTheme.accent
                                    : NeuTheme.warning,
                                borderRadius: BorderRadius.circular(NeuTheme.radiusFull),
                              ),
                              child: GestureDetector(
                                onTap: widget.dtuService.isConnected ? _showRoleSwitchDialog : null,
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
                                    const SizedBox(width: 2),
                                    const Icon(
                                      Icons.swap_horiz,
                                      color: Colors.white,
                                      size: 12,
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
                            color: NeuTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _deviceMac,
                          style: const TextStyle(
                            fontSize: 11,
                            color: NeuTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showDisconnectDialog(context),
                    icon: const Icon(
                      Icons.link_off,
                      color: NeuTheme.textMuted,
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
                      color: NeuTheme.accent,
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
          color: NeuTheme.card,
          boxShadow: const [
            BoxShadow(color: NeuTheme.shadowDark, offset: Offset(0, -4), blurRadius: 8),
            BoxShadow(color: NeuTheme.shadowLight, offset: Offset(0, -4), blurRadius: 8),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
            color: isSelected ? NeuTheme.accent : NeuTheme.textMuted,
            size: 20,
          ),
          const SizedBox(height: 2),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isSelected ? NeuTheme.accent : NeuTheme.textMuted,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _showRoleSwitchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NeuTheme.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NeuTheme.radiusMd)),
        title: const Row(
          children: [
            Icon(Icons.swap_horiz, color: NeuTheme.accent, size: 24),
            SizedBox(width: 8),
            Text('切换角色', style: TextStyle(color: NeuTheme.textPrimary, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '选择设备角色：',
              style: TextStyle(color: NeuTheme.textPrimary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            _RoleOption(
              title: 'ROOT (根节点)',
              subtitle: '可连接多个子节点',
              icon: Icons.hub,
              color: NeuTheme.accent,
              isSelected: _nodeType == NodeType.root,
              onTap: () => _switchRole(NodeType.root),
            ),
            const SizedBox(height: 12),
            _RoleOption(
              title: 'NODE (子节点)',
              subtitle: '连接一个根节点',
              icon: Icons.device_hub,
              color: NeuTheme.warning,
              isSelected: _nodeType == NodeType.child,
              onTap: () => _switchRole(NodeType.child),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  Future<void> _switchRole(NodeType targetRole) async {
    // 判断目标角色
    final int targetRoleValue = targetRole == NodeType.root
        ? DtuProtocol.ROLE_ROOT  // 0x01
        : DtuProtocol.ROLE_NODE; // 0x00

    final targetRoleName = targetRole == NodeType.root ? 'ROOT (根节点)' : 'NODE (子节点)';

    // 关闭角色选择对话框
    Navigator.pop(context);

    // 等待一帧，确保对话框已关闭
    await Future.delayed(Duration.zero);

    if (!mounted) return;

    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: NeuTheme.bg,
        content: const Row(
          children: [
            SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: NeuTheme.accent)),
            SizedBox(width: 16),
            Text('正在切换角色...', style: TextStyle(color: NeuTheme.textPrimary)),
          ],
        ),
      ),
    ).then((_) async {
      // 对话框关闭后执行
    });

    try {
      // 1. 设置角色
      await widget.dtuService.writeAllConfig(role: targetRoleValue);

      // 2. 更新 DtuService 中的角色信息
      widget.dtuService.updateRole(targetRoleValue);

      // 3. 关闭加载对话框
      if (mounted) {
        Navigator.pop(context); // 关闭加载对话框
      }

      // 4. 强制重建 UI
      if (mounted) {
        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('角色已切换为 $targetRoleName'),
            backgroundColor: NeuTheme.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      // 关闭加载对话框
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('切换失败: $e'),
            backgroundColor: NeuTheme.error,
          ),
        );
      }
    }
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
              style: TextStyle(color: NeuTheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : NeuTheme.card,
          borderRadius: BorderRadius.circular(NeuTheme.radiusMd),
          boxShadow: isSelected ? [] : NeuTheme.shadowRaisedSm,
          border: Border.all(color: isSelected ? color : NeuTheme.card, width: isSelected ? 2 : 0),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : NeuTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: NeuTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }
}
