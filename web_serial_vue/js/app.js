/**
 * DTU 配置助手 - Vue 应用
 * 模块化的组件和逻辑
 * 包含完整的DTU协议实现，移植自Flutter应用程序
 */

// ========================================
// 消息提示组件
// ========================================
const Message = {
  show(text, type = 'info', duration = 3000) {
    const existing = document.querySelector('.message');
    if (existing) existing.remove();
    
    const el = document.createElement('div');
    el.className = `message ${type}`;
    el.textContent = text;
    document.body.appendChild(el);
    
    setTimeout(() => el.remove(), duration);
  },
  success(text) { this.show(text, 'success'); },
  error(text) { this.show(text, 'error'); },
  warning(text) { this.show(text, 'warning'); },
  info(text) { this.show(text, 'info'); }
};

// ========================================
// DTU 协议常量
// ========================================
const DtuProtocol = {
  // 帧格式常量
  SOF: 0xAA55,
  
  // 命令字
  CMD_READ_DEV_INFO: 0x01,
  CMD_READ_UART_CFG: 0x02,
  CMD_READ_MODBUS_CFG: 0x03,
  CMD_READ_ROOT_WL_ALL: 0x04,
  CMD_READ_ROOT_POWER: 0x05,
  CMD_GET_MODE_STATUS: 0x06,
  CMD_READ_WL_NODE_CFG: 0x07,     // 读取白名单节点配置
  
  CMD_SET_ROLE: 0x10,
  CMD_SET_UART_CFG: 0x11,
  CMD_SET_MODBUS_CFG: 0x12,
  CMD_SET_ROOT_POWER: 0x13,
  CMD_ADD_WL_ITEM: 0x14,
  CMD_DEL_WL_ITEM: 0x15,
  CMD_CLEAR_WL: 0x16,
  CMD_SET_WL_NODE_CFG: 0x17,     // 设置白名单节点配置
  
  CMD_COMMIT: 0x20,
  CMD_REBOOT: 0x21,
  CMD_FACTORY_RESET: 0x22,

  // 状态码
  STATUS_SUCCESS: 0x00,
  STATUS_CRC_ERROR: 0x01,
  STATUS_LENGTH_ERROR: 0x02,
  STATUS_CMD_ERROR: 0x03,
  STATUS_PARAM_ERROR: 0x04,
  STATUS_NOT_CONFIG_MODE: 0x05,
  STATUS_ROLE_MISMATCH: 0x06,
  STATUS_WHITELIST_FULL: 0x07,
  STATUS_NOT_FOUND: 0x08,
  STATUS_SAVE_FAILED: 0x09,
  STATUS_BUSY: 0x0A,

  // 角色枚举
  ROLE_NODE: 0x00,
  ROLE_ROOT: 0x01,

  // 波特率映射
  baudRateMap: {
    0x00: 1200,
    0x01: 2400,
    0x02: 4800,
    0x03: 9600,
    0x04: 19200,
    0x05: 38400,
    0x06: 57600,
    0x07: 115200,
  },

  baudRateToLevel: {
    1200: 0x00,
    2400: 0x01,
    4800: 0x02,
    9600: 0x03,
    19200: 0x04,
    38400: 0x05,
    57600: 0x06,
    115200: 0x07,
  },

  // 校验位
  PARITY_NONE: 0x00,
  PARITY_EVEN: 0x01,
  PARITY_ODD: 0x02,

  // 停止位
  STOP_BITS_1: 0x01,
  STOP_BITS_2: 0x02,

  // 数据位
  DATA_BITS_7: 0x07,
  DATA_BITS_8: 0x08,

  // 状态码名称
  statusNames: {
    0x00: '成功',
    0x01: 'CRC错误',
    0x02: '长度错误',
    0x03: '命令错误',
    0x04: '参数错误',
    0x05: '不在配置模式',
    0x06: '角色不匹配',
    0x07: '白名单已满',
    0x08: '未找到',
    0x09: '保存失败',
    0x0A: '设备忙',
  },

  getStatusName(status) {
    return this.statusNames[status] || `未知错误(0x${status.toString(16).padStart(2, '0')})`;
  },

  // 命令名称映射
  getCmdName(cmd) {
    const map = {
      0x01: 'READ_DEV_INFO',    0x02: 'READ_UART_CFG',   0x03: 'READ_MODBUS_CFG',
      0x04: 'READ_WL_CFG',      0x05: 'READ_POWER',      0x06: 'GET_MODE_STATUS',
      0x07: 'READ_WL_NODE_CFG',
      0x10: 'SET_ROLE',         0x11: 'SET_UART_CFG',    0x12: 'SET_MODBUS_CFG',
      0x13: 'SET_POWER',        0x14: 'ADD_WL_ITEM',     0x15: 'DEL_WL_ITEM',
      0x16: 'CLEAR_WL',         0x17: 'SET_WL_NODE_CFG',
      0x20: 'COMMIT',           0x21: 'REBOOT',          0x22: 'FACTORY_RESET',
      0x81: 'READ_DEV_INFO_RSP', 0x82: 'READ_UART_CFG_RSP', 0x83: 'READ_MODBUS_CFG_RSP',
      0x84: 'READ_WL_CFG_RSP',   0x85: 'READ_POWER_RSP',    0x86: 'GET_MODE_STATUS_RSP',
      0x87: 'READ_WL_NODE_CFG_RSP',
      0x90: 'SET_ROLE_RSP',      0x91: 'SET_UART_CFG_RSP',  0x92: 'SET_MODBUS_CFG_RSP',
      0x93: 'SET_POWER_RSP',     0x94: 'ADD_WL_ITEM_RSP',   0x95: 'DEL_WL_ITEM_RSP',
      0x96: 'CLEAR_WL_RSP',      0x97: 'SET_WL_NODE_CFG_RSP',
      0xA0: 'COMMIT_RSP',        0xA1: 'REBOOT_RSP',        0xA2: 'FACTORY_RESET_RSP',
    };
    return map[cmd] || `CMD_0x${cmd.toString(16).padStart(2, '0').toUpperCase()}`;
  },

  // 命令中文描述
  getCmdDescription(cmd, status) {
    const isResp = (cmd & 0x80) !== 0;
    const reqCmd = isResp ? (cmd & 0x7F) : cmd;
    const prefix = isResp ? '📥' : '📤';
    const statusStr = status !== undefined ? ` (${this.getStatusName(status)})` : '';
    const map = {
      0x01: `${prefix} 【设备信息】获取DTU的MAC地址、名称、角色${statusStr}`,
      0x02: `${prefix} 【串口配置】读取串口波特率/数据位/停止位/校验位${statusStr}`,
      0x03: `${prefix} 【Modbus配置】读取8个Modbus预设地址和类型${statusStr}`,
      0x04: `${prefix} 【白名单】读取白名单设备MAC列表${statusStr}`,
      0x05: `${prefix} 【功率】读取SLE发射功率等级${statusStr}`,
      0x06: `${prefix} 【模式状态】读取当前工作模式和角色${statusStr}`,
      0x07: `${prefix} 【子节点配置】读取白名单子节点的串口+Modbus配置${statusStr}`,
      0x10: `${prefix} 【设置角色】切换为ROOT/NODE模式${statusStr}`,
      0x11: `${prefix} 【串口配置】写入串口参数${statusStr}`,
      0x12: `${prefix} 【Modbus配置】写入8个Modbus预设${statusStr}`,
      0x13: `${prefix} 【功率设置】写入SLE发射功率${statusStr}`,
      0x14: `${prefix} 【添加白名单】添加子设备MAC到白名单${statusStr}`,
      0x15: `${prefix} 【删除白名单】从白名单移除子设备MAC${statusStr}`,
      0x16: `${prefix} 【清空白名单】清空所有白名单条目${statusStr}`,
      0x17: `${prefix} 【子节点配置】写入白名单子节点的串口+Modbus配置${statusStr}`,
      0x20: `${prefix} 【提交保存】将配置写入NV存储${statusStr}`,
      0x21: `${prefix} 【重启设备】执行设备重启${statusStr}`,
      0x22: `${prefix} 【恢复出厂】恢复出厂设置${statusStr}`,
    };
    return map[reqCmd] || `${prefix} 【命令 0x${reqCmd.toString(16).toUpperCase()}】${statusStr}`;
  },

  getBaudRate(level) {
    return this.baudRateMap[level] || 9600;
  },

  getBaudRateLevel(baudRate) {
    return this.baudRateToLevel[baudRate] || 0x03;
  },

  // 校验位名称
  parityNames: {
    0x00: 'None',
    0x01: 'Even',
    0x02: 'Odd',
  },

  getParityName(parity) {
    return this.parityNames[parity] || 'None';
  },

  // 设备类型
  DEV_TYPE_RESERVED: 0x05,
  DEV_TYPE_THREE_PHASE_METER: 0x01,
  DEV_TYPE_SINGLE_PHASE_METER: 0x02,
  DEV_TYPE_TEMP_HUMIDITY: 0x03,
  DEV_TYPE_RELAY: 0x04,

  deviceTypeNames: {
    0x01: '三相电表',
    0x02: '单相电表',
    0x03: '温湿度变送器',
    0x04: '继电器',
    0x05: '其他预留',
  },

  getDeviceTypeName(type) {
    return this.deviceTypeNames[type] || '未知设备';
  },

  // 角色名称
  roleNames: {
    0x00: 'NODE',
    0x01: 'ROOT',
  },

  getRoleName(role) {
    return this.roleNames[role] || '未知角色';
  },

  // 模式来源名称
  getModeSourceName(source) {
    switch (source) {
      case 0x01: return 'GPIO拨码';
      case 0x02: return 'NV存储';
      case 0x03: return '默认';
      default: return '未知';
    }
  }
};

