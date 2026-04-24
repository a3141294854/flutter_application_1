/// DTU 配置协议 - BLE 通信服务
/// 实现通过 BLE 特征值进行协议数据的发送和接收

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dtu_frame.dart';
import 'dtu_models.dart';
import 'dtu_protocol.dart';

/// 调试日志条目
class DebugLogEntry {
  final DateTime timestamp;
  final String direction; // "发送" 或 "接收"
  final String cmdName; // 命令名称
  final String? description; // 报文详细描述
  final Uint8List data;
  final String? error;

  DebugLogEntry({
    required this.timestamp,
    required this.direction,
    required this.cmdName,
    required this.data,
    this.description,
    this.error,
  });

  String get hexString => data.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');

  String get formattedTime => '${timestamp.hour.toString().padLeft(2, '0')}:'
      '${timestamp.minute.toString().padLeft(2, '0')}:'
      '${timestamp.second.toString().padLeft(2, '0')}.'
      '${timestamp.millisecond.toString().padLeft(3, '0')}';

  /// 获取完整的显示描述
  String get fullDescription {
    if (description != null) return description!;
    if (error != null) return error!;
    return '';
  }
}

/// 调试日志服务
class DebugLogService {
  static final DebugLogService _instance = DebugLogService._internal();
  factory DebugLogService() => _instance;
  DebugLogService._internal();

  final _logs = <DebugLogEntry>[];
  final _maxLogs = 500;

  final _controller = StreamController<DebugLogEntry>.broadcast();
  Stream<DebugLogEntry> get stream => _controller.stream;

  /// 获取所有日志
  List<DebugLogEntry> get logs => List.unmodifiable(_logs);

