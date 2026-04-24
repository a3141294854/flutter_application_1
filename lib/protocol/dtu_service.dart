/// DTU 配置协议 - 协议服务
/// 提供高层次的配置读取和写入操作

import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'ble_service.dart';
import 'dtu_models.dart';
import 'dtu_protocol.dart';

/// 协议服务
/// 封装完整的配置读取和写入流程
class DtuService {
  final BleService _bleService;

  /// 设备配置缓存
  DeviceConfig _config = DeviceConfig.empty();

  /// 设备信息
  DeviceConfig get config => _config;
  DeviceInfo? get deviceInfo => _config.deviceInfo;
  UartConfig? get uartConfig => _config.uartConfig;
  ModbusConfig? get modbusConfig => _config.modbusConfig;
  List<WhiteListItem> get whiteList => _config.whiteList;
  PowerConfig? get powerConfig => _config.powerConfig;

  DtuService(this._bleService);

  /// 是否为根节点
  bool get isRoot => _config.isRoot;

  /// 更新设备角色（本地刷新，不发送命令）
  void updateRole(int role) {
    final currentInfo = _config.deviceInfo;
    if (currentInfo != null) {
      // 更新现有设备信息
      final updatedInfo = DeviceInfo(
        role: role,
        mac: currentInfo.mac,
        name: currentInfo.name,
      );
      _config = _config.copyWith(deviceInfo: updatedInfo);
      print('[DtuService] Updated role to ${role == DtuProtocol.ROLE_ROOT ? "ROOT" : "NODE"}');
    } else {
      // 如果没有设备信息，创建一个
      _config = _config.copyWith(
        deviceInfo: DeviceInfo(role: role, mac: '00:00:00:00:00:00', name: 'Unknown'),
      );
      print('[DtuService] Created new DeviceInfo with role ${role == DtuProtocol.ROLE_ROOT ? "ROOT" : "NODE"}');
    }
  }

  /// 是否已连接
  bool get isConnected => _bleService.isConnected;

  // ========== 连接管理 ==========

  /// 连接设备
  Future<void> connect(BluetoothDevice device) async {
    await _bleService.connect(device);
    _config = DeviceConfig.empty();
  }

  /// 断开连接
  Future<void> disconnect() async {
    await _bleService.disconnect();
    _config = DeviceConfig.empty();
  }

  // ========== 读取操作 ==========

  /// 读取完整配置（根据设备角色自动选择顺序）
  Future<DeviceConfig> readAllConfig() async {
    // 读取设备信息
    final deviceInfo = await _bleService.readDeviceInfo();
    _config = _config.copyWith(deviceInfo: deviceInfo);

    // 读取串口配置
    final uartConfig = await _bleService.readUartConfig();
    _config = _config.copyWith(uartConfig: uartConfig);

    // 读取 Modbus 配置
    final modbusConfig = await _bleService.readModbusConfig();
    _config = _config.copyWith(modbusConfig: modbusConfig);

    // ROOT 专属：读取白名单和功率
    if (deviceInfo.isRoot) {
      final whiteList = await _bleService.readWhiteList();
      _config = _config.copyWith(whiteList: whiteList);

      final powerConfig = await _bleService.readPower();
      _config = _config.copyWith(powerConfig: powerConfig);
    }

    return _config;
  }

  /// 读取设备信息
  Future<DeviceInfo> readDeviceInfo() async {
    final info = await _bleService.readDeviceInfo();
    _config = _config.copyWith(deviceInfo: info);
    return info;
  }

  /// 读取串口配置
  Future<UartConfig> readUartConfig() async {
    final config = await _bleService.readUartConfig();
    _config = _config.copyWith(uartConfig: config);
    return config;
  }

  /// 读取 Modbus 配置
  Future<ModbusConfig> readModbusConfig() async {
    final config = await _bleService.readModbusConfig();
    _config = _config.copyWith(modbusConfig: config);
    return config;
  }

  /// 读取白名单
  Future<List<WhiteListItem>> readWhiteList() async {
    final items = await _bleService.readWhiteList();
    _config = _config.copyWith(whiteList: items);
    return items;
  }

  /// 读取功率
  Future<PowerConfig> readPower() async {
    final config = await _bleService.readPower();
    _config = _config.copyWith(powerConfig: config);
    return config;
  }

  // ========== 写入操作 ==========