// ========================================
// DTU 帧构建与解析
// ========================================
const DtuFrame = {
  // 请求序列计数器
  _seqCounter: 0,

  // 获取下一个序列号
  nextSeq() {
    this._seqCounter = (this._seqCounter + 1) & 0xFF;
    return this._seqCounter;
  },

  // 重置序列号
  resetSeq(value = 0) {
    this._seqCounter = value & 0xFF;
  },

  // CRC16-Modbus 计算函数 (移植自Flutter app)
  crc16Modbus(data) {
    let crc = 0xFFFF;
    
    for (const byte of data) {
      crc ^= byte & 0xFF;
      for (let i = 0; i < 8; i++) {
        if ((crc & 0x0001) !== 0) {
          crc = (crc >> 1) ^ 0xA001;
        } else {
          crc >>= 1;
        }
      }
    }
    
    return crc & 0xFFFF;
  },

  // 构建请求帧
  // 帧格式: SOF(2) + CMD(1) + SEQ(1) + LEN(2) + BODY(N) + CRC16(2)
  buildFrame(cmd, body = []) {
    const bodyBytes = new Uint8Array(body);
    const bodyLen = bodyBytes.length;
    
    // 创建帧缓冲区: SOF(2) + CMD(1) + SEQ(1) + LEN(2) + BODY(N) + CRC(2)
    const frame = new ArrayBuffer(2 + 1 + 1 + 2 + bodyLen + 2);
    const view = new DataView(frame);
    
    // 设置SOF (大端) = 0xAA55
    view.setUint16(0, DtuProtocol.SOF, false); // false = big endian
    
    // CMD
    view.setUint8(2, cmd);
    
    // SEQ - 自动递增
    const seq = this.nextSeq();
    view.setUint8(3, seq);
    
    // LEN (小端) = BODY长度
    view.setUint16(4, bodyLen, true); // true = little endian
    
    // BODY
    for (let i = 0; i < bodyLen; i++) {
      view.setUint8(6 + i, bodyBytes[i]);
    }
    
    // CRC16 覆盖: CMD + SEQ + LEN(2) + BODY (不含SOF)
    const crcData = new Uint8Array(frame, 2, 1 + 1 + 2 + bodyLen);
    const crc = this.crc16Modbus(crcData);
    
    // CRC16 (小端)
    view.setUint16(6 + bodyLen, crc, true);
    
    return new Uint8Array(frame);
  },

  // ========== 读取类命令 ==========
  
  // 构建设备信息读取请求
  buildReadDevInfo() {
    return this.buildFrame(DtuProtocol.CMD_READ_DEV_INFO);
  },

  // 构建串口配置读取请求
  buildReadUartCfg() {
    return this.buildFrame(DtuProtocol.CMD_READ_UART_CFG);
  },

  // 构建Modbus配置读取请求
  buildReadModbusCfg() {
    return this.buildFrame(DtuProtocol.CMD_READ_MODBUS_CFG);
  },

  // 构建白名单读取请求
  buildReadWhiteList() {
    return this.buildFrame(DtuProtocol.CMD_READ_ROOT_WL_ALL);
  },

  // 构建白名单节点配置读取请求
  // BODY: MAC(6)
  buildReadChildNodeConfig(mac) {
    const macBytes = this._parseMac(mac);
    return this.buildFrame(DtuProtocol.CMD_READ_WL_NODE_CFG, macBytes);
  },

  // 构建功率读取请求
  buildReadPower() {
    return this.buildFrame(DtuProtocol.CMD_READ_ROOT_POWER);
  },

  // 构建模式状态读取请求
  buildGetModeStatus() {
    return this.buildFrame(DtuProtocol.CMD_GET_MODE_STATUS);
  },

  // ========== 写入类命令 ==========

  // 构建角色设置请求
  buildSetRole(role) {
    return this.buildFrame(DtuProtocol.CMD_SET_ROLE, [role]);
  },

  // 构建串口配置设置请求 - 移植自Flutter app
  buildSetUartCfg({ baudLevel, parity, stopBits, dataBits }) {
    const body = [baudLevel, parity, stopBits, dataBits];
    return this.buildFrame(DtuProtocol.CMD_SET_UART_CFG, body);
  },

  // 构建Modbus配置设置请求 - 移植自Flutter app
  buildSetModbusCfg(items) {
    const body = [items.length]; // item_count
    for (const item of items) {
      body.push(item.addr || 0);
      body.push(item.devType || 0);
    }
    return this.buildFrame(DtuProtocol.CMD_SET_MODBUS_CFG, body);
  },

  // 构建功率设置请求
  buildSetPower(power) {
    return this.buildFrame(DtuProtocol.CMD_SET_ROOT_POWER, [power]);
  },

  // 构建添加白名单条目请求 (V2协议：只包含MAC，去掉name字段)
  buildAddWhiteListItem(mac) {
    const macBytes = this._parseMac(mac);
    return this.buildFrame(DtuProtocol.CMD_ADD_WL_ITEM, macBytes);
  },

  // 构建子节点配置设置请求 (CMD 0x17)
  // BODY: MAC(6) + 波特率(1) + 校验位(1) + 停止位(1) + 数据位(1) + 从站个数(1) + (addr+dev_type)×N
  buildSetChildNodeConfig({ mac, baudLevel, parity, stopBits, dataBits, modbusItems }) {
    const macBytes = this._parseMac(mac);
    const body = [
      ...macBytes,
      baudLevel,
      parity,
      stopBits,
      dataBits,
      modbusItems.length
    ];
    for (const item of modbusItems) {
      body.push(item.addr || 0);
      body.push(item.devType || 0x05);
    }
    return this.buildFrame(DtuProtocol.CMD_SET_WL_NODE_CFG, body);
  },

  // 构建删除白名单条目请求
  buildDelWhiteListItem(mac) {
    const macBytes = this._parseMac(mac);
    return this.buildFrame(DtuProtocol.CMD_DEL_WL_ITEM, macBytes);
  },

  // 构建清空白名单请求
  buildClearWhiteList() {
    return this.buildFrame(DtuProtocol.CMD_CLEAR_WL);
  },

  // ========== 控制类命令 ==========

  // 构建提交保存请求
  buildCommit() {
    return this.buildFrame(DtuProtocol.CMD_COMMIT);
  },

  // 构建重启请求
  buildReboot() {
    return this.buildFrame(DtuProtocol.CMD_REBOOT);
  },

  // 构建恢复出厂请求
  buildFactoryReset() {
    return this.buildFrame(DtuProtocol.CMD_FACTORY_RESET);
  },

  // ========== 辅助函数 ==========

  // 解析MAC地址字符串 (XX:XX:XX:XX:XX:XX -> Array<int>)
  _parseMac(mac) {
    const parts = mac.split(':');
    if (parts.length !== 6) {
      throw new Error(`无效的MAC地址格式: ${mac}`);
    }
    return parts.map(p => parseInt(p, 16));
  },

  // 将字节数组转换为MAC地址字符串
  formatMac(bytes) {
    if (bytes.length < 6) {
      return '00:00:00:00:00:00';
    }
    return bytes.slice(0, 6)
      .map(b => b.toString(16).padStart(2, '0').toUpperCase())
      .join(':');
  },

  // 从BODY中解析状态码
  getStatus(body) {
    return body && body.length > 0 ? body[0] : -1;
  },

  // 解析响应帧
  parseFrame(data) {
    if (data.length < 7) {
      return { success: false, error: '数据长度不足，最小需要 7 字节' };
    }

    const view = new DataView(data.buffer, data.byteOffset);
    
    // 验证 SOF
    const sof = view.getUint16(0, false); // big endian
    if (sof !== DtuProtocol.SOF) {
      const hexStr = sof.toString(16).padStart(4, '0').toUpperCase();
      return { success: false, error: `帧头错误: 0x${hexStr}` };
    }

    // 获取 CMD 和 SEQ
    const cmd = view.getUint8(2);
    const seq = view.getUint8(3);

    // 获取 LEN (小端)
    const len = view.getUint16(4, true);

    // 验证数据长度
    const minLen = 6 + len + 2; // SOF(2) + CMD + SEQ + LEN(2) + BODY(N) + CRC(2)
    if (data.length < minLen) {
      return { success: false, error: `数据长度不足: 需要 ${minLen}, 实际 ${data.length}` };
    }

    // 提取 BODY
    const body = data.slice(6, 6 + len);

    // 验证 CRC16
    const receivedCrc = view.getUint16(6 + len, true);
    const crcData = data.slice(2, 6 + len);
    const calculatedCrc = this.crc16Modbus(crcData);

    if (receivedCrc !== calculatedCrc) {
      const receivedHex = receivedCrc.toString(16).padStart(4, '0');
      const calcHex = calculatedCrc.toString(16).padStart(4, '0');
      return { 
        success: false, 
        error: `CRC校验失败: 收到 0x${receivedHex}, 计算 0x${calcHex}`,
        status: DtuProtocol.STATUS_CRC_ERROR
      };
    }

    return {
      success: true,
      cmd,
      seq,
      body,
      status: this.getStatus(body)
    };
  },

  // 从流中搜索并解析帧
  parseStream(data) {
    const results = [];
    let offset = 0;

    while (offset <= data.length - 7) {
      // 查找 SOF (0xAA55)
      let sofIndex = -1;
      for (let i = offset; i < data.length - 1; i++) {
        if (data[i] === 0xAA && data[i + 1] === 0x55) {
          sofIndex = i;
          break;
        }
      }

      if (sofIndex === -1) break;
      
      if (sofIndex > offset) {
        console.log(`丢弃无效前导字节: ${this.bytesToHex(data.slice(offset, sofIndex))}`);
      }

      offset = sofIndex;
      const remaining = data.length - offset;
      if (remaining < 7) break;

      // 获取LEN字节 (小端)
      const len = data[offset + 4] | (data[offset + 5] << 8);
      const minFrameLen = 8 + len; // 2(SOF) + 1(CMD) + 1(SEQ) + 2(LEN) + N(BODY) + 2(CRC)

      if (remaining < minFrameLen) break;

      const completeFrame = data.slice(offset, offset + minFrameLen);
      const result = this.parseFrame(completeFrame);

      if (result.success) {
        results.push(result);
        offset += minFrameLen;
      } else {
        offset += 1;
      }
    }

    const remainingBytes = offset < data.length ? data.slice(offset) : new Uint8Array(0);
    return { results, remaining: remainingBytes };
  },

  // 工具函数
  bytesToHex(bytes, separator = ' ') {
    return Array.from(bytes).map(b => b.toString(16).padStart(2, '0').toUpperCase()).join(separator);
  },

  hexToBytes(hex) {
    const cleanHex = hex.replace(/\s+/g, '');
    const bytes = [];
    for (let i = 0; i < cleanHex.length; i += 2) {
      bytes.push(parseInt(cleanHex.substr(i, 2), 16));
    }
    return new Uint8Array(bytes);
  }
};

