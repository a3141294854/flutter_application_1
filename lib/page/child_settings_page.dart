import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ChildSettingsPage extends StatefulWidget {
  final bool isConnected;
  final BluetoothDevice? device;

  const ChildSettingsPage({
    super.key,
    required this.isConnected,
    this.device,
  });

  @override
  State<ChildSettingsPage> createState() => _ChildSettingsPageState();
}

class _ChildSettingsPageState extends State<ChildSettingsPage> {
  String _baudRate = '9600';
  String _dataBits = '8';
  String _parity = 'None';
  String _stopBits = '1';

  final List<String> _baudRates = ['9600', '19200', '38400', '57600', '115200'];
  final List<String> _dataBitsList = ['5', '6', '7', '8'];
  final List<String> _parityList = ['None', 'Odd', 'Even'];
  final List<String> _stopBitsList = ['1', '2'];

  final List<int> _modbusAddresses = [1, 2, 3, 4, 5, 6, 7, 8];
  final List<String> _modbusDeviceTypes = ['保留', '保留', '保留', '保留', '保留', '保留', '保留', '保留'];
  final List<String> _deviceTypeOptions = ['保留', '多相电表', '单相电表', '温湿度变送器', '继电器'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.device_hub, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      '子节点',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                '参数配置',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D4A6F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Modbus 地址预设',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D4A6F),
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.isConnected ? _resetModbusAddresses : null,
                        child: Text(
                          '重置默认',
                          style: TextStyle(
                            color: widget.isConnected ? const Color(0xFF4A90D9) : const Color(0xFFA0BCD6),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 1,
                  color: const Color(0xFFF0F7FF),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: 8,
                    itemBuilder: (context, index) => _buildModbusCard(index),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          _buildSectionTitle('串口参数'),
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
                _buildParamRow('波特率', _baudRate, _baudRates, (v) {
                  setState(() => _baudRate = v);
                }),
                Container(height: 1, color: const Color(0xFFF0F7FF), margin: const EdgeInsets.symmetric(horizontal: 10)),
                _buildParamRow('数据位', _dataBits, _dataBitsList, (v) {
                  setState(() => _dataBits = v);
                }),
                Container(height: 1, color: const Color(0xFFF0F7FF), margin: const EdgeInsets.symmetric(horizontal: 10)),
                _buildParamRow('停止位', _stopBits, _stopBitsList, (v) {
                  setState(() => _stopBits = v);
                }),
                Container(height: 1, color: const Color(0xFFF0F7FF), margin: const EdgeInsets.symmetric(horizontal: 10)),
                _buildParamRow('校验位', _parity, _parityList, (v) {
                  setState(() => _parity = v);
                }),
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

  Widget _buildParamRow(String label, String value, List<String> options, Function(String) onChanged) {
    return InkWell(
      onTap: widget.isConnected ? () => _showOptionsPicker(label, options, value, onChanged) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D4A6F),
              ),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.isConnected ? const Color(0xFF4A90D9) : const Color(0xFFA0BCD6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: widget.isConnected ? const Color(0xFF4A90D9) : const Color(0xFFA0BCD6),
                  size: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsPicker(String title, List<String> options, String currentValue, Function(String) onChanged) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF0F7FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          '选择 $title',
          style: const TextStyle(color: Color(0xFF2D4A6F), fontSize: 15),
        ),
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

  void _resetModbusAddresses() {
    setState(() {
      _modbusAddresses.setAll(0, [1, 2, 3, 4, 5, 6, 7, 8]);
      _modbusDeviceTypes.setAll(0, ['保留', '保留', '保留', '保留', '保留', '保留', '保留', '保留']);
    });
  }

  void _showAddressEditor(int index) {
    final controller = TextEditingController(text: _modbusAddresses[index].toString());
    String selectedType = _modbusDeviceTypes[index];

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
                    Row(
                      children: [
                        const Icon(Icons.settings_applications, color: Color(0xFF4A90D9), size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Modbus 预设',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D4A6F),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F2FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '#${index + 1}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF4A90D9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 1,
                      color: const Color(0xFFE8F2FF),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.category, color: Color(0xFF4A90D9), size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          '设备类型',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D4A6F),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _ExpandableDropdown(
                      selectedType: selectedType,
                      options: _deviceTypeOptions,
                      onTypeSelected: (type) {
                        setDialogState(() {
                          selectedType = type;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.tag, color: Color(0xFF4A90D9), size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'Modbus 地址',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D4A6F),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A90D9),
                        ),
                        decoration: InputDecoration(
                          hintText: '1-255',
                          hintStyle: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFA0BCD6),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
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
                            label: '保存',
                            isPrimary: true,
                            onPressed: () {
                              final value = int.tryParse(controller.text);
                              if (value != null && value >= 1 && value <= 255) {
                                setState(() {
                                  _modbusAddresses[index] = value;
                                  _modbusDeviceTypes[index] = selectedType;
                                });
                              }
                              Navigator.pop(context);
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

  Widget _buildModbusCard(int index) {
    return GestureDetector(
      onTap: widget.isConnected ? () => _showAddressEditor(index) : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE8F2FF), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A90D9).withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
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
              child: Text(
                _modbusDeviceTypes[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: _modbusDeviceTypes[index] == '保留'
                      ? const Color(0xFFA0BCD6)
                      : const Color(0xFF4A90D9),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '${_modbusAddresses[index]}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.isConnected ? const Color(0xFF2D4A6F) : const Color(0xFFA0BCD6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandableDropdown extends StatefulWidget {
  final String selectedType;
  final List<String> options;
  final Function(String) onTypeSelected;

  const _ExpandableDropdown({
    required this.selectedType,
    required this.options,
    required this.onTypeSelected,
  });

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
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    widget.selectedType,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4A90D9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.expand_more, color: Color(0xFF4A90D9), size: 20),
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded)
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: widget.options.map((type) {
                final isSelected = type == widget.selectedType;
                return GestureDetector(
                  onTap: () {
                    widget.onTypeSelected(type);
                    setState(() {
                      _isExpanded = false;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFE8F2FF) : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Text(
                          type,
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected ? const Color(0xFF4A90D9) : const Color(0xFF2D4A6F),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          const Icon(Icons.check, color: Color(0xFF4A90D9), size: 16),
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

  const _DialogButton({
    required this.label,
    required this.isPrimary,
    required this.onPressed,
  });

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
