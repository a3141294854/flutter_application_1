import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerDialog extends StatefulWidget {
  const QrScannerDialog({super.key});

  @override
  State<QrScannerDialog> createState() => _QrScannerDialogState();
}

class _QrScannerDialogState extends State<QrScannerDialog> {
  MobileScannerController? _controller;
  bool _hasScanned = false;
  String? _errorMessage;
  bool _torchOn = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
      );
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '摄像头启动失败，请检查权限';
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// 解析二维码内容，提取蓝牙设备信息
  /// 支持格式:
  /// - JSON: {"name":"xxx","mac":"xxx"} 或 {"n":"xxx","m":"xxx"}
  /// - BT:设备名称:MAC地址 (如 BT:DTU_Device:AA:BB:CC:DD:EE:FF)
  /// - name:xxx;mac:xxx (如 name:DTU;mac:AA:BB:CC:DD:EE:FF)
  /// - 直接是 MAC 地址 (如 AA:BB:CC:DD:EE:FF)
  ({String name, String mac})? _parseQrContent(String content) {
    content = content.trim();
    
    // 格式0: JSON 格式
    if (content.startsWith('{') && content.endsWith('}')) {
      final result = _parseJsonContent(content);
      if (result != null) return result;
    }
    
    // 格式1: BT:设备名称:MAC地址
    if (content.startsWith('BT:') || content.startsWith('bt:')) {
      final parts = content.split(':');
      if (parts.length >= 3) {
        final name = parts[1].trim();
        final mac = parts.sublist(2).join(':').replaceAll('-', ':').toUpperCase();
        if (_isValidMac(mac)) {
          return (name: name, mac: mac);
        }
      }
    }
    
    // 格式2: name:xxx;mac:xxx
    if (content.contains(';') || content.contains('&')) {
      final separator = content.contains(';') ? ';' : '&';
      final parts = content.split(separator);
      String? name;
      String? mac;
      
      for (final part in parts) {
        final kv = part.split(':');
        if (kv.length == 2) {
          final key = kv[0].trim().toLowerCase();
          final value = kv[1].trim();
          if (key == 'name' || key == 'n' || key == '设备名称') {
            name = value;
          } else if (key == 'mac' || key == 'm' || key == '地址') {
            mac = value.replaceAll('-', ':').toUpperCase();
          }
        }
      }
      
      if (name != null && mac != null && _isValidMac(mac)) {
        return (name: name, mac: mac);
      }
    }
    
    // 格式3: 直接是 MAC 地址
    final cleanedMac = content.replaceAll('-', ':').toUpperCase();
    if (_isValidMac(cleanedMac)) {
      return (name: '设备', mac: cleanedMac);
    }
    
    return null;
  }

  /// 解析 JSON 格式的二维码内容
  ({String name, String mac})? _parseJsonContent(String content) {
    try {
      // 简单解析 JSON，不依赖 dart:convert
      String? name;
      String? mac;
      
      // 提取 name 字段
      final namePatterns = [
        '"name"\\s*:\\s*"([^"]+)"',
        '"n"\\s*:\\s*"([^"]+)"',
      ];
      for (final pattern in namePatterns) {
        final match = RegExp(pattern).firstMatch(content);
        if (match != null) {
          name = match.group(1);
          break;
        }
      }
      
      // 提取 mac 字段
      final macPatterns = [
        '"mac"\\s*:\\s*"([^"]+)"',
        '"m"\\s*:\\s*"([^"]+)"',
      ];
      for (final pattern in macPatterns) {
        final match = RegExp(pattern).firstMatch(content);
        if (match != null) {
          mac = match.group(1)?.replaceAll('-', ':').toUpperCase();
          break;
        }
      }
      
      if (name != null && mac != null && _isValidMac(mac)) {
        return (name: name, mac: mac);
      }
    } catch (_) {
      // 解析失败，忽略
    }
    return null;
  }

  bool _isValidMac(String mac) {
    // 验证 MAC 地址格式 (6组16进制数，用:或-分隔)
    final macRegex = RegExp(r'^([0-9A-Fa-f]{2}[:\-]){5}([0-9A-Fa-f]{2})$');
    return macRegex.hasMatch(mac);
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final value = barcode.rawValue;
      if (value == null) continue;

      debugPrint('[QRScanner] 扫描到内容: $value');
      final result = _parseQrContent(value);
      if (result != null) {
        debugPrint('[QRScanner] 解析成功: name=${result.name}, mac=${result.mac}');
        _hasScanned = true;
        Navigator.of(context).pop(result);
        return;
      } else {
        debugPrint('[QRScanner] 无法解析该内容');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.qr_code_scanner, color: Colors.white),
                const SizedBox(width: 8),
                const Text(
                  '扫描设备二维码',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _torchOn ? Icons.flash_on : Icons.flash_off,
                    color: _torchOn ? Colors.amber : Colors.white,
                  ),
                  onPressed: _controller != null
                      ? () async {
                          await _controller!.toggleTorch();
                          setState(() {
                            _torchOn = !_torchOn;
                          });
                        }
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          
          // 扫描区域
          SizedBox(
            height: 320,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isInitializing)
                  const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text('正在启动摄像头...', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  )
                else if (_controller != null)
                  MobileScanner(
                    controller: _controller!,
                    onDetect: _onDetect,
                  )
                else
                  const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.no_photography, color: Colors.orange, size: 48),
                        SizedBox(height: 16),
                        Text('摄像头启动失败', style: TextStyle(color: Colors.orange)),
                        SizedBox(height: 8),
                        Text('请检查摄像头权限', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                // 扫描框
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                // 扫描角
                ...List.generate(4, (index) {
                  final isTop = index < 2;
                  final isLeft = index % 2 == 0;
                  return Positioned(
                    top: isTop ? 40 : null,
                    bottom: isTop ? null : 40,
                    left: isLeft ? null : null,
                    right: isLeft ? null : null,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border(
                          top: isTop ? const BorderSide(color: Color(0xFF4A90D9), width: 4) : BorderSide.none,
                          bottom: !isTop ? const BorderSide(color: Color(0xFF4A90D9), width: 4) : BorderSide.none,
                          left: isLeft ? const BorderSide(color: Color(0xFF4A90D9), width: 4) : BorderSide.none,
                          right: !isLeft ? const BorderSide(color: const Color(0xFF4A90D9), width: 4) : BorderSide.none,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          
          // 提示信息
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Text(
                  _errorMessage ?? '请扫描设备上的蓝牙二维码',
                  style: TextStyle(
                    color: _errorMessage != null ? Colors.orange : Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '支持的格式: JSON / BT:名称:MAC / name:xxx;mac:xxx',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
