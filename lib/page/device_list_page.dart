import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DeviceListPage extends StatefulWidget {
  final bool isConnected;
  final BluetoothDevice? device;

  const DeviceListPage({
    super.key,
    required this.isConnected,
    this.device,
  });

  @override
  State<DeviceListPage> createState() => _DeviceListPageState();
}

class _DeviceListPageState extends State<DeviceListPage> {
  // 设备数据（null 表示空闲槽位）
  final List<Map<String, String>?> _devices = List.filled(8, null);

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                onPressed: widget.isConnected ? () => _showClearAllDialog(context) : null,
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
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 8,
              itemBuilder: (context, index) {
                return _buildDeviceCard(context, index + 1, _devices[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(BuildContext context, int slot, Map<String, String>? deviceInfo) {
    final bool isEmpty = deviceInfo == null;

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
                    isEmpty ? 'Modbus ID: $slot' : deviceInfo['name']!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D4A6F),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isEmpty ? '-- 空闲槽位 --' : deviceInfo['mac']!,
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
                onTap: widget.isConnected ? () => _showAddDeviceDialog(context, slot) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.isConnected
                        ? const Color(0xFF4A90D9).withValues(alpha: 0.1)
                        : const Color(0xFFE8F2FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '+ 添加',
                    style: TextStyle(
                      color: widget.isConnected ? const Color(0xFF4A90D9) : const Color(0xFFA0BCD6),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: () => _showDeleteConfirmDialog(context, slot),
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

  void _showClearAllDialog(BuildContext context) {
    final hasDevices = _devices.any((d) => d != null);
    if (!hasDevices) return;

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
          style: TextStyle(
            color: Color(0xFF5A7A9A),
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '取消',
              style: TextStyle(color: Color(0xFF5A7A9A)),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                for (int i = 0; i < _devices.length; i++) {
                  _devices[i] = null;
                }
              });
              Navigator.pop(context);
            },
            child: const Text(
              '清空',
              style: TextStyle(color: Color(0xFFE85C5C)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDeviceDialog(BuildContext context, int slot) {
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
          slot: slot,
          onDeviceAdded: (name, mac) {
            setState(() {
              _devices[slot - 1] = {'name': name, 'mac': mac};
            });
          },
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, int slot) {
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
          '确定要删除 #${slot} 槽位的设备吗？',
          style: const TextStyle(
            color: Color(0xFF5A7A9A),
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '取消',
              style: TextStyle(color: Color(0xFF5A7A9A)),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _devices[slot - 1] = null;
              });
              Navigator.pop(context);
            },
            child: const Text(
              '删除',
              style: TextStyle(color: Color(0xFFE85C5C)),
            ),
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

class AddDeviceDialog extends StatefulWidget {
  final int slot;
  final Function(String name, String mac) onDeviceAdded;

  const AddDeviceDialog({
    super.key,
    required this.slot,
    required this.onDeviceAdded,
  });

  @override
  State<AddDeviceDialog> createState() => _AddDeviceDialogState();
}

class _AddDeviceDialogState extends State<AddDeviceDialog> {
  bool _isExpanded = false;
  final _nameController = TextEditingController();
  final _macController = TextEditingController();
  String? _nameError;
  String? _macError;

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
    return Center(
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
                  const Icon(Icons.add_circle_outline, color: Color(0xFF4A90D9), size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    '添加设备',
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
                      '#${widget.slot}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4A90D9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 1,
                color: const Color(0xFFE8F2FF),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.label_outline, color: Color(0xFF4A90D9), size: 16),
                  const SizedBox(width: 6),
                  const Text(
                    '设备名称',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D4A6F),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: '请输入设备名称',
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: _nameError != null ? Colors.red : Colors.transparent),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: _nameError != null ? Colors.red.shade200 : Colors.transparent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: _nameError != null ? Colors.red : const Color(0xFF4A90D9)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
              if (_nameError != null) ...[
                const SizedBox(height: 6),
                Text(
                  _nameError!,
                  style: const TextStyle(color: Colors.red, fontSize: 11),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.router, color: Color(0xFF4A90D9), size: 16),
                  const SizedBox(width: 6),
                  const Text(
                    'MAC 地址',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D4A6F),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _macController,
                      style: const TextStyle(fontSize: 14, letterSpacing: 1),
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'AA:BB:CC:DD:EE:FF',
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: _macError != null ? Colors.red : Colors.transparent),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: _macError != null ? Colors.red.shade200 : Colors.transparent),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: _macError != null ? Colors.red : const Color(0xFF4A90D9)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A90D9),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4A90D9).withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
              if (_macError != null) ...[
                const SizedBox(height: 6),
                Text(
                  _macError!,
                  style: const TextStyle(color: Colors.red, fontSize: 11),
                ),
              ],
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.settings, color: Color(0xFF4A90D9), size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        '串口参数',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF2D4A6F),
                        ),
                      ),
                      const Spacer(),
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.expand_more, color: Color(0xFF4A90D9), size: 20),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isExpanded) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      _buildParamRow('波特率', _baudRate, _baudRates, (v) => setState(() => _baudRate = v)),
                      _buildDivider(),
                      _buildParamRow('数据位', _dataBits, _dataBitsList, (v) => setState(() => _dataBits = v)),
                      _buildDivider(),
                      _buildParamRow('停止位', _stopBits, _stopBitsList, (v) => setState(() => _stopBits = v)),
                      _buildDivider(),
                      _buildParamRow('校验位', _parity, _parityList, (v) => setState(() => _parity = v)),
                    ],
                  ),
                ),
              ],
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
                      label: '确认',
                      isPrimary: true,
                      onPressed: () {
                        final name = _nameController.text.trim();
                        final mac = _macController.text.trim();
                        setState(() {
                          _nameError = name.isEmpty ? '请输入设备名称' : null;
                          _macError = !_isValidMacAddress(mac) ? '格式错误，应为 XX:XX:XX:XX:XX:XX' : null;
                        });
                        if (name.isNotEmpty && _isValidMacAddress(mac)) {
                          widget.onDeviceAdded(name, mac);
                          Navigator.pop(context);
                        }
                      },
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

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: const Color(0xFFF0F7FF),
      margin: const EdgeInsets.symmetric(vertical: 4),
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

  // 验证MAC地址格式 XX:XX:XX:XX:XX:XX
  bool _isValidMacAddress(String mac) {
    if (mac.isEmpty) return false;
    final macRegex = RegExp(r'^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$');
    return macRegex.hasMatch(mac);
  }

  void _showOptionsPicker(String title, List<String> options, String currentValue, Function(String) onChanged) {
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
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                      const Icon(Icons.arrow_drop_down, color: Color(0xFF4A90D9), size: 22),
                      const SizedBox(width: 4),
                      Text(
                        '选择 $title',
                        style: const TextStyle(
                          color: Color(0xFF2D4A6F),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 1,
                    color: const Color(0xFFE8F2FF),
                  ),
                  const SizedBox(height: 8),
                  ...options.asMap().entries.map((entry) {
                    final index = entry.key;
                    final option = entry.value;
                    final isSelected = option == currentValue;
                    return _OptionTile(
                      label: option,
                      isSelected: isSelected,
                      showDivider: index < options.length - 1,
                      onTap: () {
                        onChanged(option);
                        Navigator.pop(context);
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OptionTile extends StatefulWidget {
  final String label;
  final bool isSelected;
  final bool showDivider;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.isSelected,
    required this.showDivider,
    required this.onTap,
  });

  @override
  State<_OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<_OptionTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? const Color(0xFFF5F9FF)
                  : _isPressed
                      ? const Color(0xFFE8F2FF)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 15,
                      color: widget.isSelected ? const Color(0xFF4A90D9) : const Color(0xFF2D4A6F),
                      fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (widget.isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF4A90D9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 14),
                  ),
              ],
            ),
          ),
        ),
        if (widget.showDivider)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 1,
              color: const Color(0xFFE8F2FF),
            ),
          ),
        if (widget.showDivider) const SizedBox(height: 4),
      ],
    );
  }
}