  /// 添加日志
  void addLog(DebugLogEntry entry) {
    _logs.add(entry);
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }
    _controller.add(entry);
  }

  /// 清空日志
  void clear() {
    _logs.clear();
  }

  /// 获取命令名称
  static String getCmdName(int cmd) {
    switch (cmd) {
      case 0x01: return 'READ_DEV_INFO';      // 读取设备信息
      case 0x02: return 'READ_UART_CFG';     // 读取串口配置
      case 0x03: return 'READ_MODBUS_CFG';   // 读取Modbus配置
      case 0x04: return 'READ_ROOT_WL_ALL';   // 读取ROOT白名单
      case 0x05: return 'READ_ROOT_POWER';   // 读取ROOT功率
      case 0x06: return 'GET_MODE_STATUS';    // 获取模式状态
      case 0x10: return 'SET_ROLE';           // 设置角色
      case 0x11: return 'SET_UART_CFG';       // 设置串口配置
      case 0x12: return 'SET_MODBUS_CFG';     // 设置Modbus配置
      case 0x13: return 'SET_ROOT_POWER';    // 设置ROOT功率
      case 0x14: return 'ADD_WL_ITEM';        // 添加白名单
      case 0x15: return 'DEL_WL_ITEM';        // 删除白名单
      case 0x16: return 'CLEAR_WL';           // 清空白名单
      case 0x17: return 'SET_CHILD_NODE_CFG'; // 设置子节点配置
      case 0x18: return 'SET_WHITE_LIST_FULL';// 批量设置白名单
      case 0x20: return 'COMMIT';             // 提交保存
      case 0x21: return 'REBOOT';             // 重启设备
      case 0x22: return 'FACTORY_RESET';      // 恢复出厂
      case 0x81: return 'READ_DEV_INFO_RSP';
      case 0x82: return 'READ_UART_CFG_RSP';
      case 0x83: return 'READ_MODBUS_CFG_RSP';
      case 0x84: return 'READ_ROOT_WL_ALL_RSP';
      case 0x85: return 'READ_ROOT_POWER_RSP';
      case 0x86: return 'GET_MODE_STATUS_RSP';
      case 0x90: return 'SET_ROLE_RSP';
      case 0x91: return 'SET_UART_CFG_RSP';
      case 0x92: return 'SET_MODBUS_CFG_RSP';
      case 0x93: return 'SET_ROOT_POWER_RSP';
      case 0xA0: return 'COMMIT_RSP';
      case 0xA1: return 'REBOOT_RSP';
      case 0xA2: return 'FACTORY_RESET_RSP';
      default: return '0x${cmd.toRadixString(16).toUpperCase()}';
    }
  }

  /// 获取命令描述（详细说明）
  static String getCmdDescription(int cmd, Uint8List data, {bool isRequest = true}) {
    final direction = isRequest ? '→发送' : '←接收';
    
    // 请求报文解析
    if (isRequest && data.length >= 7) {
      // 帧格式: AA 55 CMD SEQ LEN_L LEN_H [BODY...] CRC_L CRC_H
      // 索引:   0   1   2    3    4     5     6...   N-2  N-1
      final bodyLen = data[4] | (data[5] << 8);
      final body = bodyLen > 0 && data.length > 6 ? data.sublist(6, 6 + bodyLen) : [];
      
      switch (cmd) {
        case 0x01: return '📤 【读取设备信息】获取DTU的MAC地址、设备名称、角色等基本信息';
        case 0x02: return '📤 【读取串口配置】获取DTU与下位机通信的串口参数（波特率、校验位等）';
        case 0x03: return '📤 【读取Modbus配置】获取DTU连接的Modbus从机设备地址列表';
        case 0x04: return '📤 【读取ROOT白名单】获取ROOT模式下允许连接的NODE设备MAC列表';
        case 0x05: return '📤 【读取ROOT功率】获取ROOT设备的发射功率等级（0-7）';
        case 0x06: return '📤 【获取模式状态】获取DTU当前工作模式（CONFIG配置模式/RUN运行模式）';
        case 0x10: // SET_ROLE
          if (body.isNotEmpty) {
            final role = body[0] == 0x01 ? 'ROOT(主节点)' : 'NODE(子节点)';
            final roleDesc = body[0] == 0x01 ? '可连接多个NODE设备' : '只能连接一个ROOT设备';
            return '📤 【设置角色】设置DTU为$role  $roleDesc';
          }
          return '📤 【设置角色】配置DTU为主从模式';
        case 0x11: // SET_UART_CFG
          if (body.length >= 4) {
            final baud = DtuProtocol.getBaudRate(body[0]);
            final parity = DtuProtocol.getParityName(body[1]);
            return '📤 【设置串口配置】波特率:$baud 数据位:${body[2]} 校验:$parity 停止位:${body[3]}';
          }
          return '📤 【设置串口配置】配置DTU与下位机的串口通信参数';
        case 0x12: // SET_MODBUS_CFG
          final count = body.isNotEmpty ? body[0] : 0;
          return '📤 【设置Modbus配置】配置$count个Modbus从机设备地址';
        case 0x13: // SET_ROOT_POWER
          final power = body.isNotEmpty ? body[0] : 0;
          final powerDesc = power <= 2 ? '低功率(省电)' : (power <= 5 ? '中功率' : '高功率(远距离)');
          return '📤 【设置ROOT功率】功率等级:$power($powerDesc) 影响通信距离';
        case 0x14: // ADD_WL_ITEM
          if (body.length >= 7) {
            final mac = body.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(':');
            return '📤 【添加白名单】允许MAC=$mac的设备连接';
          }
          return '📤 【添加白名单】将指定MAC的NODE设备添加到允许列表';
        case 0x15: // DEL_WL_ITEM
          if (body.length >= 6) {
            final mac = body.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(':');
            return '📤 【删除白名单】移除MAC=$mac的设备连接权限';
          }
          return '📤 【删除白名单】从白名单中移除指定MAC设备';
        case 0x16: return '📤 【清空白名单】移除所有白名单设备（谨慎操作）';
        case 0x17: return '📤 【设置子节点配置】配置NODE设备的下位机参数（串口+Modbus）';
        case 0x18: return '📤 【批量设置白名单】一次性设置多个白名单设备';
        case 0x20: return '📤 【提交保存】将所有配置写入Flash永久保存（必须操作！）';
        case 0x21: return '📤 【重启设备】重启DTU使配置生效';
        case 0x22: return '📤 【恢复出厂】清除所有配置恢复默认（谨慎操作！）';
        default: return '📤 【${getCmdName(cmd)}】未知命令 $direction';
      }
    }
    
    // 响应报文解析
    if (!isRequest && data.isNotEmpty) {
      final status = data[0];
      final statusDesc = _getStatusDescription(status);
      
      switch (cmd) {
        case 0x81: // READ_DEV_INFO 响应
          if (data.length >= 9) {
            final role = data[1] == 0x01 ? 'ROOT(主节点)' : 'NODE(子节点)';
            final mac = data.sublist(2, 8).map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(':');
            final nameLen = data[8];
            final name = nameLen > 0 && data.length > 9 + nameLen 
                ? String.fromCharCodes(data.sublist(9, 9 + nameLen)) : '未知';
            return '📥 【设备信息】名称:$name MAC:$mac 角色:$role $statusDesc';
          }
          return '📥 【读取设备信息响应】 $statusDesc';
        case 0x82: // READ_UART_CFG 响应
          if (data.length >= 5) {
            final baud = DtuProtocol.getBaudRate(data[1]);
            final parity = DtuProtocol.getParityName(data[2]);
            return '📥 【串口配置】波特率:$baud 数据位:${data[4]} 校验:$parity 停止位:${data[3]} $statusDesc';
          }
          return '📥 【读取串口配置响应】 $statusDesc';
        case 0x83: // READ_MODBUS_CFG 响应
          if (data.length >= 2) {
            final count = data[1];
            return '📥 【Modbus配置】已配置$count个Modbus从机设备 $statusDesc';
          }
          return '📥 【读取Modbus配置响应】 $statusDesc';
        case 0x84: // READ_ROOT_WL_ALL 响应
          if (data.length >= 5) {
            return '📥 【白名单】第${data[1]}页/共${data[2]}页 共${data[3]}条记录 $statusDesc';
          }
          return '📥 【读取白名单响应】 $statusDesc';
        case 0x85: // READ_ROOT_POWER 响应
          if (data.length > 1) {
            final power = data[1];
            return '📥 【ROOT功率】当前功率等级:$power $statusDesc';
          }
          return '📥 【读取功率响应】 $statusDesc';
        case 0x86: // GET_MODE_STATUS 响应
          if (data.length >= 2) {
            final mode = data[1] == 0x01 ? 'CONFIG(配置模式)' : 'RUN(运行模式)';
            return '📥 【模式状态】当前模式:$mode $statusDesc';
          }
          return '📥 【获取模式状态响应】 $statusDesc';
        case 0x90: return '📥 【设置角色响应】 $statusDesc';
        case 0x91: return '📥 【设置串口响应】 $statusDesc';
        case 0x92: return '📥 【设置Modbus响应】 $statusDesc';
        case 0x93: return '📥 【设置功率响应】 $statusDesc';
        case 0xA0: return '📥 【提交保存响应】配置已写入Flash $statusDesc';
        case 0xA1: return '📥 【重启响应】设备正在重启... $statusDesc';
        case 0xA2: return '📥 【恢复出厂响应】所有配置已清除 $statusDesc';
        default: return '📥 【${getCmdName(cmd)}响应】 $statusDesc';
      }
    }
    
    return '${getCmdName(cmd)} $direction';
  }

  /// 获取状态码详细描述
  static String _getStatusDescription(int status) {
    switch (status) {
      case 0x00: return '(操作成功)';
      case 0x01: return '(操作失败)';
      case 0x02: return '(参数错误)';
      case 0x03: return '(权限不足)';
      case 0x04: return '(设备忙)';
      case 0x05: return '(数据不存在)';
      case 0x06: return '(空间不足)';
      default: return '';
    }
  }

  void dispose() {
    _controller.close();
  }
}

