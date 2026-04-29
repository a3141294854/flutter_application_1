import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../protocol/protocol.dart';

/// 二维码扫描结果模型
class QRScanResult {
  final String name;
  final String mac;
  final String role;

  QRScanResult({required this.name, required this.mac, required this.role});

  /// 从字符串解析二维码内容，支持多种格式
  static QRScanResult? fromString(String content) {
    content = content.trim();

    // 格式1: JSON 格式 {"name":"xxx","mac":"AA:BB:CC:DD:EE:FF"} (支持多行格式)
    if (content.contains('{') && content.contains('}')) {
      try {
        // 使用正则提取 name 和 mac
        String? name;
        String? mac;
        String? role;

        final nameMatch = RegExp(r'"name"\s*:\s*"([^"]+)"').firstMatch(content);
        if (nameMatch != null) name = nameMatch.group(1);

        final nMatch = RegExp(r'"n"\s*:\s*"([^"]+)"').firstMatch(content);
        if (nMatch != null && name == null) name = nMatch.group(1);

        final macMatch = RegExp(r'"mac"\s*:\s*"([^"]+)"').firstMatch(content);
        if (macMatch != null)
          mac = macMatch.group(1)?.replaceAll('-', ':').toUpperCase();

        final mMatch = RegExp(r'"m"\s*:\s*"([^"]+)"').firstMatch(content);
        if (mMatch != null && mac == null)
          mac = mMatch.group(1)?.replaceAll('-', ':').toUpperCase();

        final roleMatch = RegExp(r'"role"\s*:\s*"([^"]+)"').firstMatch(content);
        if (roleMatch != null) role = roleMatch.group(1);

        if (name != null && name.isNotEmpty && mac != null && isValidMac(mac)) {
          return QRScanResult(name: name, mac: mac, role: role ?? 'unknown');
        }
      } catch (_) {}
    }

    // 格式2: BT:设备名称:MAC地址 (如 BT:DTU_Device:AA:BB:CC:DD:EE:FF)
    if (content.startsWith('BT:') || content.startsWith('bt:')) {
      final parts = content.split(':');
      if (parts.length >= 3) {
        final name = parts[1].trim();
        final mac = parts
            .sublist(2)
            .join(':')
            .replaceAll('-', ':')
            .toUpperCase();
        if (isValidMac(mac)) {
          return QRScanResult(name: name, mac: mac, role: 'unknown');
        }
      }
    }

    // 格式3: name:xxx;mac:xxx (如 name:DTU;mac:AA:BB:CC:DD:EE:FF)
    if (content.contains(';') || content.contains('&')) {
      final separator = content.contains(';') ? ';' : '&';
      final parts = content.split(separator);
      String? name;
      String? mac;
      for (final part in parts) {
        final kv = part.split(':');
        if (kv.length >= 2) {
          final key = kv[0].trim().toLowerCase();
          final value = kv.sublist(1).join(':').trim();
          if (key == 'name' || key == 'n') {
            name = value;
          } else if (key == 'mac' || key == 'm') {
            mac = value.replaceAll('-', ':').toUpperCase();
          }
        }
      }
      if (name != null && name.isNotEmpty && mac != null && isValidMac(mac)) {
        return QRScanResult(name: name, mac: mac, role: 'unknown');
      }
    }

    // 格式4: 直接是 MAC 地址 (如 AA:BB:CC:DD:EE:FF)
    final cleanedMac = content.replaceAll('-', ':').toUpperCase();
    if (isValidMac(cleanedMac)) {
      return QRScanResult(name: cleanedMac, mac: cleanedMac, role: 'unknown'); // V2: name = mac
    }

    return null;
  }

  /// 验证MAC地址格式
  static bool isValidMac(String mac) {
    final macRegex = RegExp(r'^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$');
    return macRegex.hasMatch(mac);
  }
}

/// 子设备参数配置对话框（重构版）
class ChildNodeConfigDialog extends StatefulWidget {
  final WhiteListItem device;
  final Function(WhiteListItem) onConfigSaved;
  final Future<WhiteListItem> Function(String mac) onLoadNodeConfig;

  const ChildNodeConfigDialog({
    super.key,
    required this.device,
    required this.onConfigSaved,
    required this.onLoadNodeConfig,
  });

