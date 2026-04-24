/// DTU 配置协议 - 帧封装与解析
/// 实现帧格式: SOF(2) + CMD(1) + SEQ(1) + LEN(2) + BODY(N) + CRC16(2)

import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'dtu_protocol.dart';

/// 协议帧封装与解析工具
class DtuFrame {
  /// 请求序号生成器
  static int _seqCounter = 0;

  /// 获取下一个请求序号
  static int nextSeq() {
    _seqCounter = (_seqCounter + 1) & 0xFF;
    return _seqCounter;
  }

  /// 重置序号（可选，用于同步）
  static void resetSeq([int value = 0]) {
    _seqCounter = value & 0xFF;
  }

  // ========== 帧构建 ==========

  /// 构建请求帧
  /// 帧格式: SOF(2) + CMD(1) + SEQ(1) + LEN(2) + BODY(N) + CRC16(2)
  static Uint8List buildFrame(int cmd, {List<int>? body}) {
    body ??= [];
    final bodyBytes = Uint8List.fromList(body);
    final bodyLen = bodyBytes.length;

    // 创建帧缓冲区
    // 总长度 = SOF(2) + CMD(1) + SEQ(1) + LEN(2) + BODY(N) + CRC(2)
    final frame = ByteData(2 + 1 + 1 + 2 + bodyLen + 2);

    // SOF (大端) = 0xAA55
    frame.setUint16(0, DtuProtocol.SOF, Endian.big);

    // CMD
    frame.setUint8(2, cmd);

    // SEQ
    frame.setUint8(3, nextSeq());

    // LEN (小端) = BODY 长度
    frame.setUint16(4, bodyLen, Endian.little);

    // BODY
    for (int i = 0; i < bodyLen; i++) {
      frame.setUint8(6 + i, bodyBytes[i]);
    }

    // CRC16 覆盖: CMD + SEQ + LEN(2) + BODY (不含SOF)
    final crcData = Uint8List.view(frame.buffer, 2, 1 + 1 + 2 + bodyLen);
    final crc = crc16Modbus(crcData);

    // CRC16 (小端)
    frame.setUint16(6 + bodyLen, crc, Endian.little);

    return frame.buffer.asUint8List();
  }

  /// 构建设备信息读取请求
  static Uint8List buildReadDevInfo() {
    return buildFrame(DtuProtocol.CMD_READ_DEV_INFO);
  }

  /// 构建串口配置读取请求
  static Uint8List buildReadUartCfg() {
    return buildFrame(DtuProtocol.CMD_READ_UART_CFG);
  }

  /// 构建 Modbus 配置读取请求
  static Uint8List buildReadModbusCfg() {
    return buildFrame(DtuProtocol.CMD_READ_MODBUS_CFG);
  }

  /// 构建白名单读取请求
  static Uint8List buildReadWhiteList() {
    return buildFrame(DtuProtocol.CMD_READ_ROOT_WL_ALL);
  }

  /// 构建功率读取请求
  static Uint8List buildReadPower() {
    return buildFrame(DtuProtocol.CMD_READ_ROOT_POWER);
  }

  /// 构建获取模式状态请求
  static Uint8List buildGetModeStatus() {
    return buildFrame(DtuProtocol.CMD_GET_MODE_STATUS);
  }

  /// 构建角色设置请求
  static Uint8List buildSetRole(int role) {
    return buildFrame(DtuProtocol.CMD_SET_ROLE, body: [role]);
  }

  /// 构建串口配置设置请求
  static Uint8List buildSetUartCfg({
    required int baudLevel,
    required int parity,
    required int stopBits,
    required int dataBits,
  }) {
    return buildFrame(
      DtuProtocol.CMD_SET_UART_CFG,
      body: [baudLevel, parity, stopBits, dataBits],
    );
  }

  /// 构建 Modbus 配置设置请求
  /// BODY格式: item_count(1) + (addr(1) + dev_type(1)) × N
  static Uint8List buildSetModbusCfg(List<Map<String, int>> items) {
    final body = <int>[];
    body.add(items.length); // item_count
    for (final item in items) {
      body.add(item['addr'] ?? 0);
      body.add(item['dev_type'] ?? 0);
    }
    return buildFrame(DtuProtocol.CMD_SET_MODBUS_CFG, body: body);
  }

  /// 构建功率设置请求
  static Uint8List buildSetPower(int power) {
    return buildFrame(DtuProtocol.CMD_SET_ROOT_POWER, body: [power]);
  }

  /// 构建添加白名单条目请求
  static Uint8List buildAddWhiteListItem(String mac, String name) {
    final macBytes = _parseMac(mac);
    final nameBytes = name.codeUnits;
    return buildFrame(
      DtuProtocol.CMD_ADD_WL_ITEM,
      body: [...macBytes, nameBytes.length, ...nameBytes],
    );
  }