  /// 写入完整配置（根据设备角色自动选择顺序）
  /// 返回操作结果描述
  Future<String> writeAllConfig({
    int? role,
    UartConfig? uartConfig,
    ModbusConfig? modbusConfig,
    PowerConfig? powerConfig,
    List<WhiteListItem>? whiteList,
  }) async {
    final results = <String>[];
    final errors = <String>[];

    // 1. 设置角色（如果指定）
    if (role != null) {
      try {
        await _bleService.setRole(role);
        results.add('✓ 角色设置成功');
      } catch (e) {
        errors.add('✗ 角色设置失败: $e');
      }
    }

    // 2. 设置串口配置
    if (uartConfig != null) {
      try {
        await _bleService.setUartConfig(uartConfig);
        _config = _config.copyWith(uartConfig: uartConfig);
        results.add('✓ 串口配置成功');
      } catch (e) {
        errors.add('✗ 串口配置失败: $e');
      }
    }

    // 3. 设置 Modbus 配置
    if (modbusConfig != null) {
      try {
        await _bleService.setModbusConfig(modbusConfig);
        _config = _config.copyWith(modbusConfig: modbusConfig);
        results.add('✓ Modbus 配置成功');
      } catch (e) {
        errors.add('✗ Modbus 配置失败: $e');
      }
    }

    // 4. ROOT 专属：设置功率
    if (isRoot && powerConfig != null) {
      try {
        await _bleService.setPower(powerConfig);
        _config = _config.copyWith(powerConfig: powerConfig);
        results.add('✓ 功率设置成功');
      } catch (e) {
        errors.add('✗ 功率设置失败: $e');
      }
    }

    // 5. ROOT 专属：白名单操作
    if (isRoot && whiteList != null) {
      // 5.1 获取当前白名单的 MAC 列表
      final currentMacs = _config.whiteList.map((e) => e.mac).toSet();
      final newMacs = whiteList.map((e) => e.mac).toSet();

      // 5.2 删除不在新列表中的条目
      final toDelete = currentMacs.difference(newMacs);
      for (final mac in toDelete) {
        try {
          await _bleService.delWhiteListItem(mac);
          results.add('✓ 删除白名单条目 $mac');
        } catch (e) {
          errors.add('✗ 删除白名单条目 $mac 失败: $e');
        }
      }

      // 5.3 添加新条目
      final toAdd = newMacs.difference(currentMacs);
      for (final item in whiteList) {
        if (toAdd.contains(item.mac)) {
          try {
            await _bleService.addWhiteListItem(item.mac, item.name);
            results.add('✓ 添加白名单条目 ${item.name}');
          } catch (e) {
            errors.add('✗ 添加白名单条目 ${item.name} 失败: $e');
          }
        }
      }

      // 更新缓存
      _config = _config.copyWith(whiteList: whiteList);
    }

    // 6. 提交保存
    try {
      await _bleService.commit();
      results.add('✓ 配置已保存');
    } catch (e) {
      errors.add('✗ 保存失败: $e');
    }

    // 返回结果
    if (errors.isEmpty) {
      return '配置完成:\n${results.join('\n')}';
    } else {
      return '部分失败:\n${results.join('\n')}\n${errors.join('\n')}';
    }
  }

  /// 写入串口配置
  Future<void> writeUartConfig(UartConfig config) async {
    await _bleService.setUartConfig(config);
    _config = _config.copyWith(uartConfig: config);
  }

  /// 写入 Modbus 配置
  Future<void> writeModbusConfig(ModbusConfig config) async {
    await _bleService.setModbusConfig(config);
    _config = _config.copyWith(modbusConfig: config);
  }

  /// 写入功率
  Future<void> writePower(PowerConfig config) async {
    await _bleService.setPower(config);
    _config = _config.copyWith(powerConfig: config);
  }

  /// 添加白名单条目
  Future<void> addWhiteListItem(String mac, String name) async {
    await _bleService.addWhiteListItem(mac, name);
    final newList = List<WhiteListItem>.from(_config.whiteList);
    newList.add(WhiteListItem(mac: mac, name: name));
    _config = _config.copyWith(whiteList: newList);
  }

  /// 添加完整的白名单条目（包含串口参数和 Modbus 配置）
  Future<void> addWhiteListItemFull(WhiteListItem item) async {
    await _bleService.addWhiteListItemFull(item);
    final newList = List<WhiteListItem>.from(_config.whiteList);
    newList.add(item);
    _config = _config.copyWith(whiteList: newList);
  }

  /// 设置子节点配置
  Future<void> setChildNodeConfig(WhiteListItem item) async {
    await _bleService.setChildNodeConfig(item);
  }

  /// 删除白名单条目
  Future<void> delWhiteListItem(String mac) async {
    await _bleService.delWhiteListItem(mac);
    final newList = _config.whiteList.where((e) => e.mac != mac).toList();
    _config = _config.copyWith(whiteList: newList);
  }

  /// 清空白名单
  Future<void> clearWhiteList() async {
    await _bleService.clearWhiteList();
    _config = _config.copyWith(whiteList: []);
  }

  /// 提交保存
  Future<void> commit() async {
    await _bleService.commit();
  }

  /// 重启设备
  Future<void> reboot() async {
    await _bleService.reboot();
  }

  /// 恢复出厂设置
  Future<void> factoryReset() async {
    await _bleService.factoryReset();
    _config = DeviceConfig.empty();
  }

  /// 释放资源
  void dispose() {
    _bleService.dispose();
  }
}

/// 协议服务管理器（单例）
class DtuServiceManager {
  static final DtuServiceManager _instance = DtuServiceManager._internal();
  factory DtuServiceManager() => _instance;
  DtuServiceManager._internal();

  late final DtuService _service;
  bool _initialized = false;

  /// 获取服务实例
  DtuService get service {
    if (!_initialized) {
      _service = DtuService(BleService());
      _initialized = true;
    }
    return _service;
  }

  /// 重新初始化
  void reinitialize() {
    _service.dispose();
    _initialized = false;
  }
}
