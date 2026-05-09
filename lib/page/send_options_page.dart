import 'package:flutter/material.dart';
import '../protocol/protocol.dart';
import '../theme/app_theme.dart';

class SendOptionsPage extends StatefulWidget {
  final bool isConnected;
  final DtuService dtuService;

  const SendOptionsPage({super.key, required this.isConnected, required this.dtuService});

  @override
  State<SendOptionsPage> createState() => _SendOptionsPageState();
}

class _SendOptionsPageState extends State<SendOptionsPage> {
  bool _isLoading = false;
  String _loadingText = '';
  String? _lastResult;

  DtuService get _service => widget.dtuService;

  Future<void> _showLoading(String text) async => setState(() { _isLoading = true; _loadingText = text; });
  void _hideLoading() => setState(() { _isLoading = false; _loadingText = ''; });
  void _showResult(String result) => setState(() { _lastResult = result; });

  Future<void> _readConfig() async {
    if (!widget.isConnected) return;
    await _showLoading('正在读取配置...');
    try {
      final config = await _service.readAllConfig();
      final buffer = StringBuffer()..writeln('=== 读取成功 ===');
      if (config.deviceInfo != null) { buffer.writeln('设备名称: ${config.deviceInfo!.name}'); buffer.writeln('设备角色: ${config.deviceInfo!.roleName}'); buffer.writeln('MAC地址: ${config.deviceInfo!.mac}'); }
      if (config.uartConfig != null) { buffer.writeln('波特率: ${config.uartConfig!.baudRate}'); buffer.writeln('校验位: ${config.uartConfig!.parityName}'); buffer.writeln('停止位: ${config.uartConfig!.stopBits}'); buffer.writeln('数据位: ${config.uartConfig!.dataBits}'); }
      if (config.modbusConfig != null) { buffer.writeln('Modbus预设:'); for (int i = 0; i < config.modbusConfig!.items.length; i++) { final item = config.modbusConfig!.items[i]; if (item.devType != 0) buffer.writeln('  #${i + 1}: 站号${item.addr} - ${item.deviceTypeName}'); } }
      if (config.powerConfig != null) buffer.writeln('发射功率: ${config.powerConfig!.power}');
      if (config.whiteList.isNotEmpty) { buffer.writeln('白名单:'); for (final item in config.whiteList) buffer.writeln('  ${item.mac}'); }
      _showResult(buffer.toString());
    } catch (e) { _showResult('读取失败: $e'); } finally { _hideLoading(); }
  }

  Future<void> _saveConfig() async {
    if (!widget.isConnected) return;
    await _showLoading('正在保存配置...');
    try { await _service.commit(); _showResult('配置已保存'); } catch (e) { _showResult('保存失败: $e'); } finally { _hideLoading(); }
  }

  Future<void> _factoryReset() async {
    if (!widget.isConnected) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('恢复出厂设置'),
        content: const Text('确定要恢复出厂设置吗？所有配置将被清除。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('确认', style: TextStyle(color: NeuTheme.error))),
        ],
      ),
    );
    if (confirmed != true) return;
    await _showLoading('正在恢复出厂设置...');
    try { await _service.factoryReset(); _showResult('已恢复出厂设置'); } catch (e) { _showResult('恢复失败: $e'); } finally { _hideLoading(); }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 12),
            _buildSectionTitle('发送选项'),
            Container(
              decoration: NeuTheme.cardDecoration(),
              child: Column(children: [
                _buildSendOptionRow('读取配置', Icons.download, _readConfig),
                Container(height: 1, color: NeuTheme.bg, margin: const EdgeInsets.symmetric(horizontal: 10)),
                _buildSendOptionRow('保存配置', Icons.save, _saveConfig),
                Container(height: 1, color: NeuTheme.bg, margin: const EdgeInsets.symmetric(horizontal: 10)),
                _buildSendOptionRow('恢复出厂', Icons.restore, _factoryReset),
              ]),
            ),
            const SizedBox(height: 10),
            if (_lastResult != null) ...[
              _buildSectionTitle('操作结果'),
              Container(
                width: double.infinity, padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: NeuTheme.card, borderRadius: BorderRadius.circular(NeuTheme.radiusSm), boxShadow: NeuTheme.shadowRaisedSm),
                child: Text(_lastResult!, style: const TextStyle(fontSize: 12, color: NeuTheme.textPrimary, height: 1.5)),
              ),
            ],
            const SizedBox(height: 20),
          ]),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                decoration: BoxDecoration(color: NeuTheme.card, borderRadius: BorderRadius.circular(NeuTheme.radiusMd), boxShadow: NeuTheme.shadowRaisedMd),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const CircularProgressIndicator(color: NeuTheme.accent),
                  const SizedBox(height: 16),
                  Text(_loadingText, style: const TextStyle(color: NeuTheme.textPrimary, fontSize: 14)),
                ]),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: NeuTheme.textPrimary)));

  Widget _buildSendOptionRow(String label, IconData icon, VoidCallback onTap) => InkWell(
    onTap: widget.isConnected && !_isLoading ? onTap : null,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(children: [
        Icon(icon, size: 20, color: widget.isConnected ? NeuTheme.accent : NeuTheme.textMuted),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: widget.isConnected ? NeuTheme.textPrimary : NeuTheme.textMuted)),
        const Spacer(),
        Icon(Icons.chevron_right, size: 18, color: widget.isConnected ? NeuTheme.accent : NeuTheme.textMuted),
      ]),
    ),
  );
}
