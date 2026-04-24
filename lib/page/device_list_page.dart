import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../protocol/protocol.dart';

/// 二维码扫描结果模型
class QRScanResult {
  final String name;
  final String mac;
  final String role;

  QRScanResult({
    required this.name,
    required this.mac,
    required this.role,
  });

  /// 从JSON字符串解析二维码内容
  static QRScanResult? fromJson(String jsonString) {
    try {
      final map = json.decode(jsonString) as Map<String, dynamic>;
      final name = map['name'] as String?;
      final mac = map['mac'] as String?;
      final role = map['role'] as String?;

      if (name == null || name.isEmpty) return null;
      if (mac == null || mac.isEmpty) return null;

      return QRScanResult(
        name: name,
        mac: mac,
        role: role ?? 'unknown',
      );
    } catch (e) {
      return null;
    }
  }

  /// 验证MAC地址格式
  static bool isValidMac(String mac) {
    final macRegex = RegExp(r'^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$');
    return macRegex.hasMatch(mac);
  }
}

/// 子设备参数配置对话框
class ChildNodeConfigDialog extends StatefulWidget {
  final WhiteListItem device;
  final Function(WhiteListItem) onConfigSaved;

  const ChildNodeConfigDialog({
    super.key,
    required this.device,
    required this.onConfigSaved,
  });

  @override
  State<ChildNodeConfigDialog> createState() => _ChildNodeConfigDialogState();
}

class _ChildNodeConfigDialogState extends State<ChildNodeConfigDialog> {
  late int _baudLevel;
  late int _dataBits;
  late int _stopBits;
  late int _parity;
  late List<TextEditingController> _modbusControllers;

  @override
  void initState() {
    super.initState();
    _baudLevel = widget.device.baudLevel;
    _dataBits = widget.device.dataBits;
    _stopBits = widget.device.stopBits;
    _parity = widget.device.parity;
    _modbusControllers = List.generate(8, (i) {
      final addr = i < widget.device.modbusAddresses.length 
          ? widget.device.modbusAddresses[i] 
          : i + 1;
      return TextEditingController(text: addr.toString());
    });
  }

