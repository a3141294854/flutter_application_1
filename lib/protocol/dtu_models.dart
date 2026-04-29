/// DTU 配置协议 - 数据模型
/// 定义设备配置相关的数据结构

import 'dart:typed_data';
import 'dart:developer' as developer;
import 'dtu_protocol.dart';
import 'dtu_frame.dart';

/// 设备信息
class DeviceInfo {
  final int role;
  final String mac;
  final String name;

  DeviceInfo({
    required this.role,
    required this.mac,
    required this.name,
  });

  /// 从响应 BODY 解析
  factory DeviceInfo.fromBytes(Uint8List body) {
    if (body.length < 9) {
      throw FormatException('设备信息数据长度不足: ${body.length}');
    }

    final status = body[0];
    if (status != DtuProtocol.STATUS_SUCCESS) {
      throw FormatException('读取设备信息失败: ${DtuProtocol.getStatusName(status)}');
    }

    final role = body[1];
    final mac = DtuFrame.formatMac(body.sublist(2, 8).toList());
    final nameLen = body[8];
    final name = String.fromCharCodes(body.sublist(9, 9 + nameLen));

    return DeviceInfo(role: role, mac: mac, name: name);
  }

  String get roleName => DtuProtocol.getRoleName(role);
  bool get isRoot => role == DtuProtocol.ROLE_ROOT;
  bool get isNode => role == DtuProtocol.ROLE_NODE;

  @override
  String toString() => 'DeviceInfo(role: $roleName, mac: $mac, name: $name)';
}

/// 串口配置
class UartConfig {
  final int baudLevel;
  final int parity;
  final int stopBits;
  final int dataBits;

  UartConfig({
    required this.baudLevel,
    required this.parity,
    required this.stopBits,
    required this.dataBits,
  });

  /// 从响应 BODY 解析
  factory UartConfig.fromBytes(Uint8List body) {
    if (body.length < 5) {
      throw FormatException('串口配置数据长度不足: ${body.length}');
    }

    final status = body[0];
    if (status != DtuProtocol.STATUS_SUCCESS) {
      throw FormatException('读取串口配置失败: ${DtuProtocol.getStatusName(status)}');
    }

    return UartConfig(
      baudLevel: body[1],
      parity: body[2],
      stopBits: body[3],
      dataBits: body[4],
    );
  }

  /// 默认配置
  factory UartConfig.defaultConfig() {
    return UartConfig(
      baudLevel: 0x03, // 9600
      parity: DtuProtocol.PARITY_NONE,
      stopBits: DtuProtocol.STOP_BITS_1,
      dataBits: DtuProtocol.DATA_BITS_8,
    );
  }

  int get baudRate => DtuProtocol.getBaudRate(baudLevel);
  String get parityName => DtuProtocol.getParityName(parity);
  String get dataBitsStr => '$dataBits';
  String get stopBitsStr => '$stopBits';

  /// 转换为字节列表
  List<int> toBytes() {
    return [baudLevel, parity, stopBits, dataBits];
  }

  @override
  String toString() =>
      'UartConfig(baud: $baudRate, parity: $parityName, stop: $stopBits, data: $dataBits)';
}

/// Modbus 预设项
class ModbusItem {
  final int addr;
  final int devType;

  ModbusItem({
    required this.addr,
    required this.devType,
  });

  /// 从字节解析
  factory ModbusItem.fromBytes(int addr, int devType) {
    return ModbusItem(addr: addr, devType: devType);
  }

  /// 转换为字节
  List<int> toBytes() => [addr, devType];

  String get deviceTypeName => DtuProtocol.getDeviceTypeName(devType);

  @override
  String toString() => 'ModbusItem(addr: $addr, type: $deviceTypeName)';
}

/// Modbus 配置
class ModbusConfig {
  final List<ModbusItem> items;

  ModbusConfig({required this.items});