// ========================================
// DTU 协议服务
// ========================================
const DtuService = {
  // 当前配置缓存
  config: {
    deviceInfo: null,
    uartConfig: null,
    modbusConfig: null,
    whiteList: [],
    powerConfig: null
  },

  // 是否已连接
  isConnected: false,

  // Web Serial端口实例
  port: null,
  reader: null,
  writable: null,

  // 构造函数
  constructor(sendLogFn = null, onDetailedLog = null) {
    this.onLog = sendLogFn || console.log;
    this.onDetailedLog = onDetailedLog || this.onLog;
    this.pendingRequests = new Map();
    this.receiveBuffer = new Uint8Array(0);
  },

  // ========== 连接管理 ==========

  // 检查Web Serial支持
  async checkSupport() {
    return 'serial' in navigator;
  },

  // 连接设备
  async connect(serialParams = { baudRate: 115200, dataBits: 8, stopBits: 1, parity: 'none' }) {
    try {
      this.onLog('SYS', '正在请求USB设备...');
      
      this.port = await navigator.serial.requestPort();
      await this.port.open({
        baudRate: serialParams.baudRate,
        dataBits: serialParams.dataBits,
        stopBits: serialParams.stopBits,
        parity: serialParams.parity
      });

      this.isConnected = true;
      this.onLog('USB', `连接成功 - ${serialParams.baudRate}bps`, 'success');
      
      // 启动数据接收
      this._startReading();
      return true;
    } catch (err) {
      this.onLog('ERR', `连接失败: ${err.message}`, 'error');
      this.isConnected = false;
      return false;
    }
  },

  // 断开连接
  async disconnect() {
    try {
      if (this.reader) {
        await this.reader.cancel();
        this.reader = null;
      }
      if (this.port) {
        await this.port.close();
        this.port = null;
      }
      this.isConnected = false;
      this.onLog('USB', '已断开连接');
    } catch (err) {
      this.onLog('ERR', `断开失败: ${err.message}`, 'error');
    }
  },

  // ========== 通信核心 ==========

  // 发送数据并等待响应 (移植自Flutter BleService.sendAndWait)
  async sendAndWait(frame, timeoutMs = 3000) {
    if (!this.isConnected || !this.port) {
      throw new Error('未连接到设备');
    }

    return new Promise((resolve, reject) => {
      const seq = frame[3]; // 从帧中获取SEQ
      const timeoutId = setTimeout(() => {
        this.pendingRequests.delete(seq);
        reject(new Error('响应超时'));
      }, timeoutMs);

      // 将请求加入待处理列表
      this.pendingRequests.set(seq, {
        resolve: (result) => {
          clearTimeout(timeoutId);
          resolve(result);
        },
        reject: (error) => {
          clearTimeout(timeoutId);
          reject(error);
        }
      });

      // 发送帧
      this._sendFrame(frame).catch(err => {
        clearTimeout(timeoutId);
        this.pendingRequests.delete(seq);
        reject(err);
      });
    });
  },

  // 发送帧数据
  async _sendFrame(frame) {
    if (!this.port) throw new Error('端口未打开');
    
    this.writable = this.port.writable;
    const writer = this.writable.getWriter();
    try {
      await writer.write(frame);
      const cmd = frame[2];
      const hexData = DtuFrame.bytesToHex(frame);
      this.onLog('TX', hexData, 'tx');
      // 详细日志
      this.onDetailedLog({
        direction: '发送',
        frame: frame,
        hexData: hexData,
        cmdName: DtuProtocol.getCmdName(cmd),
        description: DtuProtocol.getCmdDescription(cmd),
      });
    } finally {
      writer.releaseLock();
    }
  },

  // 处理接收到的数据
  _onDataReceived(data) {
    // 将接收数据加入缓冲区
    const newData = new Uint8Array(this.receiveBuffer.length + data.length);
    newData.set(this.receiveBuffer);
    newData.set(data, this.receiveBuffer.length);
    this.receiveBuffer = newData;

    // 尝试解析帧
    const parseResult = DtuFrame.parseStream(this.receiveBuffer);

    // 处理解析结果
    for (const result of parseResult.results) {
      if (result.success) {
        const cmd = result.frame?.[2] || 0;
        const status = result.body && result.body.length > 0 ? result.body[0] : undefined;
        const hexData = result.frame ? DtuFrame.bytesToHex(result.frame) : DtuFrame.bytesToHex(result.body);
        const desc = DtuProtocol.getCmdDescription(cmd, status);
        const hasError = status !== undefined && status !== 0;
        // 匹配已发起的请求
        const pending = this.pendingRequests.get(result.seq);
        if (pending) {
          pending.resolve(result);
          this.pendingRequests.delete(result.seq);
          this.onLog('RX', hexData, hasError ? 'warning' : 'success');
        } else {
          this.onLog('RX', hexData, 'info');
        }
        // 详细日志
        this.onDetailedLog({
          direction: '接收',
          frame: result.frame || null,
          hexData: hexData,
          cmdName: DtuProtocol.getCmdName(cmd),
          description: desc,
          error: hasError ? DtuProtocol.getStatusName(status) : null,
          level: hasError ? 'warning' : 'success',
        });
      } else {
        this.onLog('ERR', result.error, 'error');
      }
    }

    // 更新缓冲区
    this.receiveBuffer = parseResult.remaining;
  },

  // 启动读取循环
  async _startReading() {
    if (!this.port || !this.port.readable) return;

    while (this.port && this.port.readable) {
      this.reader = this.port.readable.getReader();
      try {
        while (true) {
          const { value, done } = await this.reader.read();
          if (done) break;
          if (value) {
            this._onDataReceived(value);
          }
        }
      } catch (err) {
        if (err.name !== 'AbortError') {
          this.onLog('ERR', `读取错误: ${err.message}`, 'error');
        }
      } finally {
        this.reader.releaseLock();
      }
    }
  },

  // ========== 读取操作 ==========

  // 读取设备信息
  async readDeviceInfo() {
    const frame = DtuFrame.buildReadDevInfo();
    const result = await this.sendAndWait(frame);
    if (!result.success) throw new Error(result.error);
    
    const body = Array.from(result.body);
    const deviceInfo = {
      role: body[1],
      mac: DtuFrame.formatMac(body.slice(2, 8)),
      name: String.fromCharCode(...body.slice(9, 9 + body[8]))
    };
    
    this.config.deviceInfo = deviceInfo;
    this.onLog('DEV', `角色: ${deviceInfo.role === 1 ? 'ROOT' : 'NODE'}, MAC: ${deviceInfo.mac}, 名称: ${deviceInfo.name}`, 'info');
    return deviceInfo;
  },

  // 读取串口配置
  async readUartCfg() {
    const frame = DtuFrame.buildReadUartCfg();
    const result = await this.sendAndWait(frame);
    if (!result.success) throw new Error(result.error);
    
    const body = Array.from(result.body);
    const uartConfig = {
      baudLevel: body[1],
      parity: body[2],
      stopBits: body[3],
      dataBits: body[4]
    };
    
    this.config.uartConfig = uartConfig;
    const baudRate = DtuProtocol.getBaudRate(uartConfig.baudLevel);
    this.onLog('UART', `波特率: ${baudRate}, 数据位: ${uartConfig.dataBits}, 停止位: ${uartConfig.stopBits}`, 'info');
    return uartConfig;
  },

  // 读取Modbus配置
  async readModbusCfg() {
    const frame = DtuFrame.buildReadModbusCfg();
    const result = await this.sendAndWait(frame);
    if (!result.success) throw new Error(result.error);
    
    const body = Array.from(result.body);
    const itemCount = body[1];
    const items = [];
    
    for (let i = 0; i < itemCount; i++) {
      const offset = 2 + i * 2;
      items.push({
        addr: body[offset],
        devType: body[offset + 1]
      });
    }
    
    this.config.modbusConfig = { items };
    this.onLog('MODBUS', `读取到 ${itemCount} 个Modbus预设`, 'info');
    return { items };
  },

  // 读取白名单 (需要ROOT权限)
  async readWhiteList() {
    const frame = DtuFrame.buildReadWhiteList();
    const result = await this.sendAndWait(frame);
    if (!result.success) throw new Error(result.error);
    
    const body = Array.from(result.body);
    const fragIdx = body[1];
    const fragTotal = body[2];
    const wlTotal = body[3];
    const itemCount = body[4];
    
    const whiteList = [];
    for (let i = 0; i < itemCount; i++) {
      const offset = 5 + i * 6;
      const macBytes = body.slice(offset, offset + 6);
      whiteList.push({
        mac: DtuFrame.formatMac(macBytes)
      });
    }
    
    this.config.whiteList = whiteList;
    this.onLog('WL', `白名单: 总条目 ${wlTotal}, 当前分片 ${itemCount}`, 'info');
    return whiteList;
  },

  // 读取白名单节点完整配置 (CMD 0x07)
  // BODY: MAC(6)
  // 响应: status + uart_cfg(4) + modbus_count + (addr + dev_type)×N
  async readChildNodeConfig(mac) {
    const frame = DtuFrame.buildReadChildNodeConfig(mac);
    const result = await this.sendAndWait(frame);
    if (!result.success) throw new Error(result.error);
    
    const body = Array.from(result.body);
    const status = body[0];
    if (status !== DtuProtocol.STATUS_SUCCESS) {
      throw new Error(`读取子节点配置失败: ${DtuProtocol.getStatusName(status)}`);
    }
    
    // uart_cfg: baudLevel(1) + parity(1) + stopBits(1) + dataBits(1)
    const baudLevel = body[1];
    const parity = body[2];
    const stopBits = body[3];
    const dataBits = body[4];
    
    // modbus_count + (addr + dev_type)×N
    const modbusCount = body[5];
    const modbusItems = [];
    for (let i = 0; i < modbusCount; i++) {
      const offset = 6 + i * 2;
      if (offset + 1 < body.length) {
        modbusItems.push({
          addr: body[offset],
          devType: body[offset + 1]
        });
      }
    }
    
    const baudRate = DtuProtocol.getBaudRate(baudLevel);
    this.onLog('NODE_CFG', `${mac} -> 波特率:${baudRate} 数据位:${dataBits} 停止位:${stopBits} Modbus:${modbusCount}项`, 'info');
    
    return {
      mac,
      baudLevel,
      parity,
      stopBits,
      dataBits,
      modbusItems,
      baudRate
    };
  },

  // 设置子节点配置 (CMD 0x17)
  async setChildNodeConfig(config) {
    const frame = DtuFrame.buildSetChildNodeConfig(config);
    const result = await this.sendAndWait(frame);
    if (!result.success) throw new Error(result.error);
    
    const status = DtuFrame.getStatus(result.body);
    if (status !== DtuProtocol.STATUS_SUCCESS) {
      throw new Error(`设置子节点配置失败: ${DtuProtocol.getStatusName(status)}`);
    }
    
    this.onLog('NODE_CFG', `${config.mac} 子节点配置已设置`, 'success');
  },

  // 完整添加白名单条目（V2: 仅发送MAC）
  async addWhiteListItemFull(item) {
    await this.addWhiteListItem(item.mac);
  },

  // 读取功率 (需要ROOT权限)
  async readPower() {
    const frame = DtuFrame.buildReadPower();
    const result = await this.sendAndWait(frame);
    if (!result.success) throw new Error(result.error);
    
    const body = Array.from(result.body);
    const power = body[1];
    
    this.config.powerConfig = { power };
    this.onLog('PWR', `读取功率: ${power}`, 'info');
    return { power };
  },

  // 读取模式状态
  async getModeStatus() {
    const frame = DtuFrame.buildGetModeStatus();
    const result = await this.sendAndWait(frame);
    if (!result.success) throw new Error(result.error);
    
    const body = Array.from(result.body);
    const modeStatus = {
      currentMode: body[1],
      role: body[2],
      baudLevel: body[3],
      parity: body[4],
      stopBits: body[5],
      dataBits: body[6],
      modeSource: body[7],
      rxProfile: body[8],
      rebootPending: body.length > 9 ? body[9] : 0
    };
    
    const modeName = modeStatus.currentMode === 0x01 ? 'CONFIG' : 'RUN';
    const roleName = DtuProtocol.getRoleName(modeStatus.role);
    const baudRate = DtuProtocol.getBaudRate(modeStatus.baudLevel);
    const sourceName = DtuProtocol.getModeSourceName(modeStatus.modeSource);
    this.onLog('MODE', `模式: ${modeName}, 角色: ${roleName}, 波特率: ${baudRate}, 来源: ${sourceName}`, 'info');
    return modeStatus;
  },

  // ========== 写入操作 ==========

  // 设置角色 (ROOT = 1, NODE = 0)
  async setRole(role) {
    const frame = DtuFrame.buildSetRole(role);
    const result = await this.sendAndWait(frame);
    if (!result.success) throw new Error(result.error);
    
    const status = DtuFrame.getStatus(result.body);
    if (status !== DtuProtocol.STATUS_SUCCESS) {
      throw new Error(`设置角色失败: ${DtuProtocol.getStatusName(status)}`);
    }
    
    this.onLog('ROLE', `角色已切换为: ${role === 1 ? 'ROOT' : 'NODE'}`, 'success');
  },

  // 设置串口配置
  async setUartCfg(config) {
    const frame = DtuFrame.buildSetUartCfg(config);
    const result = await this.sendAndWait(frame);
    if (!result.success) throw new Error(result.error);
    
    const status = DtuFrame.getStatus(result.body);
    if (status !== DtuProtocol.STATUS_SUCCESS) {
      throw new Error(`设置串口配置失败: ${DtuProtocol.getStatusName(status)}`);
    }
    
    this.config.uartConfig = config;
    this.onLog('UART', '串口配置已设置', 'success');
  },

  // 设置Modbus配置
  async setModbusCfg(items) {
    const frame = DtuFrame.buildSetModbusCfg(items);
    const result = await this.sendAndWait(frame);
    if (!result.success) throw new Error(result.error);
    
    const status = DtuFrame.getStatus(result.body);
    if (status !== DtuProtocol.STATUS_SUCCESS) {
      throw new Error(`设置Modbus配置失败: ${DtuProtocol.getStatusName(status)}`);
    }
    
    this.config.modbusConfig = { items };
    this.onLog('MODBUS', `已设置 ${items.length} 个Modbus预设`, 'success');
  },

  // 设置功率 (需要ROOT权限)
  async setPower(power) {
    const frame = DtuFrame.buildSetPower(power);
    const result = await this.sendAndWait(frame);
    if (!result.success) throw new Error(result.error);
    
    const status = DtuFrame.getStatus(result.body);
    if (status !== DtuProtocol.STATUS_SUCCESS) {
      throw new Error(`设置功率失败: ${DtuProtocol.getStatusName(status)}`);
    }
    
    this.config.powerConfig = { power };
    this.onLog('PWR', `功率已设置为: ${power}`, 'success');
  },

  // 添加白名单条目 (需要ROOT权限)
  async addWhiteListItem(mac) {
    const frame = DtuFrame.buildAddWhiteListItem(mac);
    const result = await this.sendAndWait(frame);
    if (!result.success) throw new Error(result.error);
    
    const status = DtuFrame.getStatus(result.body);
    if (status !== DtuProtocol.STATUS_SUCCESS) {
      throw new Error(`添加白名单失败: ${DtuProtocol.getStatusName(status)}`);
    }
    
    this.config.whiteList.push({ mac });
    this.onLog('WL', `已添加白名单: ${mac}`, 'success');
  },

  // 删除白名单条目 (需要ROOT权限)
  async delWhiteListItem(mac) {
    const frame = DtuFrame.buildDelWhiteListItem(mac);
    const result = await this.sendAndWait(frame);
    if (!result.success) throw new Error(result.error);
    
    const status = DtuFrame.getStatus(result.body);
    if (status !== DtuProtocol.STATUS_SUCCESS) {
      throw new Error(`删除白名单失败: ${DtuProtocol.getStatusName(status)}`);
    }
    
    this.config.whiteList = this.config.whiteList.filter(item => item.mac !== mac);
    this.onLog('WL', `已删除白名单: ${mac}`, 'success');
  },

  // 清空白名单 (需要ROOT权限)
  async clearWhiteList() {
    const frame = DtuFrame.buildClearWhiteList();
    const result = await this.sendAndWait(frame);
    if (!result.success) throw new Error(result.error);
    
    const status = DtuFrame.getStatus(result.body);
    if (status !== DtuProtocol.STATUS_SUCCESS) {
      throw new Error(`清空白名单失败: ${DtuProtocol.getStatusName(status)}`);
    }
    
    this.config.whiteList = [];
    this.onLog('WL', '白名单已清空', 'success');
  },

  // 提交保存
  async commit() {
    const frame = DtuFrame.buildCommit();
    const result = await this.sendAndWait(frame);
    if (!result.success) throw new Error(result.error);
    
    const status = DtuFrame.getStatus(result.body);
    if (status !== DtuProtocol.STATUS_SUCCESS) {
      throw new Error(`提交保存失败: ${DtuProtocol.getStatusName(status)}`);
    }
    
    this.onLog('SAVE', '配置已保存到NV存储', 'success');
  },

  // 重启设备
  async reboot() {
    const frame = DtuFrame.buildReboot();
    const result = await this.sendAndWait(frame);
    if (!result.success) throw new Error(result.error);
    
    const status = DtuFrame.getStatus(result.body);
    if (status !== DtuProtocol.STATUS_SUCCESS) {
      throw new Error(`重启失败: ${DtuProtocol.getStatusName(status)}`);
    }
    
    this.onLog('REBOOT', '设备正在重启...', 'warning');
  },

  // 恢复出厂设置
  async factoryReset() {
    const frame = DtuFrame.buildFactoryReset();
    const result = await this.sendAndWait(frame);
    if (!result.success) throw new Error(result.error);
    
    const status = DtuFrame.getStatus(result.body);
    if (status !== DtuProtocol.STATUS_SUCCESS) {
      throw new Error(`恢复出厂失败: ${DtuProtocol.getStatusName(status)}`);
    }
    
    this.config = {
      deviceInfo: null,
      uartConfig: null,
      modbusConfig: null,
      whiteList: [],
      powerConfig: null
    };
    
    this.onLog('RESET', '设备已恢复出厂设置', 'warning');
  },

  // ========== 完整配置管理 ==========

  // 读取完整配置
  async readAllConfig() {
    const results = [];
    
    // 读取设备信息
    const deviceInfo = await this.readDeviceInfo();
    results.push('✓ 设备信息已读取');
    
    // 读取串口配置
    const uartConfig = await this.readUartCfg();
    results.push('✓ 串口配置已读取');
    
    // 读取Modbus配置
    const modbusConfig = await this.readModbusCfg();
    results.push('✓ Modbus配置已读取');
    
    // ROOT设备独有的功能
    if (deviceInfo.role === DtuProtocol.ROLE_ROOT) {
      const whiteList = await this.readWhiteList();
      results.push('✓ 白名单已读取');
      
      const powerConfig = await this.readPower();
      results.push('✓ 功率配置已读取');
    }
    
    return results.join('\n');
  },

  // 写入完整配置
  async writeAllConfig({
    role = null,
    uartConfig = null,
    modbusItems = null,
    power = null,
    whiteListItems = null
  }) {
    const results = [];
    const errors = [];

    try {
      // 1. 设置角色
      if (role !== null) {
        await this.setRole(role);
        results.push('✓ 角色设置成功');
      }

      // 2. 设置串口配置
      if (uartConfig) {
        await this.setUartCfg(uartConfig);
        results.push('✓ 串口配置成功');
      }

      // 3. 设置Modbus配置
      if (modbusItems) {
        await this.setModbusCfg(modbusItems);
        results.push('✓ Modbus配置成功');
      }

      // 4. 设置功率 (ROOT模式下)
      if (power !== null && this.config.deviceInfo?.role === DtuProtocol.ROLE_ROOT) {
        await this.setPower(power);
        results.push('✓ 功率设置成功');
      }

      // 5. 白名单操作 (ROOT模式下)
      if (whiteListItems && this.config.deviceInfo?.role === DtuProtocol.ROLE_ROOT) {
        // 先清空现有白名单
        await this.clearWhiteList();
        
        // 添加新条目
        for (const item of whiteListItems) {
          await this.addWhiteListItem(item.mac);
        }
        
        results.push('✓ 白名单配置成功');
      }

      // 6. 提交保存
      await this.commit();
      results.push('✓ 配置已保存');

      return results.join('\n');
    } catch (err) {
      errors.push(`✗ ${err.message}`);
      return `配置写入失败:\n${results.join('\n')}\n${errors.join('\n')}`;
    }
  }
};

