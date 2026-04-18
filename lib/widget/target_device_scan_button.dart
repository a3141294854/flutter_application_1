import 'package:flutter/material.dart';

/// 目标主设备扫描按钮组件
/// 你可以把这个类放在你的 widgets 文件夹里，比如：widgets/target_device_scan_button.dart
class TargetDeviceScanButton extends StatelessWidget {
  /// 📝【你需要填写】点击按钮时触发的函数
  /// 例如：(context) => startScanning()
  final VoidCallback? onTap;

  const TargetDeviceScanButton({
    Key? key,
    this.onTap, // 允许传入 null，这样你可以控制是否禁用点击
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 让容器高度自适应内容
        children: [
          // 1. 顶部标题
          Text(
            '目标主设备 (TARGET)',
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey[700],
            ),
          ),
          const SizedBox(height: 24.0),

          // 2. 中间图标（模拟图中的二维码图标）
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.lightBlue.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.qr_code_scanner, // 使用系统自带的扫码图标
              size: 40,
              color: Colors.lightBlue[300],
            ),
          ),
          const SizedBox(height: 20.0),

          // 3. 主文案
          Text(
            '扫描主设备 MAC',
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8.0),

          // 4. 副文案（点击提示）
          GestureDetector(
            onTap: onTap, // 👈 点击这里会调用你传入的函数
            child: Text(
              '点击此处开启扫描',
              style: TextStyle(
                fontSize: 14.0,
                color: Colors.blue[500],
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}