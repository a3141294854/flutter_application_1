import 'package:flutter/material.dart';
import '../protocol/protocol.dart';

class ChildSettingsPage extends StatefulWidget {
  final bool isConnected;
  final DtuService dtuService;

  const ChildSettingsPage({
    super.key,
    required this.isConnected,
    required this.dtuService,
  });

  @override
  State<ChildSettingsPage> createState() => _ChildSettingsPageState();
}

class _ChildSettingsPageState extends State<ChildSettingsPage> {
  // 协议服务
  DtuService get _service => widget.dtuService;

  // 串口配置
  int _baudLevel = 0x03;
  int _dataBits = 0x08;
  int _parity = DtuProtocol.PARITY_NONE;
  int _stopBits = DtuProtocol.STOP_BITS_1;

  // Modbus 配置
  final List<int> _modbusAddresses = [1, 2, 3, 4, 5, 6, 7, 8];
  final List<int> _modbusDeviceTypes = [5, 5, 5, 5, 5, 5, 5, 5]; // 默认: 5=保留

  bool _isLoading = false;
  bool _hasChanges = false;

  // 配置列表
  final List<Map<String, dynamic>> _baudRates = [
    {'label': '1200', 'value': 0x00},
    {'label': '2400', 'value': 0x01},
    {'label': '4800', 'value': 0x02},
    {'label': '9600', 'value': 0x03},
    {'label': '19200', 'value': 0x04},
    {'label': '38400', 'value': 0x05},
    {'label': '57600', 'value': 0x06},
    {'label': '115200', 'value': 0x07},
  ];

  final List<String> _dataBitsList = ['7', '8'];
  final List<Map<String, dynamic>> _parityList = [
    {'label': 'None', 'value': DtuProtocol.PARITY_NONE},
    {'label': 'Odd', 'value': DtuProtocol.PARITY_ODD},
    {'label': 'Even', 'value': DtuProtocol.PARITY_EVEN},
  ];
  final List<String> _stopBitsList = ['1', '2'];

  final List<Map<String, dynamic>> _deviceTypeOptions = [
    {'label': '保留', 'value': 0},
    {'label': '三相电表', 'value': DtuProtocol.DEV_TYPE_THREE_PHASE_METER},
    {'label': '单相电表', 'value': DtuProtocol.DEV_TYPE_SINGLE_PHASE_METER},
    {'label': '温湿度变送器', 'value': DtuProtocol.DEV_TYPE_TEMP_HUMIDITY},
    {'label': '继电器', 'value': DtuProtocol.DEV_TYPE_RELAY},
  ];

