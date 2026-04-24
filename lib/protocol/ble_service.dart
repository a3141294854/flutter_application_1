/// DTU 配置协议 - BLE 通信服务
/// 实现通过 BLE 特征值进行协议数据的发送和接收

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dtu_frame.dart';
import 'dtu_models.dart';
import 'dtu_protocol.dart';

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

  /// 当前连接状态
  bool get isConnected => _device != null && _writeChar != null;

  /// 响应数据流
  Stream<List<int>> get responseStream => _responseController.stream;

  /// 连接设备
  Future<void> connect(BluetoothDevice device) async {
    _device = device;

    // 发现服务和特征值
    final services = await device.discoverServices();

    BluetoothCharacteristic? writeChar;
    BluetoothCharacteristic? notifyChar;

    for (final service in services) {
      for (final char in service.characteristics) {
        // 查找可写的特征值
        if (char.properties.write || char.properties.writeWithoutResponse) {
          writeChar ??= char;
        }
        // 查找支持通知的特征值
        if (char.properties.notify || char.properties.indicate) {
          notifyChar ??= char;
        }
      }
    }

    if (writeChar == null) {
      throw Exception('未找到可写的 BLE 特征值');
    }

    _writeChar = writeChar;
    _notifyChar = notifyChar;

    // 订阅通知（如果支持）
    if (_notifyChar != null) {
      await _notifyChar!.setNotifyValue(true);
      _notifySubscription = _notifyChar!.lastValueStream.listen(_onDataReceived);
    }
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

    try {
      // 发送帧
      await _writeChar!.write(frame, withoutResponse: false);

      // 等待响应
      final result = await completer.future.timeout(
        _responseTimeout,
        onTimeout: () {
          _pendingRequests.remove(seq);
          return ParseResult.error('响应超时');
        },
      );

      return result;
    } catch (e) {
      _pendingRequests.remove(seq);
      return ParseResult.error('发送失败: $e');
    }
  }

  /// 处理接收到的数据
  void _onDataReceived(List<int> data) {
    // 广播原始数据
    _responseController.add(data);

    // 尝试解析帧
    final results = DtuFrame.parseStream(Uint8List.fromList(data));

    for (final result in results) {
      if (result.isSuccess && result.seq != null) {
        // 检查是否有等待此 SEQ 的请求
        final completer = _pendingRequests.remove(result.seq);
        if (completer != null && !completer.isCompleted) {
          completer.complete(result);
        }
      }
    }
  }

  /// 发送请求帧（不等待响应）
  Future<void> sendFrame(Uint8List frame) async {
    if (!isConnected) {
      throw Exception('未连接到设备');
    }
    await _writeChar!.write(frame, withoutResponse: false);
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
