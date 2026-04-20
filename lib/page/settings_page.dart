import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  final bool isConnected;

  const SettingsPage({super.key, required this.isConnected});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _baudRate = '9600';
  String _dataBits = '8';
  String _parity = 'None';
  String _stopBits = '1';
  String _sleMode = '从机';
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('工作模式'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4A90D9).withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(child: _buildModeButton('Modbus 模式', true)),
                Expanded(child: _buildModeButton('广播模式', false)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionTitle('Modbus 地址预设'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4A90D9).withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.4,
                  ),
                  itemCount: 8,
                  itemBuilder: (context, index) {
                    return _buildModbusButton(index + 1);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: widget.isConnected ? _resetModbusAddresses : null,
                      child: Text(
                        '重置默认',
                        style: TextStyle(
                          color: widget.isConnected ? const Color(0xFF4A90D9) : const Color(0xFFA0BCD6),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionTitle('主设备串口参数'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4A90D9).withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildParamRow('波特率', _baudRate, _baudRates, (v) {
                  setState(() => _baudRate = v);
                }),
                Container(height: 1, color: const Color(0xFFF0F7FF), margin: const EdgeInsets.symmetric(horizontal: 16)),
                _buildParamRow('数据位', _dataBits, _dataBitsList, (v) {
                  setState(() => _dataBits = v);
                }),
                Container(height: 1, color: const Color(0xFFF0F7FF), margin: const EdgeInsets.symmetric(horizontal: 16)),
                _buildParamRow('停止位', _stopBits, _stopBitsList, (v) {
                  setState(() => _stopBits = v);
                }),
                Container(height: 1, color: const Color(0xFFF0F7FF), margin: const EdgeInsets.symmetric(horizontal: 16)),
                _buildParamRow('校验位', _parity, _parityList, (v) {
                  setState(() => _parity = v);
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionTitle('SLE 参数'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4A90D9).withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildParamRow('SLE 模式', _sleMode, _sleModes, (v) {
                  setState(() => _sleMode = v);
                }),
                Container(height: 1, color: const Color(0xFFF0F7FF), margin: const EdgeInsets.symmetric(horizontal: 16)),
                _buildParamRow('功率档位', _slePower, _slePowers, (v) {
                  setState(() => _slePower = v);
                }),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _resetModbusAddresses() {}

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
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

  Widget _buildModbusButton(int index) {
    return GestureDetector(
      onTap: widget.isConnected ? () {} : null,
      child: Container(
        width: 64,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F2FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFB8D4F0)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '#$index',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF4A90D9),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$index',
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF7A9CC6),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D4A6F),
            ),
          ),
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: widget.isConnected ? const Color(0xFF4A90D9) : const Color(0xFFA0BCD6),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: widget.isConnected ? const Color(0xFF4A90D9) : const Color(0xFFA0BCD6),
                  size: 20,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '选择 $title',
          style: const TextStyle(color: Color(0xFF2D4A6F)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) => ListTile(
                title: Text(option, style: const TextStyle(color: Color(0xFF2D4A6F))),
                trailing: option == currentValue ? const Icon(Icons.check, color: Color(0xFF4A90D9)) : null,
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