  @override
  void initState() {
    super.initState();
    // 连接后自动读取配置（延迟执行以避免切换时崩溃）
    if (widget.isConnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _safeReadConfig();
      });
    }
  }

  Future<void> _safeReadConfig() async {
    try {
      await _readConfig();
    } catch (e) {
      // 忽略读取错误，页面仍然正常显示
      debugPrint('[child_settings] Initial config read failed, ignoring: $e');
    }
  }

  @override
  void didUpdateWidget(ChildSettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当连接状态从断开变为连接时，自动读取配置
    if (!oldWidget.isConnected && widget.isConnected) {
      _readConfig();
    }
  }

  Future<void> _readConfig() async {
    if (!widget.isConnected) return;

    setState(() => _isLoading = true);

    try {
      final config = await _service.readAllConfig();
      print('[child_settings] Got config, modbusConfig=${config.modbusConfig?.items.length ?? "null"}');

      setState(() {
        print('[child_settings] Inside setState callback');
        if (config.uartConfig != null) {
          _baudLevel = config.uartConfig!.baudLevel;
          _dataBits = config.uartConfig!.dataBits;
          _parity = config.uartConfig!.parity;
          _stopBits = config.uartConfig!.stopBits;
        }

        // 更新 Modbus 配置
        print('[child_settings] modbusConfig is null: ${config.modbusConfig == null}');
        if (config.modbusConfig != null) {
          print('[child_settings] Modbus config items count: ${config.modbusConfig!.items.length}');
          if (config.modbusConfig!.items.isEmpty) {
            print('[child_settings] Modbus items is empty, using default values');
          } else {
            for (int i = 0; i < config.modbusConfig!.items.length && i < 8; i++) {
              _modbusAddresses[i] = config.modbusConfig!.items[i].addr;
              _modbusDeviceTypes[i] = config.modbusConfig!.items[i].devType;
              print('[child_settings] Modbus[$i]: addr=${_modbusAddresses[i]}, type=${_modbusDeviceTypes[i]}');
            }
          }
        }
        print('[child_settings] After update: _modbusAddresses=$_modbusAddresses, _modbusDeviceTypes=$_modbusDeviceTypes');

        _hasChanges = false;
        print('[child_settings] setState completed');
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('配置读取成功'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('读取失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConfig() async {
    if (!widget.isConnected || !_hasChanges) return;

    setState(() => _isLoading = true);

    try {
      await _service.writeAllConfig(
        uartConfig: UartConfig(
          baudLevel: _baudLevel,
          parity: _parity,
          stopBits: _stopBits,
          dataBits: _dataBits,
        ),
        modbusConfig: ModbusConfig(
          items: List.generate(
            8,
            (i) => ModbusItem(addr: _modbusAddresses[i], devType: _modbusDeviceTypes[i]),
          ),
        ),
      );

      setState(() => _hasChanges = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('配置保存成功'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getBaudRateLabel() {
    return _baudRates.firstWhere((b) => b['value'] == _baudLevel, orElse: () => _baudRates[3])['label'] as String;
  }

  String _getParityLabel() {
    return _parityList.firstWhere((p) => p['value'] == _parity, orElse: () => _parityList[0])['label'] as String;
  }

  String _getDeviceTypeLabel(int type) {
    return _deviceTypeOptions.firstWhere((d) => d['value'] == type, orElse: () => _deviceTypeOptions[0])['label'] as String;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFFF9800), borderRadius: BorderRadius.circular(12)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.device_hub, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text('子节点', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('参数配置', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2D4A6F))),
                  const Spacer(),
                  if (_hasChanges)
                    TextButton.icon(
                      onPressed: _isLoading ? null : _saveConfig,
                      icon: const Icon(Icons.save, size: 16),
                      label: const Text('保存'),
                    ),
                  IconButton(
                    onPressed: _isLoading ? null : _readConfig,
                    icon: _isLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Modbus 预设
              _buildModbusSection(),
              const SizedBox(height: 10),

              // 串口参数
              _buildUartSection(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModbusSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: const Color(0xFF4A90D9).withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Modbus 地址预设', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2D4A6F))),
                GestureDetector(
                  onTap: widget.isConnected ? _resetModbusAddresses : null,
                  child: Text('重置默认', style: TextStyle(color: widget.isConnected ? const Color(0xFF4A90D9) : const Color(0xFFA0BCD6), fontSize: 11)),
                ),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFF0F7FF), margin: const EdgeInsets.symmetric(horizontal: 10)),
          Padding(
            padding: const EdgeInsets.all(10),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 6, mainAxisSpacing: 6, childAspectRatio: 1.0),
              itemCount: 8,
              itemBuilder: (context, index) => _buildModbusCard(index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('串口参数'),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: const Color(0xFF4A90D9).withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: [
              _buildParamRow('波特率', _getBaudRateLabel(), () => _showBaudRatePicker()),
              Container(height: 1, color: const Color(0xFFF0F7FF), margin: const EdgeInsets.symmetric(horizontal: 10)),
              _buildParamRow('数据位', '$_dataBits', () => _showDataBitsPicker()),
              Container(height: 1, color: const Color(0xFFF0F7FF), margin: const EdgeInsets.symmetric(horizontal: 10)),
              _buildParamRow('停止位', '$_stopBits', () => _showStopBitsPicker()),
              Container(height: 1, color: const Color(0xFFF0F7FF), margin: const EdgeInsets.symmetric(horizontal: 10)),
              _buildParamRow('校验位', _getParityLabel(), () => _showParityPicker()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2D4A6F))),
    );
  }

  Widget _buildModbusCard(int index) {
    final typeLabel = _getDeviceTypeLabel(_modbusDeviceTypes[index]);
    final isReserved = _modbusDeviceTypes[index] == DtuProtocol.DEV_TYPE_RESERVED;

    return GestureDetector(
      onTap: widget.isConnected ? () => _showAddressEditor(index) : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE8F2FF), width: 1),
          boxShadow: [BoxShadow(color: const Color(0xFF4A90D9).withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: const BoxDecoration(
                color: Color(0xFFF0F7FF),
                borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
              ),
              child: Text(typeLabel, textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: isReserved ? const Color(0xFFA0BCD6) : const Color(0xFF4A90D9)), overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              child: Center(child: Text('${_modbusAddresses[index]}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: widget.isConnected ? const Color(0xFF2D4A6F) : const Color(0xFFA0BCD6)))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParamRow(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: widget.isConnected && !_isLoading ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF2D4A6F))),
            Row(
              children: [
                Text(value, style: TextStyle(fontSize: 13, color: widget.isConnected ? const Color(0xFF4A90D9) : const Color(0xFFA0BCD6), fontWeight: FontWeight.w600)),
                Icon(Icons.chevron_right, color: widget.isConnected ? const Color(0xFF4A90D9) : const Color(0xFFA0BCD6), size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _resetModbusAddresses() {
    setState(() {
      _modbusAddresses.setAll(0, [1, 2, 3, 4, 5, 6, 7, 8]);
      _modbusDeviceTypes.setAll(0, [5, 5, 5, 5, 5, 5, 5, 5]); // 默认: 5=保留
      _hasChanges = true;
    });
    _sendModbusConfig(); // 实时发送
  }

  /// 实时发送串口配置到设备
  Future<void> _sendUartConfig() async {
    if (!widget.isConnected || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      await _service.writeUartConfig(UartConfig(
        baudLevel: _baudLevel,
        parity: _parity,
        stopBits: _stopBits,
        dataBits: _dataBits,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('串口配置已同步'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('串口配置失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 实时发送Modbus配置到设备
  Future<void> _sendModbusConfig() async {
    if (!widget.isConnected || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      await _service.writeModbusConfig(ModbusConfig(
        items: List.generate(8, (i) => ModbusItem(addr: _modbusAddresses[i], devType: _modbusDeviceTypes[i])),
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Modbus配置已同步'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Modbus配置失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showBaudRatePicker() {
    _showOptionsPicker('波特率', _baudRates.map((b) => b['label'] as String).toList(), _getBaudRateLabel(), (selected) async {
      final item = _baudRates.firstWhere((b) => b['label'] == selected);
      setState(() {
        _baudLevel = item['value'] as int;
        _hasChanges = true;
      });
      await _sendUartConfig();
    });
  }

  void _showDataBitsPicker() {
    _showOptionsPicker('数据位', _dataBitsList, '$_dataBits', (selected) async {
      setState(() {
        _dataBits = int.parse(selected);
        _hasChanges = true;
      });
      await _sendUartConfig();
    });
  }

  void _showStopBitsPicker() {
    _showOptionsPicker('停止位', _stopBitsList, '$_stopBits', (selected) async {
      setState(() {
        _stopBits = int.parse(selected);
        _hasChanges = true;
      });
      await _sendUartConfig();
    });
  }

  void _showParityPicker() {
    _showOptionsPicker('校验位', _parityList.map((p) => p['label'] as String).toList(), _getParityLabel(), (selected) async {
      final item = _parityList.firstWhere((p) => p['label'] == selected);
      setState(() {
        _parity = item['value'] as int;
        _hasChanges = true;
      });
      await _sendUartConfig();
    });
  }

  void _showOptionsPicker(String title, List<String> options, String currentValue, Future<void> Function(String) onChanged) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF0F7FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('选择 $title', style: const TextStyle(color: Color(0xFF2D4A6F), fontSize: 15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) => ListTile(
            dense: true,
            title: Text(option, style: const TextStyle(color: Color(0xFF2D4A6F), fontSize: 13)),
            trailing: option == currentValue ? const Icon(Icons.check, color: Color(0xFF4A90D9), size: 18) : null,
            onTap: () {
              onChanged(option);
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showAddressEditor(int index) {
    final addrController = TextEditingController(text: _modbusAddresses[index].toString());
    int selectedType = _modbusDeviceTypes[index];

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
        return StatefulBuilder(
          builder: (context, setDialogState) => Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: const Color(0xFF4A90D9).withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.settings_applications, color: Color(0xFF4A90D9), size: 20),
                        const SizedBox(width: 8),
                        const Text('Modbus 预设', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D4A6F))),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFE8F2FF), borderRadius: BorderRadius.circular(8)),
                          child: Text('#${index + 1}', style: const TextStyle(fontSize: 13, color: Color(0xFF4A90D9), fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(height: 1, color: const Color(0xFFE8F2FF)),
                    const SizedBox(height: 16),
                    const Row(children: [Icon(Icons.category, color: Color(0xFF4A90D9), size: 18), SizedBox(width: 8), Text('设备类型', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D4A6F)))]),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        children: _deviceTypeOptions.map((type) {
                          final isSelected = selectedType == type['value'];
                          return ListTile(
                            dense: true,
                            title: Text(type['label'] as String, style: const TextStyle(fontSize: 14)),
                            trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF4A90D9)) : null,
                            onTap: () => setDialogState(() => selectedType = type['value'] as int),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Row(children: [Icon(Icons.tag, color: Color(0xFF4A90D9), size: 18), SizedBox(width: 8), Text('Modbus 地址', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D4A6F)))]),
                    const SizedBox(height: 10),
                    TextField(
                      controller: addrController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF4A90D9)),
                      decoration: const InputDecoration(hintText: '1-255', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _DialogButton(label: '取消', isPrimary: false, onPressed: () => Navigator.pop(context))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DialogButton(
                            label: '保存',
                            isPrimary: true,
                            onPressed: () async {
                              final value = int.tryParse(addrController.text);
                              if (value != null && value >= 1 && value <= 255) {
                                setState(() {
                                  _modbusAddresses[index] = value;
                                  _modbusDeviceTypes[index] = selectedType;
                                  _hasChanges = true;
                                });
                              }
                              Navigator.pop(context);
                              await _sendModbusConfig();
                            },
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
      },
    );
  }
}

class _ExpandableDropdown extends StatefulWidget {
  final String selectedType;
  final List<String> options;
  final Function(String) onTypeSelected;

  const _ExpandableDropdown({required this.selectedType, required this.options, required this.onTypeSelected});

  @override
  State<_ExpandableDropdown> createState() => _ExpandableDropdownState();
}

class _ExpandableDropdownState extends State<_ExpandableDropdown> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(widget.selectedType, style: const TextStyle(fontSize: 14, color: Color(0xFF4A90D9), fontWeight: FontWeight.w500)),
                ),
                AnimatedRotation(turns: _isExpanded ? 0.5 : 0, duration: const Duration(milliseconds: 200), child: const Icon(Icons.expand_more, color: Color(0xFF4A90D9), size: 20)),
              ],
            ),
          ),
        ),
        if (_isExpanded)
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: widget.options.map((type) {
                final isSelected = type == widget.selectedType;
                return GestureDetector(
                  onTap: () {
                    widget.onTypeSelected(type);
                    setState(() => _isExpanded = false);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(color: isSelected ? const Color(0xFFE8F2FF) : Colors.transparent, borderRadius: BorderRadius.circular(4)),
                    child: Row(
                      children: [
                        Text(type, style: TextStyle(fontSize: 13, color: isSelected ? const Color(0xFF4A90D9) : const Color(0xFF2D4A6F), fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                        const Spacer(),
                        if (isSelected) const Icon(Icons.check, color: Color(0xFF4A90D9), size: 16),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
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
          boxShadow: widget.isPrimary ? [BoxShadow(color: const Color(0xFF4A90D9).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
        ),
        child: Text(
          widget.label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: widget.isPrimary ? Colors.white : const Color(0xFF4A90D9)),
        ),
      ),
    );
  }
}