  /// 构建设置子节点配置请求（Tag 0x08）
  /// BODY: MAC(6) + 波特率(1) + 数据位(1) + 停止位(1) + 校验位(1) + 从站个数(1) + (addr+dev_type)×N
  static Uint8List buildSetChildNodeConfig({
    required String mac,
    required int baudLevel,
    required int dataBits,
    required int stopBits,
    required int parity,
    required List<Map<String, int>> modbusItems,
  }) {
    final macBytes = _parseMac(mac);
    final modbusBytes = modbusItems.expand((item) => [item['addr'] ?? 0, item['dev_type'] ?? 0]).toList();
    return buildFrame(
      DtuProtocol.CMD_SET_CHILD_NODE_CFG,
      body: [
        ...macBytes,
        baudLevel,
        dataBits,
        stopBits,
        parity,
        modbusItems.length,
        ...modbusBytes,
      ],
    );
  }

  /// 构建批量设置白名单及子节点配置请求（Tag 0x07 + 0x08）
  /// 用于一次性设置完整的白名单条目
  static Uint8List buildSetWhiteListFull({
    required String mac,
    required String name,
    required int baudLevel,
    required int dataBits,
    required int stopBits,
    required int parity,
    required List<int> modbusAddresses,
  }) {
    final macBytes = _parseMac(mac);
    final nameBytes = name.codeUnits;
    return buildFrame(
      DtuProtocol.CMD_SET_WHITE_LIST_FULL,
      body: [
        ...macBytes,          // MAC 地址
        nameBytes.length,    // 名称长度
        ...nameBytes,        // 名称
        baudLevel,          // 波特率
        dataBits,           // 数据位
        stopBits,           // 停止位
        parity,             // 校验位
        modbusAddresses.length,  // Modbus 从站个数
        ...modbusAddresses, // 从站地址列表
      ],
    );
  }

  /// 构建删除白名单条目请求
  static Uint8List buildDelWhiteListItem(String mac) {
    final macBytes = _parseMac(mac);
    return buildFrame(DtuProtocol.CMD_DEL_WL_ITEM, body: macBytes);
  }

  /// 构建清空白名单请求
  static Uint8List buildClearWhiteList() {
    return buildFrame(DtuProtocol.CMD_CLEAR_WL);
  }

  /// 构建提交保存请求
  static Uint8List buildCommit() {
    return buildFrame(DtuProtocol.CMD_COMMIT);
  }

  /// 构建重启请求
  static Uint8List buildReboot() {
    return buildFrame(DtuProtocol.CMD_REBOOT);
  }

  /// 构建恢复出厂请求
  static Uint8List buildFactoryReset() {
    return buildFrame(DtuProtocol.CMD_FACTORY_RESET);
  }

  // ========== 帧解析 ==========

  /// 解析响应帧
  /// 返回 ParseResult，包含解析结果或错误信息
  static ParseResult parseFrame(Uint8List data) {
    if (data.length < 7) {
      return ParseResult.error('数据长度不足，最小需要 7 字节');
    }

    final frame = ByteData.view(data.buffer, data.offsetInBytes);

    // 验证 SOF
    final sof = frame.getUint16(0, Endian.big);
    if (sof != DtuProtocol.SOF) {
      return ParseResult.error('帧头错误: 0x${sof.toRadixString(16).padLeft(4, '0')}');
    }

    // 获取 CMD
    final cmd = frame.getUint8(2);

    // 获取 SEQ
    final seq = frame.getUint8(3);

    // 获取 LEN (小端)
    final len = frame.getUint16(4, Endian.little);

    // 验证数据长度
    final minLen = 6 + len + 2; // SOF(2) + CMD + SEQ + LEN(2) + BODY(N) + CRC(2)
    if (data.length < minLen) {
      return ParseResult.error('数据长度不足: 需要 $minLen, 实际 ${data.length}');
    }

    // 提取 BODY
    final body = Uint8List.view(data.buffer, data.offsetInBytes + 6, len);

    // 验证 CRC16
    final receivedCrc = frame.getUint16(6 + len, Endian.little);
    final crcData = Uint8List.view(data.buffer, data.offsetInBytes + 2, 4 + len);
    final calculatedCrc = crc16Modbus(crcData);

    debugPrint('[DtuFrame] CRC 验证:');
    debugPrint('  - CRC 数据范围: offset=${data.offsetInBytes + 2}, len=${4 + len}');
    debugPrint('  - CRC 数据: ${bytesToHex(Uint8List.fromList(crcData))}');
    debugPrint('  - 收到 CRC: 0x${receivedCrc.toRadixString(16).padLeft(4, '0').toUpperCase()}');
    debugPrint('  - 计算 CRC: 0x${calculatedCrc.toRadixString(16).padLeft(4, '0').toUpperCase()}');

    if (receivedCrc != calculatedCrc) {
      debugPrint('[DtuFrame] ❌ CRC 校验失败!');
      return ParseResult.error(
        'CRC 校验失败: 收到 0x${receivedCrc.toRadixString(16).padLeft(4, '0')}, '
        '计算 0x${calculatedCrc.toRadixString(16).padLeft(4, '0')}',
        status: DtuProtocol.STATUS_CRC_ERROR,
      );
    }

    debugPrint('[DtuFrame] ✅ CRC 校验通过!');

    return ParseResult.success(cmd: cmd, seq: seq, body: body);
  }

