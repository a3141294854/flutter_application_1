/// DTU 配置协议 - 常量定义
/// 基于 DTU配置协议.md 文档

class DtuProtocol {
  // ========== 帧格式常量 ==========
  /// 固定帧头 (0xAA55)
  static const int SOF = 0xAA55;

  // ========== 命令字 ==========
  /// 读取类命令
  static const int CMD_READ_DEV_INFO = 0x01;       // 读取设备信息
  static const int CMD_READ_UART_CFG = 0x02;        // 读取串口配置
  static const int CMD_READ_MODBUS_CFG = 0x03;      // 读取 Modbus 预设
  static const int CMD_READ_ROOT_WL_ALL = 0x04;     // 读取 ROOT 白名单
  static const int CMD_READ_ROOT_POWER = 0x05;      // 读取 ROOT 功率
  static const int CMD_GET_MODE_STATUS = 0x06;      // 获取模式状态
  static const int CMD_READ_WL_NODE_CFG = 0x07;     // 读取白名单节点配置

  /// 写入类命令
  static const int CMD_SET_ROLE = 0x10;             // 设置角色
  static const int CMD_SET_UART_CFG = 0x11;        // 设置串口配置
  static const int CMD_SET_MODBUS_CFG = 0x12;      // 设置 Modbus 预设
  static const int CMD_SET_ROOT_POWER = 0x13;     // 设置 ROOT 功率
  static const int CMD_ADD_WL_ITEM = 0x14;         // 添加白名单条目
  static const int CMD_DEL_WL_ITEM = 0x15;         // 删除白名单条目
  static const int CMD_CLEAR_WL = 0x16;            // 清空白名单
  static const int CMD_SET_WL_NODE_CFG = 0x17; // 设置白名单节点配置

  /// 控制类命令
  static const int CMD_COMMIT = 0x20;              // 提交保存
  static const int CMD_REBOOT = 0x21;              // 重启
  static const int CMD_FACTORY_RESET = 0x22;       // 恢复出厂

  // ========== 状态码 ==========
  static const int STATUS_SUCCESS = 0x00;          // 成功
  static const int STATUS_CRC_ERROR = 0x01;         // CRC 错误
  static const int STATUS_LENGTH_ERROR = 0x02;     // 长度错误
  static const int STATUS_CMD_ERROR = 0x03;        // 命令错误
  static const int STATUS_PARAM_ERROR = 0x04;      // 参数错误
  static const int STATUS_NOT_CONFIG_MODE = 0x05;  // 不在配置模式
  static const int STATUS_ROLE_MISMATCH = 0x06;    // 角色不匹配
  static const int STATUS_WHITELIST_FULL = 0x07;   // 白名单已满
  static const int STATUS_NOT_FOUND = 0x08;        // 未找到
  static const int STATUS_SAVE_FAILED = 0x09;     // 保存失败
  static const int STATUS_BUSY = 0x0A;             // 忙

  // ========== 角色枚举 ==========
  static const int ROLE_NODE = 0x00;               // 节点
  static const int ROLE_ROOT = 0x01;              // 根节点

  // ========== 波特率挡位 ==========
  static const Map<int, int> baudRateMap = {
    0x00: 1200,
    0x01: 2400,
    0x02: 4800,
    0x03: 9600,
    0x04: 19200,
    0x05: 38400,
    0x06: 57600,
    0x07: 115200,
  };

  static const Map<int, int> baudRateToLevel = {
    1200: 0x00,
    2400: 0x01,
    4800: 0x02,
    9600: 0x03,
    19200: 0x04,
    38400: 0x05,
    57600: 0x06,
    115200: 0x07,
  };

  // ========== 校验位 ==========
  static const int PARITY_NONE = 0x00;
  static const int PARITY_EVEN = 0x01;
  static const int PARITY_ODD = 0x02;

  // ========== 停止位 ==========
  static const int STOP_BITS_1 = 0x01;
  static const int STOP_BITS_2 = 0x02;

  // ========== 数据位 ==========
  static const int DATA_BITS_7 = 0x07;
  static const int DATA_BITS_8 = 0x08;

  // ========== 设备类型 ==========
  static const int DEV_TYPE_THREE_PHASE_METER = 0x01;   // 三相电表
  static const int DEV_TYPE_SINGLE_PHASE_METER = 0x02; // 单相电表
  static const int DEV_TYPE_TEMP_HUMIDITY = 0x03;      // 温湿度变送器
  static const int DEV_TYPE_RELAY = 0x04;              // 继电器
  static const int DEV_TYPE_RESERVED = 0x05;           // 其他预留

  static const Map<int, String> deviceTypeNames = {
    DEV_TYPE_RESERVED: '其他预留',
    DEV_TYPE_THREE_PHASE_METER: '三相电表',
    DEV_TYPE_SINGLE_PHASE_METER: '单相电表',
    DEV_TYPE_TEMP_HUMIDITY: '温湿度变送器',
    DEV_TYPE_RELAY: '继电器',
  };

  static const Map<String, int> deviceTypeValues = {
    '其他预留': DEV_TYPE_RESERVED,
    '三相电表': DEV_TYPE_THREE_PHASE_METER,
    '单相电表': DEV_TYPE_SINGLE_PHASE_METER,
    '温湿度变送器': DEV_TYPE_TEMP_HUMIDITY,
    '继电器': DEV_TYPE_RELAY,
  };

  // ========== 状态码名称 ==========
  static const Map<int, String> statusNames = {
    STATUS_SUCCESS: '成功',
    STATUS_CRC_ERROR: 'CRC 错误',
    STATUS_LENGTH_ERROR: '长度错误',
    STATUS_CMD_ERROR: '命令错误',
    STATUS_PARAM_ERROR: '参数错误',
    STATUS_NOT_CONFIG_MODE: '不在配置模式',
    STATUS_ROLE_MISMATCH: '角色不匹配',
    STATUS_WHITELIST_FULL: '白名单已满',
    STATUS_NOT_FOUND: '未找到',
    STATUS_SAVE_FAILED: '保存失败',
    STATUS_BUSY: '设备忙',
  };

  // ========== 角色名称 ==========
  static const Map<int, String> roleNames = {
    ROLE_NODE: 'NODE',
    ROLE_ROOT: 'ROOT',
  };

  // ========== 校验名称 ==========
  static const Map<int, String> parityNames = {
    PARITY_NONE: 'None',
    PARITY_EVEN: 'Even',
    PARITY_ODD: 'Odd',
  };

  static String getStatusName(int status) {
    return statusNames[status] ?? '未知错误($status)';
  }

  static String getRoleName(int role) {
    return roleNames[role] ?? '未知角色($role)';
  }

  static String getDeviceTypeName(int type) {
    return deviceTypeNames[type] ?? '未知设备($type)';
  }

  static int getDeviceTypeValue(String name) {
    return deviceTypeValues[name] ?? DEV_TYPE_RESERVED;
  }

  static String getParityName(int parity) {
    return parityNames[parity] ?? 'None';
  }

  static int getBaudRate(int level) {
    return baudRateMap[level] ?? 9600;
  }

  static int getBaudRateLevel(int baudRate) {
    return baudRateToLevel[baudRate] ?? 0x03; // 默认 9600
  }
}