  /// 从响应 BODY 解析
  factory ModbusConfig.fromBytes(Uint8List body) {
    void log(String msg) => developer.log(msg, name: 'ModbusConfig');
    
    log('body length: ${body.length}');
    if (body.length >= 2) {
      log('first 2 bytes: [0x${body[0].toRadixString(16).toUpperCase()}, 0x${body[1].toRadixString(16).toUpperCase()}]');
    }
    if (body.length >= 6) {
      log('first 6 bytes: ${body.sublist(0, 6).map((b) => '0x${b.toRadixString(16).toUpperCase()}').join(', ')}');
    }
    
    if (body.length < 2) {
      throw FormatException('Modbus 配置数据长度不足: ${body.length}');
    }

    final status = body[0];
    log('status: 0x${status.toRadixString(16).toUpperCase()}');
    if (status != DtuProtocol.STATUS_SUCCESS) {
      throw FormatException('读取 Modbus 配置失败: ${DtuProtocol.getStatusName(status)}');
    }

    final itemCount = body[1];
    log('itemCount from response: $itemCount');
    
    final items = <ModbusItem>[];

    // 解析所有 Modbus 预设项
    // 预期格式: itemCount(1) + addr1(1) + devType1(1) + addr2(1) + devType2(1) + ...
    int parsedItems = 0;
    int offset = 2;
    while (offset + 1 < body.length && parsedItems < itemCount) {
      final addr = body[offset];
      int devType = body[offset + 1];
      if (devType == 0) devType = 0x05; // 0 非法，回退为"其他预留"
      items.add(ModbusItem(addr: addr, devType: devType));
      log('item[$parsedItems]: addr=$addr, devType=$devType (0x${devType.toRadixString(16).toUpperCase()})');
      offset += 2;
      parsedItems++;
    }

    log('parsed ${items.length} items (expected: $itemCount)');
    return ModbusConfig(items: items);
  }

  /// 默认配置（8 个空项）
  factory ModbusConfig.defaultConfig() {
    return ModbusConfig(
      items: List.generate(8, (i) => ModbusItem(addr: i + 1, devType: 0x05)),
    );
  }

  /// 转换为字节列表
  List<Map<String, int>> toBytesList() {
    return items.map((item) => {'addr': item.addr, 'dev_type': item.devType}).toList();
  }

  @override
  String toString() => 'ModbusConfig(items: ${items.length})';
}

/// 白名单条目（包含子节点完整配置）
class WhiteListItem {
  final String mac;
  final String name;
  // 串口参数
  final int baudLevel;
  final int dataBits;
  final int stopBits;
  final int parity;
  // Modbus 配置
  final List<ModbusItem> modbusItems;

  WhiteListItem({
    required this.mac,
    required this.name,
    this.baudLevel = 0x03, // 默认 9600
    this.dataBits = 0x08,
    this.stopBits = 0x01,
    this.parity = DtuProtocol.PARITY_NONE,
    List<ModbusItem>? modbusItems,
  }) : modbusItems = modbusItems ?? List.generate(8, (i) => ModbusItem(addr: i + 1, devType: 0x05));

  /// 获取地址列表（兼容用）
  List<int> get modbusAddresses => modbusItems.map((e) => e.addr).toList();

  /// V2: 从字节解析白名单条目（仅 MAC(6)，不再包含 name_len + name）
  /// name 字段设置为 mac 值（兼容旧代码）
  factory WhiteListItem.fromTag07(List<int> bytes) {
    if (bytes.length < 6) {
      throw FormatException('白名单条目数据长度不足: ${bytes.length}');
    }

    final mac = DtuFrame.formatMac(bytes.sublist(0, 6));
    // V2: 白名单不再包含 name 字段，name = mac 以便旧代码兼容
    return WhiteListItem(mac: mac, name: mac);
  }

  /// 从字节解析（Tag 0x08 请求格式：MAC + uart + modbus）
  /// BODY: MAC(6) + 波特率(1) + 校验位(1) + 停止位(1) + 数据位(1) + 从站个数(1) + (addr+dev_type)×N
  factory WhiteListItem.fromTag08(List<int> bytes) {
    if (bytes.length < 11) {
      throw FormatException('子节点配置数据长度不足: ${bytes.length}');
    }

    final mac = DtuFrame.formatMac(bytes.sublist(0, 6));
    final baudLevel = bytes[6];
    final parity = bytes[7];
    final stopBits = bytes[8];
    final dataBits = bytes[9];
    final modbusCount = bytes[10];

    // 解析 (addr + dev_type) 对
    final items = <ModbusItem>[];
    int offset = 11;
    while (offset + 1 < bytes.length && items.length < modbusCount) {
      items.add(ModbusItem(addr: bytes[offset], devType: bytes[offset + 1]));
      offset += 2;
    }

    return WhiteListItem(
      mac: mac,
      name: '', // Tag 0x08 不包含名称，需要和 Tag 0x07 配合使用
      baudLevel: baudLevel,
      dataBits: dataBits,
      stopBits: stopBits,
      parity: parity,
      modbusItems: items,
    );
  }