// ========================================
// 工具函数
// ========================================
const Utils = {
  // 格式化时间
  formatTime(date = new Date()) {
    return date.toLocaleTimeString('zh-CN', { hour12: false });
  },
  
  // 字节转十六进制字符串
  bytesToHex(bytes) {
    return Array.from(bytes).map(b => b.toString(16).padStart(2, '0').toUpperCase()).join(' ');
  },
  
  // 十六进制字符串转字节数组
  hexToBytes(hex) {
    const parts = hex.trim().split(/\s+/);
    return new Uint8Array(parts.map(p => parseInt(p, 16)));
  },
  
  // 格式化命令预览
  formatCommand(hex) {
    if (!hex) return '(空)';
    return hex.trim().split(/\s+/).map(p => p.toUpperCase()).join(' ');
  }
};

// ========================================
// Web Serial 通信模块
// ========================================
const SerialPort = {
  port: null,
  reader: null,
  writable: null,
  connected: false,
  
  async checkSupport() {
    return 'serial' in navigator;
  },
  
  async connect(options, callbacks = {}) {
    if (!await this.checkSupport()) {
      Message.error('您的浏览器不支持 Web Serial API，请使用 Chrome/Edge 浏览器');
      return false;
    }
    
    try {
      if (callbacks.onLog) callbacks.onLog('SYS', '正在请求USB设备...');
      
      this.port = await navigator.serial.requestPort();
      await this.port.open(options);
      this.connected = true;
      
      if (callbacks.onLog) callbacks.onLog('USB', `连接成功 - ${options.baudRate}bps`, 'success');
      if (callbacks.onConnect) callbacks.onConnect();
      
      this._startReading(callbacks);
      return true;
    } catch (err) {
      if (callbacks.onLog) callbacks.onLog('ERR', '连接失败: ' + err.message, 'error');
      this.connected = false;
      return false;
    }
  },
  
  async disconnect(callbacks = {}) {
    try {
      if (this.reader) {
        await this.reader.cancel();
        this.reader = null;
      }
      if (this.port) {
        await this.port.close();
        this.port = null;
      }
      this.connected = false;
      if (callbacks.onLog) callbacks.onLog('USB', '已断开连接');
      if (callbacks.onDisconnect) callbacks.onDisconnect();
    } catch (err) {
      if (callbacks.onLog) callbacks.onLog('ERR', '断开失败: ' + err.message, 'error');
    }
  },
  
  async send(hexString, callbacks = {}) {
    if (!this.connected || !this.port) {
      Message.warning('请先连接USB设备');
      return false;
    }
    
    try {
      const bytes = Utils.hexToBytes(hexString);
      this.writable = this.port.writable;
      const writer = this.writable.getWriter();
      await writer.write(bytes);
      writer.releaseLock();
      
      if (callbacks.onLog) callbacks.onLog('TX', hexString.toUpperCase(), 'tx');
      return true;
    } catch (err) {
      if (callbacks.onLog) callbacks.onLog('ERR', '发送失败: ' + err.message, 'error');
      return false;
    }
  },
  
  async _startReading(callbacks) {
    while (this.port && this.port.readable) {
      this.reader = this.port.readable.getReader();
      try {
        while (true) {
          const { value, done } = await this.reader.read();
          if (done) break;
          if (value) {
            const hex = Utils.bytesToHex(value);
            if (callbacks.onLog) callbacks.onLog('RX', hex, 'rx');
          }
        }
      } catch (err) {
        if (err.name !== 'AbortError') {
          if (callbacks.onLog) callbacks.onLog('ERR', '读取错误: ' + err.message, 'error');
        }
      } finally {
        this.reader.releaseLock();
      }
    }
  }
};