/// BLE 通信服务
/// 管理与 DTU 设备的蓝牙通信
class BleService {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeChar;
  BluetoothCharacteristic? _notifyChar;

  final _responseController = StreamController<List<int>>.broadcast();
  StreamSubscription<List<int>>? _notifySubscription;

  // 等待响应的回调
  final Map<int, Completer<ParseResult>> _pendingRequests = {};

  // 响应超时时间
  static const Duration _responseTimeout = Duration(seconds: 5);

  // DTU 固定 UUID
  static const String _dtuServiceUuidStr = 'FDF0';

  /// 当前连接状态
  bool get isConnected => _device != null && _writeChar != null;

  /// 响应数据流
  Stream<List<int>> get responseStream => _responseController.stream;

  /// 连接设备
  Future<void> connect(BluetoothDevice device) async {
    _device = device;
    _addConnectLog('🔍 开始连接设备...', true);

    // 发现所有服务
    final services = await device.discoverServices();
    _addConnectLog('📡 发现 ${services.length} 个BLE服务', true);

    // 列出所有服务 UUID
    for (final service in services) {
      _addConnectLog('   服务: ${service.uuid.str}', true);
    }

    // 查找 DTU Service
    BluetoothService? dtuService;
    for (final service in services) {
      final uuidStr = service.uuid.str.toUpperCase();
      if (uuidStr.contains('FDF0')) {
        dtuService = service;
        _addConnectLog('✅ 找到 DTU Service (FDF0)', true);
        break;
      }
    }

    if (dtuService == null) {
      _addConnectLog('❌ 未找到 DTU Service (UUID: $_dtuServiceUuidStr)', false);
      throw Exception('未找到 DTU Service (UUID: $_dtuServiceUuidStr)');
    }

    // 列出该服务下所有特征值
    _addConnectLog('📋 DTU Service 特征值列表:', true);
    for (final char in dtuService.characteristics) {
      final canWrite = char.properties.write || char.properties.writeWithoutResponse;
      final canNotify = char.properties.notify || char.properties.indicate;
      _addConnectLog('   ${char.uuid.str} 可写:$canWrite 可通知:$canNotify', true);
    }

    // 查找特征值
    BluetoothCharacteristic? writeChar;
    BluetoothCharacteristic? notifyChar;

    for (final char in dtuService.characteristics) {
      // 查找可写的特征值 (FDF1)
      if (char.uuid.str.toUpperCase().contains('FDF1')) {
        _addConnectLog('🔍 找到 FDF1 特征值', true);
        if (char.properties.write || char.properties.writeWithoutResponse) {
          writeChar = char;
          _addConnectLog('   ✅ FDF1 支持写入', true);
        }
        if (char.properties.notify || char.properties.indicate) {
          notifyChar = char;
          _addConnectLog('   ✅ FDF1 支持通知', true);
        }
      }
    }

    // 如果没找到 FDF1，遍历所有特征值
    if (writeChar == null || notifyChar == null) {
      _addConnectLog('⚠️ 未找到 FDF1，自动匹配其他特征值', true);
      for (final char in dtuService.characteristics) {
        if (writeChar == null && (char.properties.write || char.properties.writeWithoutResponse)) {
          writeChar = char;
          _addConnectLog('   使用写入特征值: ${char.uuid.str}', true);
        }
        if (notifyChar == null && (char.properties.notify || char.properties.indicate)) {
          notifyChar = char;
          _addConnectLog('   使用通知特征值: ${char.uuid.str}', true);
        }
      }
    }

    if (writeChar == null) {
      _addConnectLog('❌ 未找到可写的特征值，无法发送数据!', false);
      throw Exception('DTU Service 中未找到可写的特征值');
    }

    _writeChar = writeChar;
    _notifyChar = notifyChar;
    _addConnectLog('📝 写入特征值: ${_writeChar!.uuid.str}', true);
    _addConnectLog('📝 通知特征值: ${_notifyChar?.uuid.str ?? "无(无法接收响应)"}', _notifyChar != null);

    // 订阅通知（必须先订阅才能收到响应）
    if (_notifyChar != null) {
      try {
        await _notifyChar!.setNotifyValue(true);
        _addConnectLog('✅ 已发送订阅Notify请求', true);
        
        // 等待一小段时间确保订阅完成
        await Future.delayed(const Duration(milliseconds: 100));
        
        // 检查订阅状态
        final isNotifying = _notifyChar!.isNotifying;
        _addConnectLog('${isNotifying ? "✅" : "⚠️"} Notify订阅状态: ${isNotifying ? "已订阅" : "未订阅"}', isNotifying);
        
        if (!isNotifying) {
          _addConnectLog('⚠️ 警告: Notify未成功订阅，设备无法发送响应数据!', false);
        }
        
        // 使用 onValueReceived 持续监听通知
        _notifySubscription = _notifyChar!.onValueReceived.listen(
          _onDataReceived,
          onError: (e) {
            debugPrint('[BLE] Notify error: $e');
          },
        );
      } catch (e) {
        _addConnectLog('❌ 订阅Notify失败: $e', false);
      }
    } else {
      _addConnectLog('❌ 错误: 未找到支持通知的特征值，响应将无法接收!', false);
    }
    
    // 连接完成
    if (_writeChar != null && _notifyChar != null) {
      _addConnectLog('🎉 连接成功! 可以开始通信了', true);
    }
  }