  /// 从 READ_WL_NODE_CFG 响应 BODY 解析（不包含 MAC）
  factory WhiteListItem.fromTag08Response(String mac, List<int> bytes) {
    if (bytes.length < 5) {
      throw FormatException('子节点配置响应数据长度不足: ${bytes.length}');
    }

    final baudLevel = bytes[0];
    final parity = bytes[1];
    final stopBits = bytes[2];
    final dataBits = bytes[3];
    final modbusCount = bytes[4];

    final items = <ModbusItem>[];
    int offset = 5;
    while (offset + 1 < bytes.length && items.length < modbusCount) {
      items.add(ModbusItem(addr: bytes[offset], devType: bytes[offset + 1]));
      offset += 2;
    }

    return WhiteListItem(
      mac: mac,
      name: '',
      baudLevel: baudLevel,
      dataBits: dataBits,
      stopBits: stopBits,
      parity: parity,
      modbusItems: items,
    );
  }

  /// 创建完整条目（合并 Tag 0x07 和 Tag 0x08）
  WhiteListItem copyWithFull({
    String? name,
    int? baudLevel,
    int? dataBits,
    int? stopBits,
    int? parity,
    List<ModbusItem>? modbusItems,
  }) {
    return WhiteListItem(
      mac: mac,
      name: name ?? this.name,
      baudLevel: baudLevel ?? this.baudLevel,
      dataBits: dataBits ?? this.dataBits,
      stopBits: stopBits ?? this.stopBits,
      parity: parity ?? this.parity,
      modbusItems: modbusItems ?? this.modbusItems,
    );
  }

  /// 获取波特率字符串
  String get baudRateStr => DtuProtocol.getBaudRate(baudLevel).toString();

  /// 获取 Modbus 地址列表字符串
  String get modbusStr {
    if (modbusItems.isEmpty) return '无';
    return modbusItems.map((e) => '${e.addr}').join(', ');
  }

  /// 字节长度（Tag 0x07）
  int get tag07ByteLength => 6 + 1 + name.length;

  /// 字节长度（Tag 0x08）
  /// BODY: MAC(6) + 波特率(1) + 数据位(1) + 停止位(1) + 校验位(1) + 从站个数(1) + (addr+dev_type)×N
  int get tag08ByteLength => 6 + 4 + 1 + modbusItems.length * 2;

  @override
  String toString() =>
      'WhiteListItem(mac: $mac, name: $name, baud: $baudRateStr)';
}

/// 白名单读取结果（支持分片）
class WhiteListResult {
  final int fragIdx;
  final int fragTotal;
  final int wlTotal;
  final int itemCount;
  final List<WhiteListItem> items;
  final bool isComplete;

  WhiteListResult({
    required this.fragIdx,
    required this.fragTotal,
    required this.wlTotal,
    required this.itemCount,
    required this.items,
  }) : isComplete = fragTotal <= 1 || fragIdx == fragTotal || fragIdx == fragTotal - 1;

  /// V2: 从响应 BODY 解析白名单（每条 item 仅 6 字节 MAC）
  factory WhiteListResult.fromBytes(Uint8List body) {
    if (body.length < 5) {
      throw FormatException('白名单数据长度不足: ${body.length}');
    }

    final status = body[0];
    if (status != DtuProtocol.STATUS_SUCCESS) {
      throw FormatException('读取白名单失败: ${DtuProtocol.getStatusName(status)}');
    }

    final fragIdx = body[1];
    final fragTotal = body[2];
    final wlTotal = body[3];
    final itemCount = body[4];

    // V2: 每个 item 固定 6 字节（仅 MAC），不再包含 name_len + name
    final items = <WhiteListItem>[];
    int offset = 5;
    for (int i = 0; i < itemCount; i++) {
      if (offset + 6 > body.length) break;
      final itemBytes = body.sublist(offset, offset + 6);
      items.add(WhiteListItem.fromTag07(itemBytes));
      offset += 6;
    }

    return WhiteListResult(
      fragIdx: fragIdx,
      fragTotal: fragTotal,
      wlTotal: wlTotal,
      itemCount: itemCount,
      items: items,
    );
  }