// ========================================
// 创建 Vue 应用
// ========================================
function initApp() {
  const { createApp, ref, computed, nextTick, onMounted, reactive } = Vue;
  
  const app = createApp({
    setup() {
      // Reactive state
      const currentPage = ref('settings');
      const serialConnected = ref(false);
      const scanning = ref(false);
      
      // 串口参数配置
      const serialParams = ref({
        baudRate: 115200,
        dataBits: 8,
        stopBits: 1,
        parity: 'none'
      });
      
      // 波特率选项
      const baudRates = [9600, 19200, 38400, 57600, 115200];
      const dataBitsOptions = [5, 6, 7, 8];
      const stopBitsOptions = [1, 2];
      const parityOptions = [
        { value: 'none', label: '无' },
        { value: 'even', label: '偶' },
        { value: 'odd', label: '奇' }
      ];
      
      // 设备模式和配置
      const deviceMode = ref('root'); // 'root' 或 'child'
      const devices = ref([]); // 白名单设备列表
      const searchQuery = ref(''); // 设备搜索
      const selectedIndices = ref(new Set()); // 多选索引集合
      
      // 设备类型选项（对齐 Flutter _deviceTypeOptions）
      const deviceTypeOptions = [
        {label: '其他预留', value: DtuProtocol.DEV_TYPE_RESERVED},           // 0x05
        {label: '三相电表', value: DtuProtocol.DEV_TYPE_THREE_PHASE_METER},   // 0x01
        {label: '单相电表', value: DtuProtocol.DEV_TYPE_SINGLE_PHASE_METER},  // 0x02
        {label: '温湿度变送器', value: DtuProtocol.DEV_TYPE_TEMP_HUMIDITY},   // 0x03
        {label: '继电器', value: DtuProtocol.DEV_TYPE_RELAY},                 // 0x04
      ];
      // devType → label 快速查找
      const deviceTypeMap = {
        0x01: '三相电表',
        0x02: '单相电表',
        0x03: '温湿度变送器',
        0x04: '继电器',
        0x05: '其他预留',
      };
      // 向后兼容：label 数组（用于 grid 显示等）
      const deviceTypeLabels = deviceTypeOptions.map(t => t.label);
      
      const modbusAddresses = ref([1, 2, 3, 4, 5, 6, 7, 8]);
      const modbusDeviceTypes = ref([0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05]); // 存 devType 值，默认 5=其他预留
      
      // SLE功率设置 (0-7)
      const slePower = ref(3);
      
      // 对话框状态
      const modbusDialogVisible = ref(false);
      const modbusEditIndex = ref(0);
      const modbusEditType = ref(0);
      const modbusEditAddr = ref(1);
      const modbusEditContext = ref('global'); // 'global' 主设置 | 'device' 子设备
      
      const deviceDialogVisible = ref(false);
      const editingDevice = ref({});
      const editingIndex = ref(-1);
      const serialParamsExpanded = ref(false);
      
      // 调试终端相关
      const terminalInput = ref('');
      const logs = ref([]);
      const autoScroll = ref(true);
      const hexDisplay = ref(true);
      const customCommand = ref('');
      
      // DTU协议服务实例
      let dtuService = null;
      
      // 当前设备配置缓存
      const deviceConfig = reactive({
        deviceInfo: null,
        uartConfig: null,
        modbusConfig: null,
        whiteList: [],
        powerConfig: null
      });
      
      // 转换为DTU协议波特率级别
      const getBaudRateLevel = (baudRate) => {
        const mapping = {
          1200: 0x00,
          2400: 0x01,
          4800: 0x02,
          9600: 0x03,
          19200: 0x04,
          38400: 0x05,
          57600: 0x06,
          115200: 0x07
        };
        return mapping[baudRate] || 0x03; // 默认9600
      };
      
      // 转换为DTU协议校验位
      const getParityValue = (parityText) => {
        switch (parityText) {
          case 'none': return DtuProtocol.PARITY_NONE;
          case 'even': return DtuProtocol.PARITY_EVEN;
          case 'odd': return DtuProtocol.PARITY_ODD;
          default: return DtuProtocol.PARITY_NONE;
        }
      };
      
      // 计算属性
      
      const connectionClass = computed(() => {
        if (serialConnected.value) return 'connected';
        if (scanning.value) return 'connecting';
        return '';
      });
      
      const connectionText = computed(() => {
        if (serialConnected.value) return '已连接';
        if (scanning.value) return '连接中...';
        return '未连接';
      });
      
      const formatCommandPreview = computed(() => {
        if (!customCommand.value) return '(空)';
        return customCommand.value.trim().split(/\s+/).map(p => p.toUpperCase()).join(' ');
      });

      // 设备搜索 & 多选
      const filteredDevices = computed(() => {
        const q = searchQuery.value.trim().toLowerCase();
        if (!q) return devices.value.map((d, i) => ({ ...d, _origIdx: i }));
        return devices.value
          .map((d, i) => ({ ...d, _origIdx: i }))
          .filter(d => d.mac && d.mac.toLowerCase().includes(q));
      });

      const isAllFilteredSelected = computed(() => {
        const fds = filteredDevices.value;
        if (fds.length === 0) return false;
        return fds.every(d => selectedIndices.value.has(d._origIdx));
      });

      const selectedCount = computed(() => selectedIndices.value.size);
      
      // Methods
      const goTo = (page) => {
        // 检查是否为白名单页面，并且当前是子节点模式
        if (page === 'whitelist' && deviceMode.value !== 'root') {
          // 自动切换到设置页面，并显示提示
          currentPage.value = 'settings';
          Message.warning('请在设备模式中切换到"根节点"模式以使用白名单功能');
          return;
        }
        currentPage.value = page;
      };
      
      // 日志辅助 — 毫秒时间戳
      const formatLogTime = () => {
        const d = new Date();
        return `${String(d.getHours()).padStart(2,'0')}:${String(d.getMinutes()).padStart(2,'0')}:${String(d.getSeconds()).padStart(2,'0')}.${String(d.getMilliseconds()).padStart(3,'0')}`;
      };
      
      // 帧拆解信息
      const getFrameInfo = (frame) => {
        if (!frame || frame.length < 7) return '';
        const cmd = frame[2];
        const seq = frame[3];
        const len = frame[4] | (frame[5] << 8);
        const body = len > 0 ? frame.slice(6, 6 + len) : [];
        const bodyHex = body.length > 0 ? DtuFrame.bytesToHex(new Uint8Array(body)) : '';
        const cmdName = DtuProtocol.getCmdName(cmd);
        return `CMD=${cmdName} | SEQ=${seq} | LEN=${len}${bodyHex ? ' | BODY=' + bodyHex : ''}`;
      };

      // 从 body 提取状态码（响应帧 body[0]）
      const getStatusFromBody = (bodyArray) => {
        if (!bodyArray || bodyArray.length === 0) return undefined;
        return bodyArray[0];
      };

      const addLog = (type, data, level = 'info') => {
        const time = formatLogTime();
        logs.value.push({ time, type, data, level });
        // 限制 500 条
        while (logs.value.length > 500) logs.value.shift();
        nextTick(() => {
          if (autoScroll.value) {
            const el = document.querySelector('.terminal');
            if (el) el.scrollTop = el.scrollHeight;
          }
        });
      };

      // 详细协议日志 — 对标 Flutter DebugPanel
      const addDetailedLog = ({ direction, frame, hexData, cmdName, description, error, level }) => {
        const time = formatLogTime();
        const frameInfo = frame ? getFrameInfo(frame) : '';
        logs.value.push({
          time, direction, hexData, cmdName, description, frameInfo, error,
          level: level || (error ? 'error' : direction === '发送' ? 'tx' : direction === '接收' ? 'rx' : 'info'),
          isDetailed: true
        });
        while (logs.value.length > 500) logs.value.shift();
        nextTick(() => {
          if (autoScroll.value) {
            const el = document.querySelector('.terminal');
            if (el) el.scrollTop = el.scrollHeight;
          }
        });
      };
      
      const toggleConnection = () => {
        serialConnected.value ? disconnectSerial() : connectSerial();
      };
      
      const connectSerial = async () => {
        if (!await DtuService.checkSupport()) {
          Message.error('您的浏览器不支持 Web Serial API，请使用 Chrome/Edge 浏览器');
          return;
        }
        try {
          scanning.value = true;
          addLog('SYS', '正在请求USB设备，波特率: ' + serialParams.value.baudRate);
          
          // 使用DTU服务连接设备
          const success = await dtuService.connect(serialParams.value);
          if (success) {
            serialConnected.value = true;
          } else {
            serialConnected.value = false;
          }
          
          scanning.value = false;
          return success;
        } catch (err) {
          addLog('ERR', '连接失败: ' + err.message, 'error');
          serialConnected.value = false;
          scanning.value = false;
          return false;
        }
      };
      
      const disconnectSerial = async () => {
        try {
          await dtuService.disconnect();
        } catch (err) {
          addLog('ERR', '断开连接时出错: ' + err.message, 'error');
        } finally {
          serialConnected.value = false;
        }
      };
      
      const applySerialParams = async () => {
        if (serialConnected.value) {
          try {
            // 断开并重新使用新参数连接
            await disconnectSerial();
            await new Promise(r => setTimeout(r, 100));
            await connectSerial();
          } catch (err) {
            Message.error('串口参数更新失败');
          }
        } else {
          Message.success('串口参数已更新');
        }
      };
      
      const sendData = async (hexString) => {
        if (!serialConnected.value) {
          Message.warning('请先连接USB设备');
          return false;
        }
        
        try {
          // 将十六进制字符串转为字节数组
          const bytes = Utils.hexToBytes(hexString);
          // 使用DTU服务的内部发送方法
          await dtuService._sendFrame(bytes);
          addLog('TX', hexString.toUpperCase(), 'tx');
          return true;
        } catch (err) {
          addLog('ERR', '发送失败: ' + err.message, 'error');
          return false;
        }
      };
      
      // DTU协议相关命令
      const dtuOperations = {
        
        // 读取配置操作
        async readDeviceInfo() {
          try {
            Message.info('正在读取设备信息...');
            const info = await dtuService.readDeviceInfo();
            deviceConfig.deviceInfo = info;
            Message.success('设备信息读取成功');
            return info;
          } catch (err) {
            Message.error('读取设备信息失败: ' + err.message);
            return null;
          }
        },
        
        async readUartConfig() {
          try {
            Message.info('正在读取串口配置...');
            const cfg = await dtuService.readUartCfg();
            deviceConfig.uartConfig = cfg;
            Message.success('串口配置读取成功');
            return cfg;
          } catch (err) {
            Message.error('读取串口配置失败: ' + err.message);
            return null;
          }
        },
        
        async readModbusConfig() {
          try {
            Message.info('正在读取Modbus配置...');
            const cfg = await dtuService.readModbusCfg();
            deviceConfig.modbusConfig = cfg;
            // 更新UI中的Modbus配置显示
            if (cfg && cfg.items) {
              modbusAddresses.value = cfg.items.map(item => item.addr);
              modbusDeviceTypes.value = cfg.items.map(item => item.devType); // 存 devType 数值
            }
            Message.success('Modbus配置读取成功');
            return cfg;
          } catch (err) {
            Message.error('读取Modbus配置失败: ' + err.message);
            return null;
          }
        },
        
        async readWhiteList() {
          try {
            if (deviceMode.value !== 'root') {
              Message.warning('请在设备模式中切换到"根节点"模式以读取白名单');
              return [];
            }
            Message.info('正在读取白名单...');
            const list = await dtuService.readWhiteList();
            deviceConfig.whiteList = list;
            // 更新UI中的设备列表
            devices.value = list.map(item => ({
              mac: item.mac,
              connected: false,
              modbusAddr: 1,
              baudRate: 115200,
              dataBits: 8,
              stopBits: 1,
              parity: 'none'
            }));
            Message.success('白名单读取成功');
            return list;
          } catch (err) {
            Message.error('读取白名单失败: ' + err.message);
            return [];
          }
        },
        
        async readPower() {
          try {
            if (deviceMode.value !== 'root') {
              Message.warning('请在设备模式中切换到"根节点"模式以读取功率');
              return null;
            }
            Message.info('正在读取功率配置...');
            const powerCfg = await dtuService.readPower();
            deviceConfig.powerConfig = powerCfg;
            slePower.value = powerCfg.power;
            Message.success('功率配置读取成功');
            return powerCfg;
          } catch (err) {
            Message.error('读取功率配置失败: ' + err.message);
            return null;
          }
        },
        
        async getModeStatus() {
          try {
            Message.info('正在读取模式状态...');
            const status = await dtuService.getModeStatus();
            Message.success('模式状态读取成功');
            return status;
          } catch (err) {
            Message.error('读取模式状态失败: ' + err.message);
            return null;
          }
        },
        
        // 读取所有配置
        async readAllConfig() {
          Message.info('正在读取完整配置...');
          const result = await dtuService.readAllConfig();
          Message.success('完整配置读取完成');
          return result;
        },
        
        // 写入配置操作
        async setRole(newRole) {
          try {
            const roleValue = newRole === 'root' ? DtuProtocol.ROLE_ROOT : DtuProtocol.ROLE_NODE;
            Message.info('正在设置设备角色: ' + newRole);
            await dtuService.setRole(roleValue);
            deviceMode.value = newRole;
            Message.success('设备角色设置成功');
            return true;
          } catch (err) {
            Message.error('设置角色失败: ' + err.message);
            throw err;
          }
        },
        
        async setUartConfig() {
          try {
            const uartCfg = {
              baudLevel: getBaudRateLevel(serialParams.value.baudRate),
              parity: getParityValue(serialParams.value.parity),
              stopBits: parseInt(serialParams.value.stopBits),
              dataBits: parseInt(serialParams.value.dataBits)
            };
            Message.info('正在设置串口配置...');
            await dtuService.setUartCfg(uartCfg);
            Message.success('串口配置设置成功');
            return true;
          } catch (err) {
            Message.error('设置串口配置失败: ' + err.message);
            throw err;
          }
        },
        
        async setModbusConfig() {
          try {
            const items = [];
            for (let i = 0; i < 8; i++) {
              items.push({
                addr: modbusAddresses.value[i],
                devType: modbusDeviceTypes.value[i] || DtuProtocol.DEV_TYPE_RESERVED
              });
            }
            
            Message.info('正在设置Modbus配置...');
            await dtuService.setModbusCfg(items);
            Message.success('Modbus配置设置成功');
            return true;
          } catch (err) {
            Message.error('设置Modbus配置失败: ' + err.message);
            throw err;
          }
        },
        
        async setPower(powerLevel) {
          try {
            Message.info('正在设置功率: ' + powerLevel);
            await dtuService.setPower(powerLevel);
            Message.success('功率设置成功');
            return true;
          } catch (err) {
            Message.error('设置功率失败: ' + err.message);
            throw err;
          }
        },
        
        async addWhiteListItem(mac) {
          try {
            Message.info('正在添加白名单: ' + mac);
            await dtuService.addWhiteListItem(mac);
            // UI中自动添加设备
            devices.value.push({
              mac: mac,
              connected: false,
              modbusAddr: 1,
              baudRate: 115200,
              dataBits: 8,
              stopBits: 1,
              parity: 'none'
            });
            Message.success('白名单添加成功');
            return true;
          } catch (err) {
            Message.error('添加白名单失败: ' + err.message);
            throw err;
          }
        },
        
        async deleteWhiteListItem(mac) {
          try {
            Message.info('正在删除白名单: ' + mac);
            await dtuService.delWhiteListItem(mac);
            Message.success('白名单删除成功');
            return true;
          } catch (err) {
            Message.error('删除白名单失败: ' + err.message);
            throw err;
          }
        },

        async readChildNodeConfig(mac) {
          try {
            Message.info('正在读取子节点配置: ' + mac);
            const cfg = await dtuService.readChildNodeConfig(mac);
            Message.success('子节点配置读取成功');
            return cfg;
          } catch (err) {
            Message.error('读取子节点配置失败: ' + err.message);
            return null;
          }
        },

        async setChildNodeConfig(config) {
          try {
            Message.info('正在设置子节点配置: ' + config.mac);
            await dtuService.setChildNodeConfig(config);
            Message.success('子节点配置设置成功');
            return true;
          } catch (err) {
            Message.error('设置子节点配置失败: ' + err.message);
            throw err;
          }
        },

        async addWhiteListItemFull(item) {
          try {
            Message.info('正在添加白名单条目: ' + item.mac);
            await dtuService.addWhiteListItemFull(item);
            devices.value.push({
              mac: item.mac,
              connected: false,
              modbusAddr: 1,
              baudRate: item.baudRate || 115200,
              dataBits: item.dataBits || 8,
              stopBits: item.stopBits || 1,
              parity: DtuProtocol.getParityName(item.parity || 0x00)
            });
            Message.success('白名单添加成功');
            return true;
          } catch (err) {
            Message.error('添加白名单失败: ' + err.message);
            throw err;
          }
        },
        
        async commitConfig() {
          try {
            Message.info('正在提交保存配置...');
            await dtuService.commit();
            Message.success('配置保存成功');
            return true;
          } catch (err) {
            Message.error('保存配置失败: ' + err.message);
            throw err;
          }
        },
        
        async rebootDevice() {
          try {
            Message.info('正在重启设备...');
            await dtuService.reboot();
            Message.warning('设备正在重启，请稍后重新连接');
            return true;
          } catch (err) {
            Message.error('重启设备失败: ' + err.message);
            throw err;
          }
        },
        
        async factoryReset() {
          try {
            Message.info('正在恢复出厂设置...');
            await dtuService.factoryReset();
            Message.warning('设备已恢复出厂设置');
            return true;
          } catch (err) {
            Message.error('恢复出厂设置失败: ' + err.message);
            throw err;
          }
        }
      };
      
      // 发送自定义命令
      const sendCustomCommand = async () => {
        if (customCommand.value) {
          await sendData(customCommand.value);
          customCommand.value = '';
        }
      };
      
      const sendCommand = async (hexString) => {
        return await sendData(hexString);
      };
      
      const sendTerminalCommand = async () => {
        if (terminalInput.value) {
          await sendData(terminalInput.value);
          terminalInput.value = '';
        }
      };
      
      const clearLogs = () => { logs.value = []; };
      
      const addDevice = () => {
        editingIndex.value = -1;
        editingDevice.value = {
          mac: '',
          modbusPresets: Array.from({ length: 8 }, (_, i) => ({ addr: i + 1, devType: 0x05 })),
          baudRate: 115200,
          dataBits: 8,
          stopBits: 1,
          parity: 'none',
          connected: false
        };
        // 添加设备时，串口参数默认展开
        serialParamsExpanded.value = true;
        closeAllSelects();
        deviceDialogVisible.value = true;
      };
      
      const editDevice = async (index) => {
        editingIndex.value = index;
        editingDevice.value = { ...devices.value[index] };
        
        // 确保编辑设备时有完整的默认值
        if (!editingDevice.value.baudRate) editingDevice.value.baudRate = 115200;
        if (!editingDevice.value.dataBits) editingDevice.value.dataBits = 8;
        if (!editingDevice.value.stopBits) editingDevice.value.stopBits = 1;
        if (!editingDevice.value.parity) editingDevice.value.parity = 'none';
        if (!editingDevice.value.modbusPresets || !Array.isArray(editingDevice.value.modbusPresets)) {
          editingDevice.value.modbusPresets = Array.from({ length: 8 }, (_, i) => ({ addr: i + 1, devType: 0x05 }));
        }
        while (editingDevice.value.modbusPresets.length < 8) {
          editingDevice.value.modbusPresets.push({ addr: editingDevice.value.modbusPresets.length + 1, devType: 0x05 });
        }
        
        // 编辑设备时也自动展开串口参数
        serialParamsExpanded.value = true;
        closeAllSelects();
        deviceDialogVisible.value = true;

        // 如果已连接且有 MAC，从设备读取子节点真实配置
        if (serialConnected.value && editingDevice.value.mac) {
          try {
            const cfg = await dtuOperations.readChildNodeConfig(editingDevice.value.mac);
            if (cfg) {
              // 用设备返回的真实串口参数填充
              editingDevice.value.baudRate = DtuProtocol.getBaudRate(cfg.baudLevel);
              editingDevice.value.dataBits = cfg.dataBits;
              editingDevice.value.stopBits = cfg.stopBits;
              editingDevice.value.parity = DtuProtocol.getParityName(cfg.parity).toLowerCase();
              // 用设备返回的真实 Modbus 预设填充
              editingDevice.value.modbusPresets = cfg.modbusItems.length > 0 
                ? cfg.modbusItems 
                : Array.from({ length: 8 }, (_, i) => ({ addr: i + 1, devType: 0x05 }));
              // 补齐到 8 个
              while (editingDevice.value.modbusPresets.length < 8) {
                editingDevice.value.modbusPresets.push({ 
                  addr: editingDevice.value.modbusPresets.length + 1, 
                  devType: 0x05 
                });
              }
              Message.success('已从设备读取子节点配置');
            }
          } catch (err) {
            // 读取失败则使用本地数据，不阻塞 UI
            console.warn('读取子节点配置失败，使用本地数据:', err.message);
          }
        }
      };
      
      const saveDevice = async () => {
        if (!editingDevice.value.mac || !editingDevice.value.mac.match(/^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$/)) {
          Message.error('请输入有效的MAC地址格式 (XX:XX:XX:XX:XX:XX)');
          return;
        }
        
        try {
          const mac = editingDevice.value.mac.toUpperCase();
          
          if (editingIndex.value >= 0) {
            const oldMac = devices.value[editingIndex.value].mac;
            if (oldMac !== mac) {
              await dtuOperations.deleteWhiteListItem(oldMac);
              await dtuOperations.addWhiteListItem(mac);
            }
            devices.value[editingIndex.value] = { ...editingDevice.value, mac };
          } else {
            await dtuOperations.addWhiteListItem(mac);
            devices.value.push({ ...editingDevice.value, mac });
          }
          
          closeDeviceDialog();
          Message.success('设备已保存');
        } catch (err) {
          Message.error('保存设备失败: ' + err.message);
        }
      };
      
      // Modal中的下拉框选择处理
      const selectModalOption = (field, value) => {
        editingDevice.value[field] = value;
        const dropdown = document.getElementById(`select-edit${field.charAt(0).toUpperCase() + field.slice(1)}`);
        if (dropdown) {
          dropdown.style.display = 'none';
          
          // 如果使用了fixed定位，恢复原状
          if (dropdown.classList.contains('fixed-position')) {
            dropdown.classList.remove('fixed-position');
            dropdown.style.top = '';
            dropdown.style.left = '';
            dropdown.style.width = '';
            
            // 将下拉框移回原来位置
            const originalParent = document.querySelector(`[data-dropdown-id="${dropdown.id}"]`);
            if (originalParent && originalParent !== dropdown.parentElement) {
              originalParent.appendChild(dropdown);
            }
          }
        }
        // 关闭下拉框时移除覆盖层
        document.body.classList.remove('dropdown-open');
      };
      
      const deleteDevice = async (index) => {
        const device = devices.value[index];
        if (!device.mac) {
          devices.value.splice(index, 1);
          Message.success('未配置MAC的设备已删除');
          return;
        }
        
        try {
          if (deviceMode.value === 'root') {
            const confirmed = confirm(`确定要从白名单中删除设备 ${device.mac} 吗？`);
            if (!confirmed) return;
            
            await dtuOperations.deleteWhiteListItem(device.mac);
            devices.value.splice(index, 1);
            Message.success('设备已从白名单中删除');
          } else {
            devices.value.splice(index, 1);
            Message.success('设备已删除');
          }
        } catch (err) {
          Message.error('删除设备失败: ' + err.message);
        }
      };
      
      const closeDeviceDialog = () => {
        deviceDialogVisible.value = false;
        // 关闭对话框时重置展开状态
        setTimeout(() => {
          serialParamsExpanded.value = false;
        }, 100);
      };

      // 多选功能
      const toggleSelect = (origIdx) => {
        const s = new Set(selectedIndices.value);
        if (s.has(origIdx)) s.delete(origIdx); else s.add(origIdx);
        selectedIndices.value = s;
      };

      const toggleSelectAll = () => {
        if (isAllFilteredSelected.value) {
          // 取消当前筛选结果的全部选中
          const s = new Set(selectedIndices.value);
          filteredDevices.value.forEach(d => s.delete(d._origIdx));
          selectedIndices.value = s;
        } else {
          const s = new Set(selectedIndices.value);
          filteredDevices.value.forEach(d => s.add(d._origIdx));
          selectedIndices.value = s;
        }
      };

      const clearSelection = () => { selectedIndices.value = new Set(); };

      const batchDelete = async () => {
        const indices = Array.from(selectedIndices.value).sort((a, b) => b - a); // 倒序，从后删
        if (indices.length === 0) { Message.warning('请先选择要删除的设备'); return; }
        const confirmed = confirm(`确定要删除选中的 ${indices.length} 个设备吗？`);
        if (!confirmed) return;
        try {
          for (const idx of indices) {
            const device = devices.value[idx];
            if (device.mac && deviceMode.value === 'root') {
              await dtuOperations.deleteWhiteListItem(device.mac);
            }
            devices.value.splice(idx, 1);
          }
          selectedIndices.value = new Set();
          Message.success(`已删除 ${indices.length} 个设备`);
        } catch (err) {
          Message.error('批量删除失败: ' + err.message);
        }
      };
      
      const refreshDevices = async () => {
        if (deviceMode.value !== 'root') {
          Message.warning('请在设备模式中切换到"根节点"模式以刷新白名单');
          return;
        }
        Message.info('正在刷新白名单...');
        await dtuOperations.readWhiteList();
      };
      
      // Modbus预设编辑
      const showModbusEditor = (index, context = 'global') => {
        modbusEditContext.value = context;
        modbusEditIndex.value = index;
        if (context === 'device') {
          const preset = editingDevice.value.modbusPresets[index];
          modbusEditAddr.value = preset.addr;
          const optIdx = deviceTypeOptions.findIndex(t => t.value === preset.devType);
          modbusEditType.value = optIdx >= 0 ? optIdx : 0;
        } else {
          modbusEditAddr.value = modbusAddresses.value[index];
          const devType = modbusDeviceTypes.value[index];
          const optIdx = deviceTypeOptions.findIndex(t => t.value === devType);
          modbusEditType.value = optIdx >= 0 ? optIdx : 0;
        }
        closeAllSelects();
        modbusDialogVisible.value = true;
      };
      
      const saveModbusPreset = async () => {
        try {
          if (modbusEditContext.value === 'device') {
            // 子设备 Modbus 预设：更新本地 + SET_WL_NODE_CFG (0x17) + COMMIT (0x20)
            editingDevice.value.modbusPresets[modbusEditIndex.value] = {
              addr: modbusEditAddr.value,
              devType: deviceTypeOptions[modbusEditType.value].value
            };
            if (serialConnected.value && editingDevice.value.mac) {
              const device = editingDevice.value;
              const config = {
                mac: device.mac,
                baudLevel: getBaudRateLevel(device.baudRate),
                parity: getParityValue(device.parity),
                stopBits: parseInt(device.stopBits),
                dataBits: parseInt(device.dataBits),
                modbusItems: device.modbusPresets.map(p => ({
                  addr: p.addr,
                  devType: p.devType || 0x05
                }))
              };
              await dtuOperations.setChildNodeConfig(config);
              await dtuOperations.commitConfig();
            }
          } else {
            // 全局 Modbus 预设 → SET_MODBUS_CFG (0x12) + COMMIT (0x20)
            modbusAddresses.value[modbusEditIndex.value] = modbusEditAddr.value;
            modbusDeviceTypes.value[modbusEditIndex.value] = deviceTypeOptions[modbusEditType.value].value;
            if (serialConnected.value) {
              await dtuOperations.setModbusConfig();
              await dtuOperations.commitConfig();
            }
          }
          modbusDialogVisible.value = false;
          let msg = 'Modbus预设已保存';
          if (serialConnected.value) {
            msg += modbusEditContext.value === 'device' ? '并写入子设备' : '并写入设备';
          } else {
            msg += '（本地）';
          }
          Message.success(msg);
        } catch (err) {
          Message.error('保存Modbus预设失败: ' + err.message);
        }
      };
      
      const resetModbusAddresses = async () => {
        modbusAddresses.value = [1, 2, 3, 4, 5, 6, 7, 8];
        modbusDeviceTypes.value = [0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05];
        if (serialConnected.value) {
          try {
            await dtuOperations.setModbusConfig();
            await dtuOperations.commitConfig();
            Message.success('Modbus地址已重置并写入设备');
          } catch (err) {
            Message.error('写入失败: ' + err.message);
          }
        } else {
          Message.success('Modbus地址已重置（本地）');
        }
      };
      
      // 功率描述
      const getPowerDesc = (level) => {
        const descs = ['最低', '低', '中低', '中', '中高', '高', '很高', '最高'];
        return descs[level] || '';
      };
      
      // 功率滑块交互
      const setPowerByClick = (event) => {
        const track = event.currentTarget;
        const rect = track.getBoundingClientRect();
        const x = event.clientX - rect.left;
        const percent = Math.max(0, Math.min(1, x / rect.width));
        slePower.value = Math.round(percent * 7);
      };
      
      const startDrag = (event) => {
        event.preventDefault();
        const track = event.target.parentElement;
        
        const onMove = (e) => {
          const rect = track.getBoundingClientRect();
          const x = e.clientX - rect.left;
          const percent = Math.max(0, Math.min(1, x / rect.width));
          slePower.value = Math.round(percent * 7);
        };
        
        const onUp = () => {
          document.removeEventListener('mousemove', onMove);
          document.removeEventListener('mouseup', onUp);
        };
        
        document.addEventListener('mousemove', onMove);
        document.addEventListener('mouseup', onUp);
      };

      // 模拟USB连接（开发测试用）
      const simulateConnect = () => {
        serialConnected.value = true;
        addLog('USB', '模拟连接成功 - 115200bps (开发模式)', 'success');
        Message.success('已进入模拟连接模式');
        
        // 模拟一些初始数据
        setTimeout(() => {
          addLog('RX', 'AA 55 01 01 00 00 00 00 00', 'success');
        }, 500);
      };
      
      // 保存设置 - 执行完整的配置写入流程
      const saveSettings = async () => {
        try {
          // 1. 设置设备角色
          if (deviceMode.value === 'root') {
            await dtuOperations.setRole('root');
          } else {
            await dtuOperations.setRole('child');
          }
          
          // 2. 设置串口配置
          await dtuOperations.setUartConfig();
          
          // 3. 设置Modbus配置
          await dtuOperations.setModbusConfig();
          
          // 4. 如果是根节点模式，设置功率
          if (deviceMode.value === 'root') {
            await dtuOperations.setPower(slePower.value);
          }
          
          // 5. 提交保存
          await dtuOperations.commitConfig();
          
          Message.success('设置已保存');
        } catch (err) {
          Message.error('保存设置失败: ' + err.message);
        }
      };
      
      // 加载设置 - 读取完整配置
      const loadSettings = async () => {
        try {
          Message.info('正在读取配置...');
          const result = await dtuOperations.readAllConfig();
          Message.success('配置读取完成');
          return result;
        } catch (err) {
          Message.error('读取配置失败: ' + err.message);
        }
      };
      
      // 重置设置 - 恢复出厂设置
      const resetSettings = async () => {
        try {
          const confirmed = confirm('确定要恢复出厂设置吗？此操作不可逆，所有配置将被清除。');
          if (!confirmed) return;
          
          await dtuOperations.factoryReset();
          Message.warning('设备已恢复出厂设置');
        } catch (err) {
          Message.error('恢复出厂设置失败: ' + err.message);
        }
      };
      
      // 下拉框相关
      const showSelect = (name) => {
        const dropdown = document.getElementById(`select-${name}`);
        if (dropdown) {
          const isShowing = dropdown.style.display === 'block';
          document.querySelectorAll('.select-dropdown').forEach(el => {
            if (el.id !== `select-${name}`) el.style.display = 'none';
          });
          dropdown.style.display = isShowing ? 'none' : 'block';
          
          // 当下拉框显示时，添加一个透明覆盖层阻止下层交互
          if (!isShowing) {
            document.body.classList.add('dropdown-open');
            
            // 强制将所有下拉框提升到body级别，防止被其他元素遮挡
            // 只处理在层叠上下文中可能被遮挡的下拉框（如在模态框或表格中）
            const parentModal = dropdown.closest('.modal, .serial-params-bar, .card');
            if (parentModal) {
              // 计算下拉框的位置
              const trigger = dropdown.parentElement.querySelector('.select-trigger');
              if (trigger) {
                const rect = trigger.getBoundingClientRect();
                
                // 使用CSS类而不是内联样式
                dropdown.classList.add('fixed-position');
                dropdown.style.top = `${rect.bottom + window.scrollY}px`;
                dropdown.style.left = `${rect.left + window.scrollX}px`;
                dropdown.style.width = `${rect.width}px`;
                
                // 记录原始父元素
                const originalParent = dropdown.parentElement;
                originalParent.setAttribute('data-dropdown-id', dropdown.id);
                
                // 将下拉框移动到body直接子元素
                document.body.appendChild(dropdown);
              }
            }
          } else {
            document.body.classList.remove('dropdown-open');
            // 移除fixed定位，恢复原始状态
            dropdown.style.position = '';
            dropdown.style.top = '';
            dropdown.style.left = '';
            dropdown.style.width = '';
            dropdown.style.zIndex = '';
          }
        }
      };
      
      const selectOption = (name, value) => {
        if (name === 'slePower') {
          slePower.value = value;
        } else {
          serialParams.value[name] = value;
        }
        const dropdown = document.getElementById(`select-${name}`);
        if (dropdown) {
          dropdown.style.display = 'none';
          
          // 如果使用了fixed定位，恢复原状
          if (dropdown.classList.contains('fixed-position')) {
            dropdown.classList.remove('fixed-position');
            dropdown.style.top = '';
            dropdown.style.left = '';
            dropdown.style.width = '';
            
            // 将下拉框移回原来位置
            const originalParent = document.querySelector(`[data-dropdown-id="${dropdown.id}"]`);
            if (originalParent && originalParent !== dropdown.parentElement) {
              originalParent.appendChild(dropdown);
            }
          }
        }
        // 关闭下拉框时移除覆盖层
        document.body.classList.remove('dropdown-open');
      };
      
      const getSelectLabel = (name) => {
        if (name === 'slePower') {
          return slePower.value;
        }
        const options = {
          baudRate: baudRates.map(r => ({ value: r, label: r })),
          dataBits: dataBitsOptions.map(b => ({ value: b, label: b })),
          stopBits: stopBitsOptions.map(s => ({ value: s, label: s })),
          parity: parityOptions
        };
        const found = options[name]?.find(o => o.value === serialParams.value[name]);
        return found ? found.label : serialParams.value[name];
      };

      const getParityLabel = (parityValue) => {
        const found = parityOptions.find(o => o.value === parityValue);
        return found ? found.label : (parityValue || '请选择');
      };
      
      const getDeviceTypeLabel = (devType) => {
        return deviceTypeMap[devType] || '其他预留';
      };

      // 关闭所有下拉框（modal 打开前调用，防止 select 浮在 modal 之上）
      const closeAllSelects = () => {
        document.querySelectorAll('.select-dropdown').forEach(el => {
          el.style.display = 'none';
          if (el.classList.contains('fixed-position')) {
            el.classList.remove('fixed-position');
            el.style.position = '';
            el.style.top = '';
            el.style.left = '';
            el.style.width = '';
            const originalParent = document.querySelector(`[data-dropdown-id="${el.id}"]`);
            if (originalParent && originalParent !== el.parentElement) {
              originalParent.appendChild(el);
            }
          }
        });
        document.body.classList.remove('dropdown-open');
      };
      
      onMounted(() => {
        addLog('SYS', 'DTU 配置助手 Web Serial 版本已启动');
        addLog('SYS', '请连接USB设备开始通信');
        
        // 创建DTU服务实例
        dtuService = Object.create(DtuService);
        dtuService.constructor(addLog, addDetailedLog);
        
        document.addEventListener('click', (e) => {
          if (!e.target.closest('.select')) {
            document.querySelectorAll('.select-dropdown').forEach(el => {
              el.style.display = 'none';
              
              // 如果使用了fixed定位，恢复原状
              if (el.classList.contains('fixed-position')) {
                el.classList.remove('fixed-position');
                el.style.top = '';
                el.style.left = '';
                el.style.width = '';
                
                // 将下拉框移回原来位置
                const originalParent = document.querySelector(`[data-dropdown-id="${el.id}"]`);
                if (originalParent) {
                  originalParent.appendChild(el);
                }
              }
            });
            // 关闭所有下拉框时移除覆盖层
            document.body.classList.remove('dropdown-open');
          }
        });
      });
      
      return {
        currentPage,
        serialConnected,
        scanning,
        serialParams,
        baudRates,
        dataBitsOptions,
        stopBitsOptions,
        parityOptions,
        deviceMode,
        devices,
        deviceTypeOptions,
        modbusAddresses,
        modbusDeviceTypes,
        slePower,
        customCommand,
        terminalInput,
        logs,
        autoScroll,
        hexDisplay,
        deviceDialogVisible,
        editingDevice,
        serialParamsExpanded,
        searchQuery,
        selectedIndices,
        filteredDevices,
        isAllFilteredSelected,
        selectedCount,
        toggleSelect,
        toggleSelectAll,
        clearSelection,
        batchDelete,
        modbusDialogVisible,
        modbusEditIndex,
        modbusEditType,
        modbusEditAddr,
        modbusEditContext,
        deviceConfig,
        
        connectionClass,
        connectionText,
        formatCommandPreview,
        goTo,
        toggleConnection,
        connectSerial,
        disconnectSerial,
        applySerialParams,
        sendCommand,
        sendCustomCommand,
        sendTerminalCommand,
        clearLogs,
        addDevice,
        editDevice,
        saveDevice,
        deleteDevice,
        refreshDevices,
        showModbusEditor,
        saveModbusPreset,
        resetModbusAddresses,
        getPowerDesc,
        setPowerByClick,
        startDrag,
        simulateConnect,
        saveSettings,
        loadSettings,
        resetSettings,
        showSelect,
        selectOption,
        selectModalOption,
        getSelectLabel,
        getParityLabel,
        getDeviceTypeLabel,
        closeDeviceDialog,
        
        // DTU操作函数
        dtuOperations,
        
        // 测试函数（开发用）
        async testDtuProtocol() {
          if (!serialConnected.value) {
            Message.warning('请先连接设备');
            return;
          }
          
          try {
            Message.info('开始测试DTU协议...');
            
            // 1. 测试读取设备信息
            const info = await dtuOperations.readDeviceInfo();
            if (!info) {
              Message.error('设备信息读取失败');
              return;
            }
            
            // 2. 测试读取串口配置
            const uartCfg = await dtuOperations.readUartConfig();
            if (!uartCfg) {
              Message.error('串口配置读取失败');
              return;
            }
            
            // 3. 测试读取Modbus配置
            const modbusCfg = await dtuOperations.readModbusConfig();
            if (!modbusCfg) {
              Message.error('Modbus配置读取失败');
            }
            
            // 4. 根据设备角色测试其他功能
            if (info.role === DtuProtocol.ROLE_ROOT) {
              await dtuOperations.readPower();
              await dtuOperations.readWhiteList();
            }
            
            Message.success('DTU协议测试完成');
          } catch (err) {
            Message.error('DTU协议测试失败: ' + err.message);
          }
        }
      };
    }
  });
  
  app.mount('#app');
}

// 页面加载完成后初始化
document.addEventListener('DOMContentLoaded', initApp);
