/**
 * DTU 配置助手 - Vue 应用
 * 模块化的组件和逻辑
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
  const { createApp, ref, computed, nextTick, onMounted } = Vue;
  
  const app = createApp({
    setup() {
      // Reactive state
      const currentPage = ref('settings');
      const serialConnected = ref(false);
      const scanning = ref(false);
      
      const serialParams = ref({
        baudRate: 115200,
        dataBits: 8,
        stopBits: 1,
        parity: 'none'
      });
      
      const baudRates = [9600, 19200, 38400, 57600, 115200];
      const dataBitsOptions = [5, 6, 7, 8];
      const stopBitsOptions = [1, 2];
      const parityOptions = [
        { value: 'none', label: '无' },
        { value: 'even', label: '偶' },
        { value: 'odd', label: '奇' }
      ];
      
      const deviceMode = ref('root');
      const devices = ref([]);
      const deviceTypes = ['保留', '多相电表', '单相电表', '温湿度变送器', '继电器'];
      const deviceType = ref(0);
      const modbusAddresses = ref([1, 2, 3, 4, 5, 6, 7, 8]);
      const modbusDeviceTypes = ref(['保留', '保留', '保留', '保留', '保留', '保留', '保留', '保留']);
      const slePower = ref(3);
      
      // Modbus编辑对话框
      const modbusDialogVisible = ref(false);
      const modbusEditIndex = ref(0);
      const modbusEditType = ref(0);
      const modbusEditAddr = ref(1);
      
      const customCommand = ref('');
      const terminalInput = ref('');
      const logs = ref([]);
      const autoScroll = ref(true);
      const hexDisplay = ref(true);
      
      const deviceDialogVisible = ref(false);
      const editingDevice = ref({});
      const editingIndex = ref(-1);
      const serialParamsExpanded = ref(false);
      
      // Computed
      const connectedCount = computed(() => devices.value.filter(d => d.connected).length);
      
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
      
      // Methods
      const goTo = (page) => {
        currentPage.value = page;
      };
      
      const addLog = (type, data, level = 'info') => {
        const time = new Date().toLocaleTimeString('zh-CN', { hour12: false });
        logs.value.push({ time, type, data, level });
        nextTick(() => {
          if (autoScroll.value) {
            document.querySelectorAll('.terminal').forEach(el => {
              el.scrollTop = el.scrollHeight;
            });
          }
        });
      };
      
      const toggleConnection = () => {
        serialConnected.value ? disconnectSerial() : connectSerial();
      };
      
      const connectSerial = async () => {
        if (!('serial' in navigator)) {
          Message.error('您的浏览器不支持 Web Serial API，请使用 Chrome/Edge 浏览器');
          return;
        }
        try {
          scanning.value = true;
          addLog('SYS', '正在请求USB设备...');
          
          const port = await navigator.serial.requestPort();
          await port.open({
            baudRate: serialParams.value.baudRate,
            dataBits: serialParams.value.dataBits,
            stopBits: serialParams.value.stopBits,
            parity: serialParams.value.parity
          });
          
          serialConnected.value = true;
          addLog('USB', '连接成功 - ' + serialParams.value.baudRate + 'bps', 'success');
          
          startReading(port);
        } catch (err) {
          addLog('ERR', '连接失败: ' + err.message, 'error');
          serialConnected.value = false;
        } finally {
          scanning.value = false;
        }
      };
      
      const startReading = async (port) => {
        while (port && port.readable) {
          const reader = port.readable.getReader();
          try {
            while (true) {
              const { value, done } = await reader.read();
              if (done) break;
              if (value) {
                const hex = Array.from(value).map(b => b.toString(16).padStart(2, '0').toUpperCase()).join(' ');
                addLog('RX', hex, 'success');
              }
            }
          } catch (err) {
            if (err.name !== 'AbortError') {
              addLog('ERR', '读取错误: ' + err.message, 'error');
            }
          } finally {
            reader.releaseLock();
          }
        }
      };
      
      const disconnectSerial = async () => {
        serialConnected.value = false;
        addLog('USB', '已断开连接');
      };
      
      const applySerialParams = async () => {
        if (serialConnected.value) {
          serialConnected.value = false;
          await new Promise(r => setTimeout(r, 100));
        }
        Message.success('串口参数已更新');
      };
      
      const sendData = async (hexString) => {
        if (!serialConnected.value) {
          Message.warning('请先连接USB设备');
          return false;
        }
        addLog('TX', hexString.toUpperCase(), 'tx');
        return true;
      };
      
      const sendCommand = async (cmd) => {
        const commands = {
          'READ': '01 03 00 00 00 0A C5 CD',
          'SAVE': '01 06 00 00 00 00 9A 9A',
          'RESET': '01 06 00 00 00 01 9A 9A'
        };
        if (commands[cmd]) {
          await sendData(commands[cmd]);
        }
      };
      
      const sendCustomCommand = async () => {
        if (customCommand.value) {
          await sendData(customCommand.value);
          customCommand.value = '';
        }
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
          name: '',
          mac: '',
          modbusAddr: 1,
          baudRate: 115200,
          dataBits: 8,
          stopBits: 1,
          parity: 'none',
          connected: false
        };
        deviceDialogVisible.value = true;
      };
      
      const editDevice = (index) => {
        editingIndex.value = index;
        editingDevice.value = { ...devices.value[index] };
        deviceDialogVisible.value = true;
      };
      
      const saveDevice = () => {
        if (editingIndex.value >= 0) {
          devices.value[editingIndex.value] = { ...editingDevice.value };
        } else {
          devices.value.push({ ...editingDevice.value });
        }
        deviceDialogVisible.value = false;
        Message.success('设备已保存');
      };
      
      const deleteDevice = (index) => {
        devices.value.splice(index, 1);
        Message.success('设备已删除');
      };
      
      const refreshDevices = () => Message.success('设备列表已刷新');
      
      // Modbus预设编辑
      const showModbusEditor = (index) => {
        modbusEditIndex.value = index;
        modbusEditAddr.value = modbusAddresses.value[index];
        modbusEditType.value = deviceTypes.indexOf(modbusDeviceTypes.value[index]);
        if (modbusEditType.value < 0) modbusEditType.value = 0;
        modbusDialogVisible.value = true;
      };
      
      const saveModbusPreset = () => {
        modbusAddresses.value[modbusEditIndex.value] = modbusEditAddr.value;
        modbusDeviceTypes.value[modbusEditIndex.value] = deviceTypes[modbusEditType.value];
        modbusDialogVisible.value = false;
        Message.success('Modbus预设已保存');
      };
      
      const resetModbusAddresses = () => {
        modbusAddresses.value = [1, 2, 3, 4, 5, 6, 7, 8];
        modbusDeviceTypes.value = ['保留', '保留', '保留', '保留', '保留', '保留', '保留', '保留'];
        Message.success('Modbus地址已重置');
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
          addLog('RX', '01 03 14 00 01 00 02 00 03 00 04 00 05 00 06 00 07 00 08 00 09 9A 9A', 'success');
        }, 500);
      };
      
      const saveSettings = async () => { await sendCommand('SAVE'); Message.success('设置已保存'); };
      const loadSettings = async () => { await sendCommand('READ'); Message.info('正在读取设置...'); };
      const resetSettings = async () => { await sendCommand('RESET'); Message.warning('正在恢复出厂设置...'); };
      
      // 下拉框相关
      const showSelect = (name) => {
        const dropdown = document.getElementById(`select-${name}`);
        if (dropdown) {
          document.querySelectorAll('.select-dropdown').forEach(el => {
            if (el.id !== `select-${name}`) el.style.display = 'none';
          });
          dropdown.style.display = dropdown.style.display === 'block' ? 'none' : 'block';
        }
      };
      
      const selectOption = (name, value) => {
        serialParams.value[name] = value;
        document.getElementById(`select-${name}`).style.display = 'none';
      };
      
      const getSelectLabel = (name) => {
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
      
      onMounted(() => {
        addLog('SYS', 'DTU 配置助手 Web Serial 版本已启动');
        addLog('SYS', '请连接USB设备开始通信');
        
        document.addEventListener('click', (e) => {
          if (!e.target.closest('.select')) {
            document.querySelectorAll('.select-dropdown').forEach(el => {
              el.style.display = 'none';
            });
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
        deviceTypes,
        deviceType,
        deviceTypeOptions: deviceTypes,
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
        modbusDialogVisible,
        modbusEditIndex,
        modbusEditType,
        modbusEditAddr,
        connectedCount,
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
        getSelectLabel,
        getParityLabel
      };
    }
  });
  
  app.mount('#app');
}

// 页面加载完成后初始化
document.addEventListener('DOMContentLoaded', initApp);
