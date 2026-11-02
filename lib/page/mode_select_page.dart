import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'monitor_page.dart';

/// 启动模式选择页面
class ModeSelectPage extends StatelessWidget {
  final VoidCallback onBluetoothConfig;

  const ModeSelectPage({super.key, required this.onBluetoothConfig});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeuTheme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Logo 区域
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: NeuTheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.bluetooth_connected,
                  color: NeuTheme.accent,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'DTU 配置助手',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: NeuTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '请选择操作模式',
                style: TextStyle(
                  fontSize: 14,
                  color: NeuTheme.textSecondary,
                ),
              ),
              const Spacer(flex: 2),
              // 配置模式
              _buildModeCard(
                context,
                icon: Icons.settings_bluetooth,
                title: '蓝牙配置',
                subtitle: '连接 DTU 设备，配置参数和白名单',
                color: NeuTheme.accent,
                onTap: onBluetoothConfig,
              ),
              const SizedBox(height: 16),
              // 监视模式
              _buildModeCard(
                context,
                icon: Icons.monitor_heart_outlined,
                title: '设备监视',
                subtitle: '远程查看设备运行状态和数据',
                color: NeuTheme.success,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                        backgroundColor: NeuTheme.bg,
                        body: SafeArea(child: MonitorPage()),
                      ),
                    ),
                  );
                },
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: NeuTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color, size: 24),
          ],
        ),
      ),
    );
  }
}
