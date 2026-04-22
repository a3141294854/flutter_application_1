import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class SendOptionsPage extends StatefulWidget {
  final bool isConnected;
  final BluetoothDevice? device;

  const SendOptionsPage({
    super.key,
    required this.isConnected,
    this.device,
  });

  @override
  State<SendOptionsPage> createState() => _SendOptionsPageState();
}

class _SendOptionsPageState extends State<SendOptionsPage> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          _buildSectionTitle('发送选项'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4A90D9).withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSendOptionRow('读取配置', Icons.download, () => _sendCommand('READ')),
                Container(height: 1, color: const Color(0xFFF0F7FF), margin: const EdgeInsets.symmetric(horizontal: 10)),
                _buildSendOptionRow('保存配置', Icons.save, () => _sendCommand('SAVE')),
                Container(height: 1, color: const Color(0xFFF0F7FF), margin: const EdgeInsets.symmetric(horizontal: 10)),
                _buildSendOptionRow('恢复出厂', Icons.restore, () => _sendCommand('RESET')),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2D4A6F),
        ),
      ),
    );
  }

  Widget _buildSendOptionRow(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: widget.isConnected ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: widget.isConnected ? const Color(0xFF4A90D9) : const Color(0xFFA0BCD6),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: widget.isConnected ? const Color(0xFF2D4A6F) : const Color(0xFFA0BCD6),
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: widget.isConnected ? const Color(0xFF4A90D9) : const Color(0xFFA0BCD6),
            ),
          ],
        ),
      ),
    );
  }

  void _sendCommand(String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('发送命令: $type'),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF4A90D9),
      ),
    );
  }
}