  @override
  void dispose() {
    for (final controller in _modbusControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final modbusAddresses = <int>[];
    for (final controller in _modbusControllers) {
      final text = controller.text.trim();
      if (text.isNotEmpty) {
        final addr = int.tryParse(text);
        if (addr != null && addr > 0 && addr <= 247) {
          modbusAddresses.add(addr);
        }
      }
    }

    final updatedDevice = widget.device.copyWithFull(
      baudLevel: _baudLevel,
      dataBits: _dataBits,
      stopBits: _stopBits,
      parity: _parity,
      modbusAddresses: modbusAddresses,
    );

    widget.onConfigSaved(updatedDevice);
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                Row(
                  children: [
                    const Icon(Icons.settings_input_component, color: Color(0xFF4A90D9), size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '配置子设备参数',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D4A6F)),
                          ),
                          Text(
                            widget.device.name,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF5A7A9A)),
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
                        if (value != null) setState(() => _baudLevel = value);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 数据位、停止位、校验位
                Row(
                  children: [
                    Expanded(child: _buildDropdownField('数据位', _dataBits, [7, 8], (v) => _dataBits = v)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildDropdownField('停止位', _stopBits, [1, 2], (v) => _stopBits = v)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildParityDropdown()),
                  ],
                ),
                const SizedBox(height: 16),

                // Modbus 配置
                _buildSectionTitle('Modbus 从站地址', Icons.hub),
                const SizedBox(height: 4),
                Text('设置子设备挂载的 Modbus 从机地址', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                const SizedBox(height: 12),

                // Modbus 地址网格
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 8,
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE8F2FF)),
                      ),
                      child: TextField(
                        controller: _modbusControllers[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: '1-247',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // 按钮
                Row(
                  children: [
                    Expanded(child: _DialogButton(label: '取消', isPrimary: false, onPressed: () => Navigator.pop(context))),
                    const SizedBox(width: 12),
                    Expanded(child: _DialogButton(label: '保存配置', isPrimary: true, onPressed: _submit)),
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
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2D4A6F))),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF5A7A9A)));
  }

  Widget _buildDropdownField(String label, int value, List<int> items, Function(int) onChanged) {
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
              items: items.map((e) => DropdownMenuItem(value: e, child: Text('$e'))).toList(),
              onChanged: (v) {
                if (v != null) setState(() => onChanged(v));
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
                DropdownMenuItem(value: DtuProtocol.PARITY_NONE, child: Text('无')),
                DropdownMenuItem(value: DtuProtocol.PARITY_ODD, child: Text('奇')),
                DropdownMenuItem(value: DtuProtocol.PARITY_EVEN, child: Text('偶')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _parity = v);
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// 二维码扫描对话框
class QRScannerDialog extends StatefulWidget {
  final Function(QRScanResult) onScanned;

  const QRScannerDialog({super.key, required this.onScanned});

  @override
  State<QRScannerDialog> createState() => _QRScannerDialogState();
}

class _QRScannerDialogState extends State<QRScannerDialog> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null) {
        final result = QRScanResult.fromJson(rawValue);
        if (result != null && QRScanResult.isValidMac(result.mac)) {
          setState(() => _hasScanned = true);
          Navigator.pop(context);
          widget.onScanned(result);
          return;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 300,
        height: 380,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F7FF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF4A90D9),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_scanner, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '扫描设备二维码',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // 扫描区域
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF4A90D9), width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: MobileScanner(
                      controller: _controller,
                      onDetect: _onDetect,
                    ),
                  ),
                ),
              ),
            ),
            // 提示文字
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                '请扫描设备上的二维码',
                style: TextStyle(color: Color(0xFF5A7A9A), fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 添加设备对话框（基础版：只填写名称和MAC）
class AddDeviceDialog extends StatefulWidget {
  final Function(String name, String mac) onDeviceAdded;

  const AddDeviceDialog({super.key, required this.onDeviceAdded});

  @override
  State<AddDeviceDialog> createState() => _AddDeviceDialogState();
}

class _AddDeviceDialogState extends State<AddDeviceDialog> {
  final _nameController = TextEditingController();
  final _macController = TextEditingController();
  String? _nameError;
  String? _macError;
  bool _fromQRCode = false;

  void _showQRScanner() {
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
        return QRScannerDialog(
          onScanned: _onQRCodeScanned,
        );
      },
    );
  }

  void _onQRCodeScanned(QRScanResult result) {
    setState(() {
      _nameController.text = result.name;
      _macController.text = result.mac;
      _fromQRCode = true;
      _nameError = null;
      _macError = null;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _macController.dispose();
    super.dispose();
  }

  bool _isValidMacAddress(String mac) {
    if (mac.isEmpty) return false;
    final macRegex = RegExp(r'^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$');
    return macRegex.hasMatch(mac);
  }

  void _submit() {
    final name = _nameController.text.trim();
    final mac = _macController.text.trim();

    setState(() {
      _nameError = name.isEmpty ? '请输入设备名称' : null;
      _macError = !_isValidMacAddress(mac) ? '格式错误，应为 XX:XX:XX:XX:XX:XX' : null;
    });

    if (name.isEmpty || !_isValidMacAddress(mac)) return;

    widget.onDeviceAdded(name, mac);
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                Row(
                  children: [
                    const Icon(Icons.add_circle_outline, color: Color(0xFF4A90D9), size: 22),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '添加子设备',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D4A6F)),
                      ),
                    ),
                    // 扫码按钮
                    GestureDetector(
                      onTap: _showQRScanner,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A90D9).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF4A90D9)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.qr_code_scanner, color: Color(0xFF4A90D9), size: 16),
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

                // 基础信息
                _buildSectionTitle('基本信息', Icons.info_outline),
                const SizedBox(height: 12),

                // 设备名称
                _buildLabel('设备名称'),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '请输入设备名称',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _nameError != null ? Colors.red : Colors.transparent)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _nameError != null ? Colors.red.shade200 : Colors.transparent)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _nameError != null ? Colors.red : const Color(0xFF4A90D9))),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                if (_nameError != null) ...[
                  const SizedBox(height: 4),
                  Text(_nameError!, style: const TextStyle(color: Colors.red, fontSize: 11)),
                ],
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
                    fillColor: _fromQRCode ? const Color(0xFFE8F9F0) : Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _macError != null ? Colors.red : Colors.transparent)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _macError != null ? Colors.red.shade200 : const Color(0xFFE8F9F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _macError != null ? Colors.red : const Color(0xFF4A90D9))),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    suffixIcon: _fromQRCode
                        ? const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(Icons.check_circle, color: Colors.green, size: 20),
                          )
                        : null,
                  ),
                ),
                if (_macError != null) ...[
                  const SizedBox(height: 4),
                  Text(_macError!, style: const TextStyle(color: Colors.red, fontSize: 11)),
                ],
                if (_fromQRCode) ...[
                  const SizedBox(height: 4),
                  const Text(
                    '✓ 已通过二维码扫描填充',
                    style: TextStyle(color: Colors.green, fontSize: 11),
                  ),
                ],
                const SizedBox(height: 20),

                // 按钮
                Row(
                  children: [
                    Expanded(child: _DialogButton(label: '取消', isPrimary: false, onPressed: () => Navigator.pop(context))),
                    const SizedBox(width: 12),
                    Expanded(child: _DialogButton(label: '确认添加', isPrimary: true, onPressed: _submit)),
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
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2D4A6F))),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF5A7A9A)));
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

  @override
  void initState() {
    super.initState();
    _loadWhiteList();
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

  Future<void> _addDevice(String name, String mac) async {
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
      await _service.addWhiteListItem(mac, name);
      await _service.commit();
      await _loadWhiteList();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('添加成功: $name'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // 提取错误消息
        String errorMsg = e.toString();
        if (errorMsg.contains('操作失败:')) {
          errorMsg = errorMsg.split('操作失败:').last.replaceAll('FormatException: ', '');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败: $errorMsg'), backgroundColor: Colors.red),
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
          errorMsg = errorMsg.split('操作失败:').last.replaceAll('FormatException: ', '');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $errorMsg'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
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
      setState(() => _devices = []);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已清空全部'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        if (errorMsg.contains('操作失败:')) {
          errorMsg = errorMsg.split('操作失败:').last.replaceAll('FormatException: ', '');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('清空失败: $errorMsg'), backgroundColor: Colors.red),
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
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '子设备白名单',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D4A6F),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: widget.isConnected && !_isLoading && _devices.isNotEmpty
                        ? () => _showClearAllDialog(context)
                        : null,
                    icon: Icon(
                      Icons.delete_sweep,
                      size: 18,
                      color: widget.isConnected ? const Color(0xFFE85C5C) : const Color(0xFFA0BCD6),
                    ),
                    label: Text(
                      '清空全部',
                      style: TextStyle(
                        fontSize: 13,
                        color: widget.isConnected ? const Color(0xFFE85C5C) : const Color(0xFFA0BCD6),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_devices.isEmpty && !_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.devices_other, size: 48, color: Color(0xFFA0BCD6)),
                        SizedBox(height: 12),
                        Text(
                          '暂无子设备',
                          style: TextStyle(color: Color(0xFFA0BCD6), fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '点击 + 添加设备',
                          style: TextStyle(color: Color(0xFFA0BCD6), fontSize: 12),
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
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        return _buildDeviceCard(context, index + 1, _devices[index]);
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              // 添加按钮
              if (_devices.length < 8)
                _buildAddButton(context),
              const SizedBox(height: 20),
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

  Widget _buildDeviceCard(BuildContext context, int slot, WhiteListItem device) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
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
                    device.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D4A6F),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    device.mac,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF5A7A9A),
                    ),
                  ),
                ],
              ),
            ),
            // 配置按钮
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
            // 删除按钮
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
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: widget.isConnected && !_isLoading ? () => _showAddDeviceDialog(context) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: widget.isConnected
              ? const Color(0xFF4A90D9).withValues(alpha: 0.1)
              : const Color(0xFFE8F2FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isConnected ? const Color(0xFF4A90D9) : const Color(0xFFE8F2FF),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              color: widget.isConnected ? const Color(0xFF4A90D9) : const Color(0xFFA0BCD6),
            ),
            const SizedBox(width: 8),
            Text(
              '添加设备到白名单',
              style: TextStyle(
                color: widget.isConnected ? const Color(0xFF4A90D9) : const Color(0xFFA0BCD6),
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
        title: const Text('清空全部设备', style: TextStyle(color: Color(0xFF2D4A6F), fontSize: 15, fontWeight: FontWeight.bold)),
        content: const Text('确定要清空所有已添加的设备吗？此操作无法撤销。', style: TextStyle(color: Color(0xFF5A7A9A), fontSize: 13)),
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
        return AddDeviceDialog(
          onDeviceAdded: _addDevice,
        );
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
            content: Text('配置已保存: ${device.name}'),
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
        title: const Text('确认删除', style: TextStyle(color: Color(0xFF2D4A6F), fontSize: 15, fontWeight: FontWeight.bold)),
        content: Text('确定要删除 "${device.name}" 吗？', style: const TextStyle(color: Color(0xFF5A7A9A), fontSize: 13)),
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
  final VoidCallback onPressed;

  const _DialogButton({required this.label, required this.isPrimary, required this.onPressed});

  @override
  State<_DialogButton> createState() => _DialogButtonState();
}

class _DialogButtonState extends State<_DialogButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: widget.isPrimary
              ? (_isPressed ? const Color(0xFF3A80C9) : const Color(0xFF4A90D9))
              : (_isPressed ? const Color(0xFFF0F7FF) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: widget.isPrimary ? null : Border.all(color: const Color(0xFF4A90D9), width: 1.5),
          boxShadow: widget.isPrimary
              ? [BoxShadow(color: const Color(0xFF4A90D9).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]
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