  @override
  State<ChildNodeConfigDialog> createState() => _ChildNodeConfigDialogState();
}

class _ChildNodeConfigDialogState extends State<ChildNodeConfigDialog> {
  // 串口参数
  late int _baudLevel;
  late int _dataBits;
  late int _stopBits;
  late int _parity;

  // Modbus 配置
  List<ModbusItem> _modbusItems = [];
  final List<TextEditingController> _addrControllers = [];

  // UI 状态
  bool _isLoading = true;
  String? _error;
  bool _dataLoaded = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    // 初始化显示为当前白名单项配置
    _baudLevel = widget.device.baudLevel;
    _dataBits = widget.device.dataBits;
    _stopBits = widget.device.stopBits;
    _parity = widget.device.parity;
    _modbusItems = List.from(widget.device.modbusItems);
    _syncModbusControllers();

    // 立即从设备读取真实配置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNodeConfig();
    });
  }

  Future<void> _loadNodeConfig() async {
    if (_dataLoaded) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('[ChildNodeConfig] 正在读取设备配置，MAC: ${widget.device.mac}');
      final nodeConfig = await widget.onLoadNodeConfig(widget.device.mac);

      print(
        '[ChildNodeConfig] 读取到的配置: '
        'baudLevel=${nodeConfig.baudLevel}, '
        'dataBits=${nodeConfig.dataBits}, '
        'stopBits=${nodeConfig.stopBits}, '
        'parity=${nodeConfig.parity}, '
        'modbusItems=${nodeConfig.modbusItems.length}',
      );

      if (mounted) {
        setState(() {
          // 仅更新从设备读取到的实际值
          _baudLevel = nodeConfig.baudLevel;
          _dataBits = nodeConfig.dataBits;
          _stopBits = nodeConfig.stopBits;
          _parity = nodeConfig.parity;
          _modbusItems = List.from(nodeConfig.modbusItems);
          _syncModbusControllers();
          _isLoading = false;
          _dataLoaded = true;
          _hasChanges = false;
        });
      }
    } catch (e, stackTrace) {
      print('[ChildNodeConfig] 读取配置失败: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          // 仍然显示UI，但保留从widget.device获取的初始值
        });
      }
    }
  }

  void _submit() {
    if (_isLoading || !_hasChanges) return;

    final updatedDevice = widget.device.copyWithFull(
      baudLevel: _baudLevel,
      dataBits: _dataBits,
      stopBits: _stopBits,
      parity: _parity,
      modbusItems: _modbusItems,
    );

    print(
      '[ChildNodeConfig] 保存配置: '
      'baudLevel=$_baudLevel, '
      'dataBits=$_dataBits, '
      'stopBits=$_stopBits, '
      'parity=$_parity, '
      'modbusCount=${_modbusItems.length}',
    );

    widget.onConfigSaved(updatedDevice);
    Navigator.pop(context);
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  void _syncModbusControllers() {
    while (_addrControllers.length < _modbusItems.length) {
      _addrControllers.add(TextEditingController());
    }

    while (_addrControllers.length > _modbusItems.length) {
      _addrControllers.removeLast().dispose();
    }

    for (int i = 0; i < _modbusItems.length; i++) {
      _addrControllers[i].text = '${_modbusItems[i].addr}';
    }
  }

  @override
  void dispose() {
    for (final controller in _addrControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 加载中状态
    if (_isLoading) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7FF),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4A90D9).withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF4A90D9)),
                SizedBox(height: 16),
                Text(
                  '正在读取设备配置...',
                  style: TextStyle(color: Color(0xFF5A7A9A), fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 错误状态
    if (_error != null) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7FF),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4A90D9).withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  '读取配置失败',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D4A6F),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5A7A9A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _error = null;
                    });
                    _loadNodeConfig();
                  },
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F7FF),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4A90D9).withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                Row(
                  children: [
                    const Icon(
                      Icons.settings_input_component,
                      color: Color(0xFF4A90D9),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '配置子设备参数',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D4A6F),
                            ),
                          ),
                          Text(
                            widget.device.mac,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF5A7A9A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF7A9CC6)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: const Color(0xFFE8F2FF)),
                const SizedBox(height: 16),

                // 串口参数
                _buildSectionTitle('串口参数', Icons.settings_input_component),
                const SizedBox(height: 12),

                // 波特率
                _buildLabel('波特率'),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _baudLevel,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 0x00, child: Text('1200')),
                        DropdownMenuItem(value: 0x01, child: Text('2400')),
                        DropdownMenuItem(value: 0x02, child: Text('4800')),
                        DropdownMenuItem(value: 0x03, child: Text('9600')),
                        DropdownMenuItem(value: 0x04, child: Text('19200')),
                        DropdownMenuItem(value: 0x05, child: Text('38400')),
                        DropdownMenuItem(value: 0x06, child: Text('57600')),
                        DropdownMenuItem(value: 0x07, child: Text('115200')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _baudLevel = value);
                          _markChanged();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 数据位、停止位、校验位
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdownField('数据位', _dataBits, [
                        7,
                        8,
                      ], (v) => _dataBits = v),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDropdownField('停止位', _stopBits, [
                        1,
                        2,
                      ], (v) => _stopBits = v),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: _buildParityDropdown()),
                  ],
                ),
                const SizedBox(height: 16),

                // Modbus 配置
                _buildSectionTitle('Modbus 配置', Icons.memory),
                const SizedBox(height: 8),
                _buildModbusConfig(),
                const SizedBox(height: 20),

                // 按钮
                Row(
                  children: [
                    Expanded(
                      child: _DialogButton(
                        label: '取消',
                        isPrimary: false,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DialogButton(
                        label: '保存配置',
                        isPrimary: true,
                        onPressed: _hasChanges && !_isLoading ? _submit : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF4A90D9), size: 16),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D4A6F),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, color: Color(0xFF5A7A9A)),
    );
  }

  Widget _buildDropdownField(
    String label,
    int value,
    List<int> items,
    Function(int) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => onChanged(v));
                  _markChanged();
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('校验位'),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _parity,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: DtuProtocol.PARITY_NONE,
                  child: Text('无'),
                ),
                DropdownMenuItem(
                  value: DtuProtocol.PARITY_ODD,
                  child: Text('奇'),
                ),
                DropdownMenuItem(
                  value: DtuProtocol.PARITY_EVEN,
                  child: Text('偶'),
                ),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _parity = v;
                  });
                  _markChanged();
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModbusConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Modbus 设备列表
        ..._modbusItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return _buildModbusItem(index, item);
        }),
        const SizedBox(height: 8),
        // 添加按钮
        GestureDetector(
          onTap: _modbusItems.length < 8
              ? () {
                  setState(() {
                    _modbusItems.add(
                      ModbusItem(addr: _modbusItems.length + 1, devType: 0x05),
                    );
                    _syncModbusControllers();
                    _markChanged();
                  });
                }
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: _modbusItems.length < 8
                  ? const Color(0xFFF0F7FF)
                  : const Color(0xFFEDEDED),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF4A90D9),
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Text(
                _modbusItems.length < 8 ? '+ 添加 Modbus 设备' : '已达到最大数量',
                style: TextStyle(
                  color: _modbusItems.length < 8
                      ? const Color(0xFF4A90D9)
                      : const Color(0xFF9AA8C3),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModbusItem(int index, ModbusItem item) {
    final addrController = _addrControllers[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8F2FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '设备 ${index + 1}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D4A6F),
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (_modbusItems.length > 1) {
                    setState(() {
                      _modbusItems.removeAt(index);
                      _syncModbusControllers();
                      _markChanged();
                    });
                  }
                },
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Color(0xFFE85C5C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('从站地址 (1-247)'),
                    const SizedBox(height: 4),
                    TextField(
                      controller: addrController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                      onChanged: (v) {
                        final addr = int.tryParse(v);
                        if (addr != null && addr >= 1 && addr <= 247) {
                          setState(() {
                            _modbusItems[index] = ModbusItem(
                              addr: addr,
                              devType: item.devType,
                            );
                          });
                          _markChanged();
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('设备类型'),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: item.devType,
                          isExpanded: true,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF2D4A6F),
                          ),
                          items: DtuProtocol.deviceTypeNames.entries.map((e) {
                            return DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() {
                                _modbusItems[index] = ModbusItem(
                                  addr: item.addr,
                                  devType: v,
                                );
                                _markChanged();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 二维码扫描对话框
class QRScannerDialog extends StatefulWidget {
  const QRScannerDialog({super.key});

  @override
  State<QRScannerDialog> createState() => _QRScannerDialogState();
}

class _QRScannerDialogState extends State<QRScannerDialog> {
  MobileScannerController? _controller;
  bool _hasScanned = false;
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
        setState(() => _isInitializing = false);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final value = barcode.rawValue;
      if (value == null) continue;

      debugPrint('[QRScanner] 扫描到内容: $value');
      final result = QRScanResult.fromString(value);
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
                        Text(
                          '正在启动摄像头...',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  )
                else if (_controller != null)
                  MobileScanner(controller: _controller!, onDetect: _onDetect)
                else
                  const Center(
                    child: Text(
                      '摄像头启动失败',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                // 扫描框
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
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
            child: const Text(
              '请扫描设备上的蓝牙二维码',
              style: TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// 添加设备对话框（V2: 仅 MAC 地址，不再输入设备名称）
class AddDeviceDialog extends StatefulWidget {
  final Function(String mac, String name) onDeviceAdded;

  const AddDeviceDialog({super.key, required this.onDeviceAdded});

  @override
  State<AddDeviceDialog> createState() => _AddDeviceDialogState();
}

class _AddDeviceDialogState extends State<AddDeviceDialog> {
  final _macController = TextEditingController();
  String? _macError;
  bool _fromQRCode = false;

  @override
  void dispose() {
    _macController.dispose();
    super.dispose();
  }

  void _showQRScanner() async {
    final result = await showDialog<QRScanResult>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) => const QRScannerDialog(),
    );

    if (result != null) {
      _onQRCodeScanned(result);
    }
  }

  void _onQRCodeScanned(QRScanResult result) {
    setState(() {
      _macController.text = result.mac;
      _fromQRCode = true;
      _macError = null;
    });
  }

  bool _isValidMacAddress(String mac) {
    if (mac.isEmpty) return false;
    final macRegex = RegExp(r'^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$');
    return macRegex.hasMatch(mac);
  }

  void _submit() {
    final mac = _macController.text.trim();

    setState(() {
      _macError = !_isValidMacAddress(mac) ? '格式错误，应为 XX:XX:XX:XX:XX:XX' : null;
    });

    if (!_isValidMacAddress(mac)) return;

    // V2: name 等同于 mac
    widget.onDeviceAdded(mac, mac);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F7FF),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4A90D9).withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Row(
                children: [
                  const Icon(
                    Icons.add_circle_outline,
                    color: Color(0xFF4A90D9),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '添加子设备到白名单',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D4A6F),
                      ),
                    ),
                  ),
                  // 扫码按钮
                  GestureDetector(
                    onTap: _showQRScanner,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A90D9).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF4A90D9)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.qr_code_scanner,
                            color: Color(0xFF4A90D9),
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '扫码',
                            style: TextStyle(
                              color: Color(0xFF4A90D9),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(height: 1, color: const Color(0xFFE8F2FF)),
              const SizedBox(height: 16),

              // 基本信息
              _buildSectionTitle('基本信息', Icons.info_outline),
              const SizedBox(height: 12),

              // MAC 地址
              _buildLabel('MAC 地址'),
              const SizedBox(height: 6),
              TextField(
                controller: _macController,
                style: const TextStyle(fontSize: 14, letterSpacing: 1),
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'AA:BB:CC:DD:EE:FF',
                  isDense: true,
                  filled: true,
                  fillColor: _fromQRCode
                      ? const Color(0xFFE8F9F0)
                      : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: _macError != null
                          ? Colors.red
                          : Colors.transparent,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: _macError != null
                          ? Colors.red.shade200
                          : const Color(0xFFE8F9F0),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: _macError != null
                          ? Colors.red
                          : const Color(0xFF4A90D9),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  suffixIcon: _fromQRCode
                      ? const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                        )
                      : null,
                ),
              ),
              if (_macError != null) ...[
                const SizedBox(height: 4),
                Text(
                  _macError!,
                  style: const TextStyle(color: Colors.red, fontSize: 11),
                ),
              ],
              if (_fromQRCode) ...[
                const SizedBox(height: 4),
                const Text(
                  '✓ 已通过二维码扫描填充',
                  style: TextStyle(color: Colors.green, fontSize: 11),
                ),
              ],
              const SizedBox(height: 24),

              // 提示
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFFFFA000),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '添加后可在设备详情中配置串口参数和Modbus地址',
                        style: TextStyle(
                          color: Color(0xFF795548),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 按钮
              Row(
                children: [
                  Expanded(
                    child: _DialogButton(
                      label: '取消',
                      isPrimary: false,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DialogButton(
                      label: '确认添加',
                      isPrimary: true,
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF4A90D9), size: 16),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D4A6F),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, color: Color(0xFF5A7A9A)),
    );
  }
}

class DeviceListPage extends StatefulWidget {
  final bool isConnected;
  final DtuService dtuService;

  const DeviceListPage({
    super.key,
    required this.isConnected,
    required this.dtuService,
  });

  @override
  State<DeviceListPage> createState() => _DeviceListPageState();
}

class _DeviceListPageState extends State<DeviceListPage> {
  // 协议服务
  DtuService get _service => widget.dtuService;

  // 白名单数据
  List<WhiteListItem> _devices = [];
  bool _isLoading = false;
  bool _isSelectionMode = false;
  final Set<String> _selectedMacs = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadWhiteList();
  }

  List<WhiteListItem> get _filteredDevices {
    if (_searchQuery.isEmpty) return _devices;
    final query = _searchQuery.toLowerCase();
    return _devices.where((device) {
      return device.mac.toLowerCase().contains(query);
    }).toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  Future<void> _loadWhiteList() async {
    if (!widget.isConnected) return;

    setState(() => _isLoading = true);

    try {
      final items = await _service.readWhiteList();
      setState(() => _devices = items);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('读取白名单失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addDevice(String mac, String name) async {
    if (!widget.isConnected) return;

    // 检查是否为 ROOT 设备
    if (!_service.isRoot) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('只有 ROOT 设备才能添加白名单'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final item = WhiteListItem(mac: mac, name: mac); // V2: name = mac
      await _service.addWhiteListItemFull(item);

      // 提交保存
      await _service.commit();
      await _loadWhiteList();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加成功: $mac'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        // 提取错误消息
        String errorMsg = e.toString();
        if (errorMsg.contains('操作失败:')) {
          errorMsg = errorMsg
              .split('操作失败:')
              .last
              .replaceAll('FormatException: ', '');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('添加失败: $errorMsg'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteDevice(String mac) async {
    if (!widget.isConnected) return;

    if (!_service.isRoot) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('只有 ROOT 设备才能删除白名单'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _service.delWhiteListItem(mac);
      await _service.commit();
      await _loadWhiteList();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除成功'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        if (errorMsg.contains('操作失败:')) {
          errorMsg = errorMsg
              .split('操作失败:')
              .last
              .replaceAll('FormatException: ', '');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除失败: $errorMsg'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedMacs.clear();
      }
    });
  }

  void _toggleDeviceSelection(String mac) {
    setState(() {
      if (_selectedMacs.contains(mac)) {
        _selectedMacs.remove(mac);
      } else {
        _selectedMacs.add(mac);
      }
    });
  }

  void _showDeleteSelectedConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF0F7FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          '确认删除',
          style: TextStyle(
            color: Color(0xFF2D4A6F),
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '确定要删除已选 ${_selectedMacs.length} 个设备吗？',
          style: const TextStyle(color: Color(0xFF5A7A9A), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: Color(0xFF5A7A9A))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSelectedDevices();
            },
            child: const Text('删除', style: TextStyle(color: Color(0xFFE85C5C))),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelectedDevices() async {
    if (!widget.isConnected) return;

    if (!_service.isRoot) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('只有 ROOT 设备才能删除白名单'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (_selectedMacs.isEmpty) return;

    final selected = _selectedMacs.toList();
    final failed = <String>[];
    var successCount = 0;

    setState(() => _isLoading = true);

    try {
      for (final mac in selected) {
        try {
          await _service.delWhiteListItem(mac);
          successCount += 1;
        } catch (_) {
          failed.add(mac);
        }
      }

      if (successCount > 0) {
        await _service.commit();
      }

      await _loadWhiteList();

      if (mounted) {
        if (failed.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已删除 $successCount 个设备'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已删除 $successCount 个设备，${failed.length} 个删除失败'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } finally {
      setState(() {
        _isLoading = false;
        _isSelectionMode = false;
        _selectedMacs.clear();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _clearAll() async {
    if (!widget.isConnected) return;

    if (!_service.isRoot) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('只有 ROOT 设备才能清空白名单'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _service.clearWhiteList();
      await _service.commit();
      setState(() {
        _devices = [];
        _selectedMacs.clear();
        _isSelectionMode = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已清空全部'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        if (errorMsg.contains('操作失败:')) {
          errorMsg = errorMsg
              .split('操作失败:')
              .last
              .replaceAll('FormatException: ', '');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('清空失败: $errorMsg'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(
                    child: Text(
                      '子设备白名单',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D4A6F),
                      ),
                    ),
                  ),
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        alignment: WrapAlignment.end,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              if (_devices.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('当前没有设备可清空'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              _showClearAllDialog(context);
                            },
                            icon: Icon(
                              Icons.delete_sweep,
                              size: 18,
                              color: widget.isConnected
                                  ? const Color(0xFFE85C5C)
                                  : const Color(0xFFA0BCD6),
                            ),
                            label: Text(
                              '清空全部',
                              style: TextStyle(
                                fontSize: 13,
                                color: widget.isConnected
                                    ? const Color(0xFFE85C5C)
                                    : const Color(0xFFA0BCD6),
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: (_devices.isEmpty || !widget.isConnected)
                                ? null
                                : _toggleSelectionMode,
                            icon: Icon(
                              _isSelectionMode ? Icons.close : Icons.checklist,
                              size: 18,
                              color: (_devices.isEmpty || !widget.isConnected)
                                  ? const Color(0xFFA0BCD6)
                                  : const Color(0xFF4A90D9),
                            ),
                            label: Text(
                              _isSelectionMode ? '取消选择' : '批量操作',
                              style: TextStyle(
                                fontSize: 13,
                                color: (_devices.isEmpty || !widget.isConnected)
                                    ? const Color(0xFFA0BCD6)
                                    : const Color(0xFF4A90D9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: '搜索 MAC 地址',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        ),
                  filled: true,
                  fillColor: const Color(0xFFF5F7FB),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Text(
                        '已选 ${_selectedMacs.length} 项',
                        style: const TextStyle(
                          color: Color(0xFF2D4A6F),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _selectedMacs.isEmpty
                            ? null
                            : () => _showDeleteSelectedConfirmDialog(context),
                        child: Text(
                          '删除所选',
                          style: TextStyle(
                            fontSize: 13,
                            color: _selectedMacs.isEmpty
                                ? const Color(0xFFA0BCD6)
                                : const Color(0xFFE85C5C),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              if (_devices.isEmpty && !_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.devices_other,
                          size: 48,
                          color: Color(0xFFA0BCD6),
                        ),
                        SizedBox(height: 12),
                        Text(
                          '暂无子设备',
                          style: TextStyle(
                            color: Color(0xFFA0BCD6),
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '点击 + 添加设备',
                          style: TextStyle(
                            color: Color(0xFFA0BCD6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_filteredDevices.isEmpty && !_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: Color(0xFFA0BCD6),
                        ),
                        SizedBox(height: 12),
                        Text(
                          '未找到匹配的设备',
                          style: TextStyle(
                            color: Color(0xFFA0BCD6),
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '请尝试其他名称或 MAC',
                          style: TextStyle(
                            color: Color(0xFFA0BCD6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadWhiteList,
                    child: ListView.builder(
                      itemCount: _filteredDevices.length,
                      itemBuilder: (context, index) {
                        final device = _filteredDevices[index];
                        return _buildDeviceCard(
                          context,
                          index + 1,
                          device,
                        );
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              // 添加按钮
              _buildAddButton(context),
              const SizedBox(height: 12),
            ],
          ),
        ),

        // 加载遮罩
        if (_isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.2),
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF4A90D9)),
            ),
          ),
      ],
    );
  }

  Widget _buildDeviceCard(
    BuildContext context,
    int slot,
    WhiteListItem device,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A90D9).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: GestureDetector(
          onTap: _isSelectionMode ? () => _toggleDeviceSelection(device.mac) : null,
          child: Row(
            children: [
              if (_isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _selectedMacs.contains(device.mac),
                      onChanged: (_) => _toggleDeviceSelection(device.mac),
                      activeColor: const Color(0xFF4A90D9),
                    ),
                  ),
                ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '#$slot',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A90D9),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      device.mac,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D4A6F),
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isSelectionMode) ...[
                GestureDetector(
                  onTap: () => _showChildNodeConfigDialog(context, device),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F2FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.settings_input_component,
                      color: Color(0xFF4A90D9),
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showDeleteConfirmDialog(context, device),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE8E8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFE85C5C),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: widget.isConnected && !_isLoading
          ? () => _showAddDeviceDialog(context)
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: widget.isConnected
              ? const Color(0xFF4A90D9).withValues(alpha: 0.1)
              : const Color(0xFFE8F2FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isConnected
                ? const Color(0xFF4A90D9)
                : const Color(0xFFE8F2FF),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              color: widget.isConnected
                  ? const Color(0xFF4A90D9)
                  : const Color(0xFFA0BCD6),
            ),
            const SizedBox(width: 8),
            Text(
              '添加设备到白名单',
              style: TextStyle(
                color: widget.isConnected
                    ? const Color(0xFF4A90D9)
                    : const Color(0xFFA0BCD6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF0F7FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          '清空全部设备',
          style: TextStyle(
            color: Color(0xFF2D4A6F),
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          '确定要清空所有已添加的设备吗？此操作无法撤销。',
          style: TextStyle(color: Color(0xFF5A7A9A), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: Color(0xFF5A7A9A))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAll();
            },
            child: const Text('清空', style: TextStyle(color: Color(0xFFE85C5C))),
          ),
        ],
      ),
    );
  }

  void _showAddDeviceDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return AddDeviceDialog(onDeviceAdded: _addDevice);
      },
    );
  }

  void _showChildNodeConfigDialog(BuildContext context, WhiteListItem device) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return ChildNodeConfigDialog(
          device: device,
          onConfigSaved: _onChildNodeConfigSaved,
          onLoadNodeConfig: (mac) => _service.readChildNodeConfig(mac),
        );
      },
    );
  }

  Future<void> _onChildNodeConfigSaved(WhiteListItem device) async {
    if (!widget.isConnected) return;

    setState(() => _isLoading = true);

    try {
      await _service.setChildNodeConfig(device);
      await _service.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('配置已保存: ${device.mac}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('配置失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showDeleteConfirmDialog(BuildContext context, WhiteListItem device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF0F7FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          '确认删除',
          style: TextStyle(
            color: Color(0xFF2D4A6F),
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '确定要删除 "$device.mac" 吗？',
          style: const TextStyle(color: Color(0xFF5A7A9A), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: Color(0xFF5A7A9A))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteDevice(device.mac);
            },
            child: const Text('删除', style: TextStyle(color: Color(0xFFE85C5C))),
          ),
        ],
      ),
    );
  }
}

class _DialogButton extends StatefulWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback? onPressed;

  const _DialogButton({
    required this.label,
    required this.isPrimary,
    this.onPressed,
  });

  @override
  State<_DialogButton> createState() => _DialogButtonState();
}

class _DialogButtonState extends State<_DialogButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: widget.isPrimary
              ? (_isPressed ? const Color(0xFF3A80C9) : const Color(0xFF4A90D9))
              : (_isPressed ? const Color(0xFFF0F7FF) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: widget.isPrimary
              ? null
              : Border.all(color: const Color(0xFF4A90D9), width: 1.5),
          boxShadow: widget.isPrimary
              ? [
                  BoxShadow(
                    color: const Color(0xFF4A90D9).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          widget.label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: widget.isPrimary ? Colors.white : const Color(0xFF4A90D9),
          ),
        ),
      ),
    );
  }
}