  /// 从流中搜索并解析帧
  /// 返回解析结果列表（可能有多帧）
  static List<ParseResult> parseStream(Uint8List data) {
    final results = <ParseResult>[];
    int offset = 0;

    // 调试日志：显示收到的原始数据
    debugPrint('[DtuFrame] parseStream 收到 ${data.length} 字节: ${bytesToHex(data)}');

    while (offset < data.length - 6) {
      // 查找 SOF (0xAA55)
      int sofIndex = -1;
      for (int i = offset; i < data.length - 1; i++) {
        if (data[i] == 0xAA && data[i + 1] == 0x55) {
          sofIndex = i;
          break;
        }
      }

      if (sofIndex == -1) {
        debugPrint('[DtuFrame] 未找到 SOF (0xAA55)，退出搜索');
        break;
      }

      debugPrint('[DtuFrame] 找到 SOF at index=$sofIndex');

      // 尝试解析从 SOF 开始的帧
      final remaining = data.length - sofIndex;
      if (remaining < 7) {
        debugPrint('[DtuFrame] 数据不足 (remaining=$remaining < 7)');
        break;
      }

      final frameData = Uint8List.view(data.buffer, data.offsetInBytes + sofIndex);

      // 尝试获取 LEN
      final len = frameData[4] | (frameData[5] << 8); // 小端
      final minFrameLen = 8 + len; // 2(SOF) + 1(CMD) + 1(SEQ) + 2(LEN) + N(BODY) + 2(CRC)

      debugPrint('[DtuFrame] LEN=$len, minFrameLen=$minFrameLen, remaining=$remaining');

      if (remaining < minFrameLen) {
        offset = sofIndex + 1;
        continue;
      }

      // 截取完整帧
      final completeFrame = Uint8List(minFrameLen);
      completeFrame.setRange(0, minFrameLen, frameData);

      debugPrint('[DtuFrame] 完整帧: ${bytesToHex(completeFrame)}');

      final result = parseFrame(completeFrame);
      debugPrint('[DtuFrame] parseFrame 结果: isSuccess=${result.isSuccess}, error=${result.error}');

      if (result.isSuccess) {
        results.add(result);
        offset = sofIndex + minFrameLen;
        debugPrint('[DtuFrame] 帧解析成功! offset 移动到 $offset');
      } else {
        offset = sofIndex + 1;
        debugPrint('[DtuFrame] 帧解析失败，offset 移动到 $offset');
      }
    }

    debugPrint('[DtuFrame] parseStream 完成，找到 ${results.length} 个有效帧');
    return results;
  }

  // ========== 工具方法 ==========

  /// CRC16-Modbus 计算
  static int crc16Modbus(List<int> data) {
    int crc = 0xFFFF;

    for (final byte in data) {
      crc ^= byte & 0xFF;
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x0001) != 0) {
          crc = (crc >> 1) ^ 0xA001;
        } else {
          crc >>= 1;
        }
      }
    }

    return crc & 0xFFFF;
  }

  /// 解析 MAC 地址字符串 (XX:XX:XX:XX:XX:XX -> List<int>)
  static List<int> _parseMac(String mac) {
    final parts = mac.split(':');
    if (parts.length != 6) {
      throw FormatException('无效的 MAC 地址格式: $mac');
    }
    return parts.map((p) => int.parse(p, radix: 16)).toList();
  }

  /// 将字节列表转换为 MAC 地址字符串
  static String formatMac(List<int> bytes) {
    if (bytes.length < 6) {
      return '00:00:00:00:00:00';
    }
    return bytes
        .take(6)
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(':');
  }

  /// 从 BODY 解析状态码
  static int getStatus(Uint8List body) {
    return body.isNotEmpty ? body[0] : -1;
  }

  /// 将十六进制字符串转换为字节列表
  static Uint8List hexToBytes(String hex) {
    final cleanHex = hex.replaceAll(' ', '').replaceAll('\n', '');
    final bytes = <int>[];
    for (int i = 0; i < cleanHex.length; i += 2) {
      bytes.add(int.parse(cleanHex.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(bytes);
  }

  /// 将字节列表转换为十六进制字符串
  static String bytesToHex(Uint8List bytes, {String separator = ' '}) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(separator);
  }
}

/// 解析结果
class ParseResult {
  final bool isSuccess;
  final int? cmd;
  final int? seq;
  final Uint8List? body;
  final String? error;
  final int? status;

  ParseResult._({
    required this.isSuccess,
    this.cmd,
    this.seq,
    this.body,
    this.error,
    this.status,
  });

  factory ParseResult.success({
    required int cmd,
    required int seq,
    required Uint8List body,
  }) {
    return ParseResult._(
      isSuccess: true,
      cmd: cmd,
      seq: seq,
      body: body,
      status: body.isNotEmpty ? body[0] : null,
    );
  }

  factory ParseResult.error(String message, {int? status}) {
    return ParseResult._(
      isSuccess: false,
      error: message,
      status: status,
    );
  }
}
