import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DeviceListPage extends StatelessWidget {
  final bool isConnected;
  final BluetoothDevice? device;

  const DeviceListPage({
    super.key,
    required this.isConnected,
    this.device,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text(
            '子设备白名单',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D4A6F),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 8,
              itemBuilder: (context, index) {
                return _buildDeviceCard(context, index + 1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(BuildContext context, int slot) {
    final bool isEmpty = true;

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
                    'Modbus ID: $slot',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D4A6F),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isEmpty ? '-- 空闲槽位 --' : '设备名称',
                    style: TextStyle(
                      fontSize: 12,
                      color: isEmpty ? const Color(0xFFA0BCD6) : const Color(0xFF5A7A9A),
                    ),
                  ),
                ],
              ),
            ),
            if (isEmpty)
              GestureDetector(
                onTap: isConnected ? () => _showAddDeviceDialog(context, slot) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isConnected
                        ? const Color(0xFF4A90D9).withValues(alpha: 0.1)
                        : const Color(0xFFE8F2FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '+ 添加',
                    style: TextStyle(
                      color: isConnected ? const Color(0xFF4A90D9) : const Color(0xFFA0BCD6),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddDeviceDialog(BuildContext context, int slot) {
    showDialog(
      context: context,
      builder: (context) => AddDeviceDialog(slot: slot),
    );
  }
}

class AddDeviceDialog extends StatefulWidget {
  final int slot;

  const AddDeviceDialog({super.key, required this.slot});

  @override
  State<AddDeviceDialog> createState() => _AddDeviceDialogState();
}

class _AddDeviceDialogState extends State<AddDeviceDialog> {
  bool _isExpanded = false;
  final _nameController = TextEditingController();
  final _macController = TextEditingController();

  String _baudRate = '9600';
  String _dataBits = '8';
  String _parity = 'None';
  String _stopBits = '1';

  final List<String> _baudRates = ['9600', '19200', '38400', '57600', '115200'];
  final List<String> _dataBitsList = ['5', '6', '7', '8'];
  final List<String> _parityList = ['None', 'Odd', 'Even'];
  final List<String> _stopBitsList = ['1', '2'];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFF0F7FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    '添加设备',
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
                      '#${widget.slot}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF4A90D9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: '设备名称',
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _macController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'MAC 地址',
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90D9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '串口参数',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                                color: Color(0xFF2D4A6F),
                              ),
                            ),
                            Icon(
                              _isExpanded ? Icons.expand_less : Icons.expand_more,
                              color: const Color(0xFF4A90D9),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isExpanded) ...[
                      Container(
                        height: 1,
                        color: const Color(0xFFE8F2FF),
                      ),
                      _buildParamRow('波特率', _baudRate, _baudRates, (v) {
                        setState(() => _baudRate = v);
                      }),
                      Container(
                        height: 1,
                        color: const Color(0xFFF5F5F5),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      _buildParamRow('数据位', _dataBits, _dataBitsList, (v) {
                        setState(() => _dataBits = v);
                      }),
                      Container(
                        height: 1,
                        color: const Color(0xFFF5F5F5),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      _buildParamRow('停止位', _stopBits, _stopBitsList, (v) {
                        setState(() => _stopBits = v);
                      }),
                      Container(
                        height: 1,
                        color: const Color(0xFFF5F5F5),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      _buildParamRow('校验位', _parity, _parityList, (v) {
                        setState(() => _parity = v);
                      }),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF5A7A9A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('取消', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        backgroundColor: const Color(0xFF4A90D9),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('确认', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildParamRow(String label, String value, List<String> options, Function(String) onChanged) {
    return InkWell(
      onTap: () => _showOptionsPicker(label, options, value, onChanged),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D4A6F),
              ),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4A90D9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF4A90D9),
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