  /// 添加连接日志到调试面板
  void _addConnectLog(String message, bool isSuccess) {
    debugPrint('[BLE连接] $message');
    DebugLogService().addLog(DebugLogEntry(
      timestamp: DateTime.now(),
      direction: '📱',
      cmdName: 'BLE连接',
      description: message,
      data: Uint8List(0),
      error: isSuccess ? null : message,
    ));
  }

  /// 断开连接
  Future<void> disconnect() async {
    await _notifySubscription?.cancel();
    _notifySubscription = null;
    _notifyChar = null;
    _writeChar = null;
    _device = null;

    // 取消所有待处理的请求
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError('连接已断开');
      }
    }
    _pendingRequests.clear();
  }

  /// 发送数据并等待响应
  Future<ParseResult> sendAndWait(Uint8List frame, {int? expectedSeq}) async {
    if (!isConnected) {
      return ParseResult.error('未连接到设备');
    }

    // 创建完成器
    final completer = Completer<ParseResult>();
    final seq = frame[3]; // 从帧中获取 SEQ

    _pendingRequests[seq] = completer;

    // 记录发送的日志
    // 帧格式: AA 55 CMD SEQ LEN_L LEN_H [BODY...] CRC_L CRC_H
    // 索引:    0   1   2    3    4     5     6...   N-2  N-1
    final cmd = frame.length > 2 ? frame[2] : 0;
    final hexStr = frame.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');
    debugPrint('[BLE发送] CMD=0x${cmd.toRadixString(16)}, SEQ=$seq, 数据: $hexStr');
    
    final sendEntry = DebugLogEntry(
      timestamp: DateTime.now(),
      direction: '发送',
      cmdName: DebugLogService.getCmdName(cmd),
      description: DebugLogService.getCmdDescription(cmd, frame, isRequest: true),
      data: frame,
    );
    DebugLogService().addLog(sendEntry);

    try {
      // 发送帧 (设备只支持不带响应的写入)
      await _writeChar!.write(frame, withoutResponse: true);
      
      // 添加等待确认日志
      _addReceiveLog('⏳ 等待响应中... (SEQ=$seq, 超时${_responseTimeout.inSeconds}秒)', true);
      debugPrint('[BLE发送] 发送成功! 等待响应...');

      // 等待响应
      final result = await completer.future.timeout(
        _responseTimeout,
        onTimeout: () {
          _pendingRequests.remove(seq);
          // 记录超时的日志（包含发送的完整信息）
          final timeoutEntry = DebugLogEntry(
            timestamp: DateTime.now(),
            direction: '接收',
            cmdName: '超时',
            data: frame,
            description: '期望响应: ${DebugLogService.getCmdName(cmd)}(0x${(cmd + 0x80).toRadixString(16).toUpperCase()}) 等待时间: ${_responseTimeout.inSeconds}秒',
            error: '响应超时! 请检查: 1)设备是否开启notify 2)帧格式是否正确 3)设备是否在线',
          );
          DebugLogService().addLog(timeoutEntry);
          return ParseResult.error('响应超时(等待${_responseTimeout.inSeconds}秒未收到${DebugLogService.getCmdName(cmd)}响应)');
        },
      );

      // 记录接收的日志
      if (result.isSuccess && result.body != null) {
        final respCmd = result.cmd ?? 0;
        final recvEntry = DebugLogEntry(
          timestamp: DateTime.now(),
          direction: '接收',
          cmdName: DebugLogService.getCmdName(respCmd),
          description: DebugLogService.getCmdDescription(respCmd, result.body!, isRequest: false),
          data: result.body!,
        );
        DebugLogService().addLog(recvEntry);
      } else if (!result.isSuccess) {
        final errorEntry = DebugLogEntry(
          timestamp: DateTime.now(),
          direction: '接收',
          cmdName: '错误',
          data: Uint8List(0),
          error: result.error,
        );
        DebugLogService().addLog(errorEntry);
      }

      return result;
    } catch (e) {
      _pendingRequests.remove(seq);
      // 记录错误的日志
      final errorEntry = DebugLogEntry(
        timestamp: DateTime.now(),
        direction: '接收',
        cmdName: '错误',
        data: Uint8List(0),
        error: '发送失败: $e',
      );
      DebugLogService().addLog(errorEntry);
      return ParseResult.error('发送失败: $e');
    }
  }

  /// 处理接收到的数据
  void _onDataReceived(List<int> data) {
    // 调试面板日志：确认收到原始数据
    final hexStr = data.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');
    _addReceiveLog('📥 BLE收到原始数据 ($data.length 字节): $hexStr', true);
    
    debugPrint('[BLE接收] 收到数据 (${data.length}字节): $hexStr');

    // 检查帧头
    if (data.length >= 2) {
      final sof1 = data[0].toRadixString(16).padLeft(2, '0').toUpperCase();
      final sof2 = data[1].toRadixString(16).padLeft(2, '0').toUpperCase();
      if (sof1 == 'AA' && sof2 == '55') {
        debugPrint('[BLE接收] ✅ 帧头正确 (AA 55)');
      } else {
        debugPrint('[BLE接收] ⚠️ 帧头错误: $sof1 $sof2 (期望: AA 55)');
      }
    }

    // 广播原始数据
    _responseController.add(data);

    // 尝试解析帧
    final results = DtuFrame.parseStream(Uint8List.fromList(data));

    if (results.isEmpty) {
      _addReceiveLog('⚠️ 无法解析为DTU帧，可能是其他协议数据', false);
      debugPrint('[BLE接收] 未找到有效帧! 数据可能是非DTU协议格式或帧头不匹配');
    }

    for (final result in results) {
      debugPrint('[BLE接收] 解析结果: isSuccess=${result.isSuccess}, cmd=0x${result.cmd?.toRadixString(16)}, seq=${result.seq}, error=${result.error}');
      
      if (result.isSuccess && result.seq != null) {
        // 检查是否有等待此 SEQ 的请求
        final completer = _pendingRequests.remove(result.seq);
        if (completer != null && !completer.isCompleted) {
          completer.complete(result);
          debugPrint('[BLE接收] ✅ 匹配到等待的请求 SEQ=${result.seq}，完成等待');
        } else {
          debugPrint('[BLE接收] ⚠️ 未找到匹配的待处理请求 seq=${result.seq}, 当前等待: ${_pendingRequests.keys.toList()}');
        }
      }
    }
  }

  /// 添加接收日志到调试面板
  void _addReceiveLog(String message, bool isSuccess) {
    DebugLogService().addLog(DebugLogEntry(
      timestamp: DateTime.now(),
      direction: '📥',
      cmdName: 'BLE接收',
      description: message,
      data: Uint8List(0),
      error: isSuccess ? null : message,
    ));
  }

  /// 发送请求帧（不等待响应）
  Future<void> sendFrame(Uint8List frame) async {
    if (!isConnected) {
      throw Exception('未连接到设备');
    }
    // 设备只支持不带响应的写入
    await _writeChar!.write(frame, withoutResponse: true);
  }

  /// 发送命令并解析特定类型的响应
  Future<T> sendCommand<T>(
    Uint8List frame,
    T Function(Uint8List body) parser,
  ) async {
    final result = await sendAndWait(frame);

    if (!result.isSuccess) {
      throw FormatException(result.error ?? '未知错误');
    }

    return parser(result.body!);
  }

  // ========== 读取命令 ==========

  /// 读取设备信息
  Future<DeviceInfo> readDeviceInfo() async {
    final result = await sendAndWait(DtuFrame.buildReadDevInfo());
    if (!result.isSuccess) {
      throw FormatException('读取设备信息失败: ${result.error}');
    }
    return DeviceInfo.fromBytes(result.body!);
  }

  /// 读取串口配置
  Future<UartConfig> readUartConfig() async {
    final result = await sendAndWait(DtuFrame.buildReadUartCfg());
    if (!result.isSuccess) {
      throw FormatException('读取串口配置失败: ${result.error}');
    }
    return UartConfig.fromBytes(result.body!);
  }

  /// 读取 Modbus 配置
  Future<ModbusConfig> readModbusConfig() async {
    final result = await sendAndWait(DtuFrame.buildReadModbusCfg());
    if (!result.isSuccess) {
      throw FormatException('读取 Modbus 配置失败: ${result.error}');
    }
    return ModbusConfig.fromBytes(result.body!);
  }

  /// 读取白名单
  Future<List<WhiteListItem>> readWhiteList() async {
    final allItems = <WhiteListItem>[];

    while (true) {
      final result = await sendAndWait(DtuFrame.buildReadWhiteList());
      if (!result.isSuccess) {
        throw FormatException('读取白名单失败: ${result.error}');
      }

      final wlResult = WhiteListResult.fromBytes(result.body!);
      allItems.addAll(wlResult.items);

      if (wlResult.isComplete) break;
    }

    return allItems;
  }

  /// 读取功率
  Future<PowerConfig> readPower() async {
    final result = await sendAndWait(DtuFrame.buildReadPower());
    if (!result.isSuccess) {
      throw FormatException('读取功率失败: ${result.error}');
    }
    return PowerConfig.fromBytes(result.body!);
  }

  /// 获取模式状态
  Future<ModeStatus> readModeStatus() async {
    final result = await sendAndWait(DtuFrame.buildGetModeStatus());
    if (!result.isSuccess) {
      throw FormatException('获取模式状态失败: ${result.error}');
    }
    return ModeStatus.fromBytes(result.body!);
  }

  // ========== 写入命令 ==========

  /// 检查响应状态
  Future<void> _checkStatus(Uint8List frame) async {
    final result = await sendAndWait(frame);
    
    if (!result.isSuccess) {
      // 通信错误（超时、断开等）
      throw FormatException('通信失败: ${result.error}');
    }
    
    if (result.body == null || result.body!.isEmpty) {
      throw FormatException('设备无响应');
    }
    
    final status = DtuFrame.getStatus(result.body!);
    if (status != DtuProtocol.STATUS_SUCCESS) {
      throw FormatException('操作失败: ${DtuProtocol.getStatusName(status)}');
    }
  }

  /// 设置角色
  Future<void> setRole(int role) async {
    await _checkStatus(DtuFrame.buildSetRole(role));
  }

  /// 设置串口配置
  Future<void> setUartConfig(UartConfig config) async {
    await _checkStatus(DtuFrame.buildSetUartCfg(
      baudLevel: config.baudLevel,
      parity: config.parity,
      stopBits: config.stopBits,
      dataBits: config.dataBits,
    ));
  }

  /// 设置 Modbus 配置
  Future<void> setModbusConfig(ModbusConfig config) async {
    await _checkStatus(DtuFrame.buildSetModbusCfg(config.toBytesList()));
  }

  /// 设置功率
  Future<void> setPower(PowerConfig config) async {
    await _checkStatus(DtuFrame.buildSetPower(config.power));
  }

  /// 添加白名单条目
  Future<void> addWhiteListItem(String mac, String name) async {
    await _checkStatus(DtuFrame.buildAddWhiteListItem(mac, name));
  }

  /// 添加完整的白名单条目（包含串口参数和 Modbus 配置）
  Future<void> addWhiteListItemFull(WhiteListItem item) async {
    await _checkStatus(DtuFrame.buildSetWhiteListFull(
      mac: item.mac,
      name: item.name,
      baudLevel: item.baudLevel,
      dataBits: item.dataBits,
      stopBits: item.stopBits,
      parity: item.parity,
      modbusAddresses: item.modbusAddresses,
    ));
  }

  /// 设置子节点配置（Tag 0x08）
  Future<void> setChildNodeConfig(WhiteListItem item) async {
    await _checkStatus(DtuFrame.buildSetChildNodeConfig(
      mac: item.mac,
      baudLevel: item.baudLevel,
      dataBits: item.dataBits,
      stopBits: item.stopBits,
      parity: item.parity,
      modbusAddresses: item.modbusAddresses,
    ));
  }

  /// 删除白名单条目
  Future<void> delWhiteListItem(String mac) async {
    await _checkStatus(DtuFrame.buildDelWhiteListItem(mac));
  }

  /// 清空白名单
  Future<void> clearWhiteList() async {
    await _checkStatus(DtuFrame.buildClearWhiteList());
  }

  /// 提交保存
  Future<void> commit() async {
    await _checkStatus(DtuFrame.buildCommit());
  }

  /// 重启设备
  Future<void> reboot() async {
    await _checkStatus(DtuFrame.buildReboot());
  }

  /// 恢复出厂设置
  Future<void> factoryReset() async {
    await _checkStatus(DtuFrame.buildFactoryReset());
  }

  /// 释放资源
  void dispose() {
    _notifySubscription?.cancel();
    _responseController.close();
    disconnect();
  }
}

/// BLE 服务管理器（单例）
class BleServiceManager {
  static final BleServiceManager _instance = BleServiceManager._internal();
  factory BleServiceManager() => _instance;
  BleServiceManager._internal();

  final BleService _service = BleService();

  BleService get service => _service;

  /// 是否已连接
  bool get isConnected => _service.isConnected;

  /// 连接设备
  Future<void> connect(BluetoothDevice device) => _service.connect(device);

  /// 断开连接
  Future<void> disconnect() => _service.disconnect();

  /// 释放
  void dispose() => _service.dispose();
}
