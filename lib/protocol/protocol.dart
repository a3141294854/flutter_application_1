/// DTU 配置协议 - 模块导出
///
/// 本模块实现了完整的 DTU 配置协议，包括：
/// - 协议常量定义
/// - 帧封装与解析
/// - 数据模型
/// - BLE 通信服务
/// - 协议服务
///
/// ## 使用示例
///
/// ```dart
/// import 'package:flutter_application_1/protocol/protocol.dart';
///
/// // 连接设备并读取配置
/// final service = DtuServiceManager().service;
/// await service.connect(device);
/// final config = await service.readAllConfig();
/// print('设备名称: ${config.deviceInfo?.name}');
///
/// // 修改配置
/// await service.writeUartConfig(UartConfig(
///   baudLevel: DtuProtocol.baudRateToLevel[115200]!,
///   parity: DtuProtocol.PARITY_NONE,
///   stopBits: DtuProtocol.STOP_BITS_1,
///   dataBits: DtuProtocol.DATA_BITS_8,
/// ));
/// await service.commit();
/// ```

export 'dtu_protocol.dart';
export 'dtu_frame.dart';
export 'dtu_models.dart';
export 'ble_service.dart';
export 'dtu_service.dart';
