import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class SettingsPage extends StatefulWidget {
  final bool isConnected;
  final BluetoothDevice? device;

  const SettingsPage({
    super.key,
    required this.isConnected,
    this.device,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _baudRate = '9600';
  String _dataBits = '8';
  String _parity = 'None';
  String _stopBits = '1';
  String _sleMode = '标准平衡模式';
  String _slePower = '0';

  final List<String> _baudRates = ['9600', '19200', '38400', '57600', '115200'];
  final List<String> _dataBitsList = ['5', '6', '7', '8'];
  final List<String> _parityList = ['None', 'Odd', 'Even'];
  final List<String> _stopBitsList = ['1', '2'];
  final List<String> _sleModes = ['超远覆盖模式', '远距离优先', '标准平衡模式', '低时延模式', '高性能极速模式'];
  final List<String> _slePowers = ['0', '1', '2', '3', '4', '5', '6', '7'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text(
            '参数设置',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D4A6F),
            ),
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

          _buildSectionTitle('主设备串口参数'),
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

          _buildSectionTitle('SLE 参数'),
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
                _buildParamRow('SLE 模式', _sleMode, _sleModes, (v) {
                  setState(() => _sleMode = v);
                }),
                Container(height: 1, color: const Color(0xFFF0F7FF), margin: const EdgeInsets.symmetric(horizontal: 10)),
                _buildParamRow('功率档位', _slePower, _slePowers, (v) {
                  setState(() => _slePower = v);
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  final List<int> _modbusAddresses = [1, 2, 3, 4, 5, 6, 7, 8];

  void _resetModbusAddresses() {
    setState(() {
      _modbusAddresses.clear();
      _modbusAddresses.addAll([1, 2, 3, 4, 5, 6, 7, 8]);
    });
  }

  void _showAddressEditor(int index) {
    final controller = TextEditingController(text: _modbusAddresses[index].toString());
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFFF0F7FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    '编辑地址',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D4A6F),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F2FF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '#${index + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF4A90D9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A90D9),
                  ),
                  decoration: InputDecoration(
                    hintText: '1-255',
                    hintStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFA0BCD6),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '输入 Modbus 地址 (1-255)',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFFA0BCD6),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4A90D9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFF4A90D9)),
                        ),
                      ),
                      child: const Text('取消', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final value = int.tryParse(controller.text);
                        if (value != null && value >= 1 && value <= 255) {
                          setState(() {
                            _modbusAddresses[index] = value;
                          });
                        }
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        backgroundColor: const Color(0xFF4A90D9),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('保存', style: TextStyle(fontSize: 13)),
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

  Widget _buildModeButton(String text, bool isSelected) {
    return GestureDetector(
      onTap: widget.isConnected ? () {} : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A90D9) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFFA0BCD6),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
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
        child: Stack(
          children: [
            Positioned(
              left: 6,
              top: 4,
              child: Text(
                '#${index + 1}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFA0BCD6),
                ),
              ),
            ),
            Center(
              child: Text(
                '${_modbusAddresses[index]}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.isConnected ? const Color(0xFF4A90D9) : const Color(0xFFA0BCD6),
                ),
              ),
            ),
          ],
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
}
