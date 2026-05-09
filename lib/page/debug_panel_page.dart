import 'package:flutter/material.dart';
import '../protocol/ble_service.dart';
import '../theme/app_theme.dart';

/// 调试面板页面
class DebugPanelPage extends StatefulWidget {
  const DebugPanelPage({super.key});

  @override
  State<DebugPanelPage> createState() => _DebugPanelPageState();
}

class _DebugPanelPageState extends State<DebugPanelPage> {
  final _debugService = DebugLogService();
  final List<DebugLogEntry> _displayLogs = [];
  bool _autoScroll = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitialLogs();
    _subscribeToLogs();
  }

  void _loadInitialLogs() {
    setState(() {
      _displayLogs.addAll(_debugService.logs);
    });
  }

  void _subscribeToLogs() {
    _debugService.stream.listen((entry) {
      if (mounted) {
        setState(() {
          _displayLogs.add(entry);
          if (_displayLogs.length > 500) {
            _displayLogs.removeAt(0);
          }
        });
        if (_autoScroll) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOut,
              );
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(Icons.bug_report, color: NeuTheme.accent, size: 20),
            SizedBox(width: 8),
            Text(
              '调试面板',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          // 清空按钮
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white70),
            onPressed: () {
              setState(() => _displayLogs.clear());
              _debugService.clear();
            },
            tooltip: '清空日志',
          ),
          // 自动滚动开关
          IconButton(
            icon: Icon(
              _autoScroll ? Icons.vertical_align_bottom : Icons.vertical_align_center,
              color: _autoScroll ? NeuTheme.accent : Colors.white70,
            ),
            onPressed: () => setState(() => _autoScroll = !_autoScroll),
            tooltip: _autoScroll ? '自动滚动: 开' : '自动滚动: 关',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 日志统计
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF16213E),
            child: Row(
              children: [
                _buildStatChip('总日志', _displayLogs.length.toString(), NeuTheme.accent),
                const SizedBox(width: 12),
                _buildStatChip('发送', _displayLogs.where((l) => l.direction == '发送').length.toString(), NeuTheme.success),
                const SizedBox(width: 12),
                _buildStatChip('接收', _displayLogs.where((l) => l.direction == '接收').length.toString(), NeuTheme.warning),
                const SizedBox(width: 12),
                _buildStatChip('错误', _displayLogs.where((l) => l.error != null).length.toString(), NeuTheme.error),
              ],
            ),
          ),
          // 日志列表
          Expanded(
            child: _displayLogs.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.article_outlined, size: 64, color: Colors.white24),
                        SizedBox(height: 16),
                        Text(
                          '暂无通信日志',
                          style: TextStyle(color: Colors.white38, fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '开始通信后这里会显示发送和接收的数据',
                          style: TextStyle(color: Colors.white24, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    itemCount: _displayLogs.length,
                    itemBuilder: (context, index) {
                      return _buildLogItem(_displayLogs[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(DebugLogEntry entry) {
    final isSend = entry.direction == '发送';
    final color = isSend ? NeuTheme.success : (entry.error != null ? NeuTheme.error : NeuTheme.warning);
    final bgColor = color.withValues(alpha: 0.1);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部：时间、方向、命令名
          Row(
            children: [
              // 时间
              Text(
                entry.formattedTime,
                style: const TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'monospace'),
              ),
              const SizedBox(width: 8),
              // 方向标签
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  entry.direction,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              // 命令名
              Expanded(
                child: Text(
                  entry.cmdName ?? '',
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          // 描述信息
          if (entry.description != null && entry.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(
                    entry.error != null ? Icons.error_outline : Icons.info_outline,
                    color: entry.error != null ? NeuTheme.error : Colors.cyan,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      entry.description!,
                      style: TextStyle(
                        color: entry.error != null ? NeuTheme.error : Colors.cyan.shade300,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // 数据内容
          if (entry.data.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.hexString,
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 4),
                  // 解析数据内容
                  Text(
                    _parseFrameInfo(entry),
                    style: const TextStyle(color: Colors.white54, fontSize: 10, fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
          ],
          // 错误信息
          if (entry.error != null) ...[
            const SizedBox(height: 4),
            Text(
              entry.error!,
              style: const TextStyle(color: NeuTheme.error, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  /// 解析帧信息
  String _parseFrameInfo(DebugLogEntry entry) {
    final data = entry.data;
    if (data.length < 7) return '';
    
    // 帧格式: AA 55 CMD SEQ LEN_L LEN_H [BODY...] CRC_L CRC_H
    final cmd = data[2];
    final seq = data[3];
    final len = data[4] | (data[5] << 8);
    
    final parts = <String>[
      'CMD=0x${cmd.toRadixString(16).padLeft(2, '0').toUpperCase()}',
      'SEQ=$seq',
      'LEN=$len',
    ];
    
    if (data.length > 6 && len > 0) {
      final body = data.sublist(6, 6 + len.clamp(0, data.length - 8));
      parts.add('BODY=${body.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}');
    }
    
    return parts.join(' | ');
  }
}