  @override
  String toString() =>
      'WhiteListResult(frag: $fragIdx/$fragTotal, total: $wlTotal, items: $itemCount)';
}

/// 模式状态
class ModeStatus {
  final int currentMode;
  final int role;
  final int baudLevel;
  final int parity;
  final int stopBits;
  final int dataBits;
  final int modeSource;
  final int rxProfile;
  final int rebootPending;

  ModeStatus({
    required this.currentMode,
    required this.role,
    required this.baudLevel,
    required this.parity,
    required this.stopBits,
    required this.dataBits,
    required this.modeSource,
    required this.rxProfile,
    required this.rebootPending,
  });

  /// 从响应 BODY 解析
  factory ModeStatus.fromBytes(Uint8List body) {
    if (body.length < 9) {
      throw FormatException('模式状态数据长度不足: ${body.length}');
    }

    final status = body[0];
    if (status != DtuProtocol.STATUS_SUCCESS) {
      throw FormatException('获取模式状态失败: ${DtuProtocol.getStatusName(status)}');
    }

    return ModeStatus(
      currentMode: body[1],
      role: body[2],
      baudLevel: body[3],
      parity: body[4],
      stopBits: body[5],
      dataBits: body[6],
      modeSource: body[7],
      rxProfile: body[8],
      rebootPending: body[9],
    );
  }

  /// 模式名称
  String get modeName => currentMode == 0x01 ? 'CONFIG' : 'RUN';

  /// 角色名称
  String get roleName => DtuProtocol.getRoleName(role);

  /// 波特率
  int get baudRate => DtuProtocol.getBaudRate(baudLevel);

  /// 校验名称
  String get parityName => DtuProtocol.getParityName(parity);

  /// 模式来源名称
  String get modeSourceName {
    switch (modeSource) {
      case 0x01: return 'GPIO拨码';
      case 0x02: return 'NV存储';
      case 0x03: return '默认';
      default: return '未知';
    }
  }

  @override
  String toString() =>
      'ModeStatus(mode: $modeName, role: $roleName, baud: $baudRate, source: $modeSourceName)';
}

/// 功率配置
class PowerConfig {
  final int power;

  PowerConfig({required this.power});

  /// 从响应 BODY 解析
  factory PowerConfig.fromBytes(Uint8List body) {
    if (body.length < 2) {
      throw FormatException('功率数据长度不足: ${body.length}');
    }

    final status = body[0];
    if (status != DtuProtocol.STATUS_SUCCESS) {
      throw FormatException('读取功率失败: ${DtuProtocol.getStatusName(status)}');
    }

    return PowerConfig(power: body[1]);
  }

  /// 默认功率
  factory PowerConfig.defaultConfig() {
    return PowerConfig(power: 3);
  }

  @override
  String toString() => 'PowerConfig(power: $power)';
}

/// 设备完整配置
class DeviceConfig {
  final DeviceInfo? deviceInfo;
  final UartConfig? uartConfig;
  final ModbusConfig? modbusConfig;
  final List<WhiteListItem> whiteList;
  final PowerConfig? powerConfig;

  DeviceConfig({
    this.deviceInfo,
    this.uartConfig,
    this.modbusConfig,
    this.whiteList = const [],
    this.powerConfig,
  });

  /// 创建空配置
  factory DeviceConfig.empty() {
    return DeviceConfig(
      uartConfig: UartConfig.defaultConfig(),
      modbusConfig: ModbusConfig.defaultConfig(),
      powerConfig: PowerConfig.defaultConfig(),
    );
  }

  /// 复制并更新
  DeviceConfig copyWith({
    DeviceInfo? deviceInfo,
    UartConfig? uartConfig,
    ModbusConfig? modbusConfig,
    List<WhiteListItem>? whiteList,
    PowerConfig? powerConfig,
  }) {
    return DeviceConfig(
      deviceInfo: deviceInfo ?? this.deviceInfo,
      uartConfig: uartConfig ?? this.uartConfig,
      modbusConfig: modbusConfig ?? this.modbusConfig,
      whiteList: whiteList ?? this.whiteList,
      powerConfig: powerConfig ?? this.powerConfig,
    );
  }

  bool get isRoot => deviceInfo?.isRoot ?? true;
}
