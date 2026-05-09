import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TargetDeviceScanButton extends StatelessWidget {
  final VoidCallback? onTap;

  const TargetDeviceScanButton({
    Key? key,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: NeuTheme.cardDecoration(radius: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '目标主设备 (TARGET)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: NeuTheme.textPrimary),
            ),
            const SizedBox(height: 24),
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(color: NeuTheme.card, shape: BoxShape.circle),
              child: Icon(Icons.qr_code_scanner, size: 44, color: NeuTheme.accent),
            ),
            const SizedBox(height: 20),
            const Text(
              '扫描主设备 MAC',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: NeuTheme.textPrimary),
            ),

          ],
        ),
      ),
    );
  }
}
