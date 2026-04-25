DTU完整测试流程（正式）

 DTU 完整测试流程

本文档按当前代码实际实现整理，适用于：

UART 配置通道联调

BLE 配置通道联调

配置模式 / 运行模式行为验证

全部已实现协议指令逐条验证

当前代码入口与实现依据主要在：

[dtu_flow.c](https://www.yuque.com/home/sueiny/fbb_ws63/src/application/samples/Dtu/service/flow/dtu_flow.c)

[dtu_mode_config.c](https://www.yuque.com/home/sueiny/fbb_ws63/src/application/samples/Dtu/service/mode/dtu_mode_config.c)

[dtu_mode_run.c](https://www.yuque.com/home/sueiny/fbb_ws63/src/application/samples/Dtu/service/mode/dtu_mode_run.c)

[dtu_build_config.h](https://www.yuque.com/home/sueiny/fbb_ws63/src/application/samples/Dtu/common/dtu_build_config.h)

 1. 测试前提

 1.1 模式来源

当前模式由 GPIO13 拨码决定：

高电平：配置模式 CONFIG

低电平：运行模式 RUN

 1.2 UART 通道

当前 UART 配置口：

UART_BUS_0

TX = GPIO17

RX = GPIO18

默认参数：115200 8N1

说明：

SET_UART_CFG 只修改运行配置与 NV

COMMIT + REBOOT 后才按保存值重新初始化串口

 1.3 BLE 通道

当前 BLE GATT：

Service UUID：0xFDF0

Characteristic UUID：0xFDF1

属性：Write Without Response + Notify

重要说明：

BLE 客户端必须先对 FDF1 打开 Notify

也就是要先写 CCCD(0x2902) 为 0x0001

否则能写入请求，但收不到响应

 1.4 协议帧格式

所有请求帧格式：



说明：

帧头固定：AA 55

LEN 为小端

CRC 为 Modbus CRC16

响应帧格式同样为：



其中：

RESP_CMD = CMD | 0x80

响应 BODY[0] 永远是 status

 2. 状态码说明

当前状态码定义如下：

| 状态码 | 含义          |
| ------ | ------------- |
| 0x00   | SUCC          |
| 0x01   | CRC_ERR       |
| 0x02   | LEN_ERR       |
| 0x03   | CMD_ERR       |
| 0x04   | PARAM_ERR     |
| 0x05   | NOT_CONFIG    |
| 0x06   | ROLE_MISMATCH |
| 0x07   | WL_FULL       |
| 0x08   | NOT_FOUND     |
| 0x09   | SAVE_FAIL     |
| 0x0A   | BUSY          |

 3. 模式行为总览

 3.1 配置模式

配置模式允许：

READ_DEV_INFO

READ_UART_CFG

READ_MODBUS_CFG

READ_ROOT_WL_ALL

READ_ROOT_POWER

GET_MODE_STATUS

READ_WL_NODE_CFG

SET_ROLE

SET_UART_CFG

SET_MODBUS_CFG

SET_ROOT_POWER

ADD_WL_ITEM

DEL_WL_ITEM

CLEAR_WL

SET_WL_NODE_CFG

COMMIT

REBOOT

FACTORY_RESET

 3.2 运行模式

运行模式允许：

GET_MODE_STATUS

REBOOT

运行模式拒绝：

其他全部配置类命令

拒绝时返回：

status = 0x05 (NOT_CONFIG)

 4. 建议测试顺序

建议按下面顺序测：

配置模式基础读取

配置模式基础写入

ROOT 专属功能

COMMIT + REBOOT 持久化验证

运行模式拒配验证

UART 与 BLE 双通道一致性验证

 5. 指令总表

 5.1 读取类

| 指令             | CMD  | 发送报文                                  |
| ---------------- | ---- | ----------------------------------------- |
| READ_DEV_INFO    | 0x01 | AA 55 01 01 00 00 50 18                   |
| READ_UART_CFG    | 0x02 | AA 55 02 02 00 00 A0 5C                   |
| READ_MODBUS_CFG  | 0x03 | AA 55 03 03 00 00 F0 60                   |
| READ_ROOT_WL_ALL | 0x04 | AA 55 04 04 00 00 40 D5                   |
| READ_ROOT_POWER  | 0x05 | AA 55 05 05 00 00 10 E9                   |
| GET_MODE_STATUS  | 0x06 | AA 55 06 06 00 00 E0 AD                   |
| READ_WL_NODE_CFG | 0x07 | AA 55 07 07 06 00 A1 A2 A3 A4 A5 A6 80 F3 |

 5.2 写入类

| 指令                          | CMD  | 发送报文                                                     |
| ----------------------------- | ---- | ------------------------------------------------------------ |
| SET_ROLE(ROOT)                | 0x10 | AA 55 10 06 01 00 01 75 4B                                   |
| SET_ROLE(NODE)                | 0x10 | AA 55 10 06 01 00 00 B4 8B                                   |
| SET_UART_CFG(115200,None,1,8) | 0x11 | AA 55 11 07 04 00 07 00 01 08 F6 AD                          |
| SET_MODBUS_CFG(2项)           | 0x12 | AA 55 12 08 05 00 02 01 02 05 03 10 5B                       |
| SET_ROOT_POWER(5)             | 0x13 | AA 55 13 09 01 00 05 33 9C                                   |
| ADD_WL_ITEM                   | 0x14 | AA 55 14 0A 0E 00 A1 A2 A3 A4 A5 A6 07 44 54 55 5F 4E 30 31 07 7B |
| DEL_WL_ITEM                   | 0x15 | AA 55 15 0B 06 00 A1 A2 A3 A4 A5 A6 EA BD                    |
| CLEAR_WL                      | 0x16 | AA 55 16 0C 00 00 C4 6F                                      |
| SET_WL_NODE_CFG               | 0x17 | AA 55 17 08 0F 00 A1 A2 A3 A4 A5 A6 07 00 01 08 02 01 05 02 05 91 F7 |

 5.3 控制类

| 指令          | CMD  | 发送报文                |
| ------------- | ---- | ----------------------- |
| COMMIT        | 0x20 | AA 55 20 0D 00 00 9A 27 |
| REBOOT        | 0x21 | AA 55 21 0E 00 00 6B DB |
| FACTORY_RESET | 0x22 | AA 55 22 0F 00 00 3A 5F |

 6. 每条指令详细测试

 6.1 READ_DEV_INFO

发送：



预期：

响应命令字：0x81

status = 0x00

返回字段：

role

mac(6)

name_len

name

验证点：

设备名如果 Kconfig 配了 DTU_DEVICE_NAME，优先返回配置名

否则返回默认名 DTU_N01

 6.2 READ_UART_CFG

发送：



预期：

响应命令字：0x82

status = 0x00

默认应返回：

baud_level = 0x07

parity = 0x00

stop_bits = 0x01

data_bits = 0x08

 6.3 READ_MODBUS_CFG

发送：



预期：

响应命令字：0x83

status = 0x00

默认 item_count = 8

默认项：

addr = 0..7

dev_type = 0x05

 6.4 READ_ROOT_WL_ALL

发送：



预期：

如果当前角色不是 ROOT

status = 0x06 (ROLE_MISMATCH)

如果当前角色是 ROOT

status = 0x00

白名单按分片返回

返回字段：

frag_idx

frag_total

wl_total

item_count

items

说明：

此命令只返回白名单基础信息：

mac

name

白名单 node 的子配置需要通过 READ_WL_NODE_CFG 单独读取

 6.5 READ_ROOT_POWER

发送：



预期：

非 ROOT：status = 0x06

ROOT：status = 0x00，并返回 power

说明：

node 不单独保存 power

名单内 node 统一跟随 ROOT 当前 power

 6.6 GET_MODE_STATUS

发送：



预期：

响应命令字：0x86

status = 0x00

返回字段顺序：

current_mode

role

baud_level

parity

stop_bits

data_bits

mode_source

rx_profile

reboot_pending

说明：

当前模式由 GPIO13 决定

mode_source 现阶段应表现为拨码来源

 6.7 READ_WL_NODE_CFG

发送：



说明：

body 为目标白名单 node 的 mac(6)

预期：

非 ROOT：status = 0x06

找不到目标 MAC：status = 0x08

成功时返回：

status

uart_cfg(4)

modbus_count

(addr + dev_type) * N

补充说明：

node 子配置只包含：

uart_cfg

modbus

power 不在这里单独保存，统一由 ROOT 的 power 决定

 6.8 SET_ROLE(ROOT)

发送：



预期：

响应命令字：0x90

status = 0x00

验证点：

只改 RAM 中的运行配置

此时读 READ_DEV_INFO 应看到角色变化

持久化需 COMMIT

 6.9 SET_ROLE(NODE)

发送：



预期：

status = 0x00

 6.10 SET_UART_CFG

发送：



含义：

115200

None

1 stop

8 data

预期：

响应命令字：0x91

status = 0x00

验证点：

当前串口不会立刻重配

必须 COMMIT + REBOOT 后才按新配置生效

 6.11 SET_MODBUS_CFG

发送：



含义：

item_count = 2

item1: addr=1 dev_type=2

item2: addr=5 dev_type=3

预期：

响应命令字：0x92

status = 0x00

验证点：

再读 READ_MODBUS_CFG 时应返回两项

 6.12 SET_ROOT_POWER

发送：



预期：

当前角色不是 ROOT：status = 0x06

当前角色是 ROOT：status = 0x00

 6.13 ADD_WL_ITEM

发送：



含义：

MAC：A1:A2:A3:A4:A5:A6

名字：DTU_N01

预期：

非 ROOT：status = 0x06

ROOT 且空间足够：status = 0x00

白名单满：status = 0x07

补充说明：

新建白名单项时，会自动初始化该 node 的子配置

默认继承当前 ROOT 运行配置中的：

uart_cfg

modbus 预设

后续可通过 SET_WL_NODE_CFG 单独修改

 6.14 DEL_WL_ITEM

发送：



预期：

非 ROOT：status = 0x06

找不到项：status = 0x08

删除成功：status = 0x00

 6.15 CLEAR_WL

发送：



预期：

非 ROOT：status = 0x06

ROOT：status = 0x00

 6.16 SET_WL_NODE_CFG

发送：



说明：

body 格式：

mac(6)

uart_cfg(4)

modbus_count(1)

(addr + dev_type) * N

上例表示：

对 A1:A2:A3:A4:A5:A6

设置 node 串口为 115200 8N1

设置 node modbus 为 2 项：

addr=1 dev_type=0x05

addr=2 dev_type=0x05

预期：

非 ROOT：status = 0x06

找不到目标 MAC：status = 0x08

成功：status = 0x00

验证点：

发完后立刻发送 READ_WL_NODE_CFG

应返回刚才写入的子配置

 6.17 COMMIT

发送：



预期：

响应命令字：0xA0

status = 0x00

验证点：

UART 日志应打印：

DTU commit ...

DTU commit snapshot ...

 6.18 REBOOT

发送：



预期：

响应命令字：0xA1

status = 0x00

验证点：

设备重启

启动后 UART 日志打印 DTU boot config ...

配置应按 COMMIT 后内容恢复

 6.19 FACTORY_RESET

发送：



预期：

响应命令字：0xA2

status = 0x00

验证点：

角色、串口、Modbus、功率、白名单恢复默认

模式仍由 GPIO13 决定

默认 Modbus 预设恢复为 8 项：

addr = 0..7

dev_type = 0x05

 7. 配置模式完整联调用例

 用例 1：基础读取

步骤：

设 GPIO13 为高电平

上电

依次发送：

READ_DEV_INFO

READ_UART_CFG

READ_MODBUS_CFG

GET_MODE_STATUS

预期：

全部 status = 0x00

GET_MODE_STATUS 返回当前为配置模式

 用例 2：NODE 配置保存

步骤：

SET_ROLE(NODE)

SET_UART_CFG

SET_MODBUS_CFG

COMMIT

REBOOT

重新发送：

READ_DEV_INFO

READ_UART_CFG

READ_MODBUS_CFG

预期：

重启后配置保留

串口参数按保存值生效

 用例 3：ROOT 配置与白名单

步骤：

SET_ROLE(ROOT)

SET_ROOT_POWER

ADD_WL_ITEM

READ_ROOT_WL_ALL

READ_ROOT_POWER

COMMIT

REBOOT

重启后重复读取 READ_ROOT_WL_ALL 与 READ_ROOT_POWER

预期：

白名单与功率在重启后保留

 用例 4：白名单删除与清空

步骤：

先确保角色为 ROOT

ADD_WL_ITEM

DEL_WL_ITEM

READ_ROOT_WL_ALL

再次 ADD_WL_ITEM

CLEAR_WL

READ_ROOT_WL_ALL

预期：

删除后条目消失

清空后白名单为空

 用例 5：恢复出厂

步骤：

先改动多个配置项并 COMMIT

发送 FACTORY_RESET

分别读取：

READ_DEV_INFO

READ_UART_CFG

READ_MODBUS_CFG

READ_ROOT_POWER

READ_ROOT_WL_ALL

预期：

配置恢复默认

 8. 运行模式完整联调用例

 用例 6：运行模式状态查询

步骤：

设 GPIO13 为低电平

上电

发送 GET_MODE_STATUS

预期：

status = 0x00

返回 current_mode = RUN

 用例 7：运行模式拒配

步骤：

在运行模式下依次发送：

READ_DEV_INFO

READ_UART_CFG

READ_MODBUS_CFG

READ_ROOT_WL_ALL

READ_ROOT_POWER

SET_ROLE

SET_UART_CFG

SET_MODBUS_CFG

SET_ROOT_POWER

ADD_WL_ITEM

DEL_WL_ITEM

CLEAR_WL

COMMIT

FACTORY_RESET

预期：

全部返回 status = 0x05 (NOT_CONFIG)

UART 日志应有 reject 记录

 用例 8：运行模式下 REBOOT

步骤：

运行模式下发送 REBOOT

预期：

返回 status = 0x00

设备重启

模式仍按 GPIO13 采样结果决定

 9. UART 与 BLE 共用 service 的一致性测试

 用例 9：UART/BLE 结果一致

步骤：

配置模式下，UART 发送 READ_UART_CFG

BLE 打开 Notify 后，发送同样的 READ_UART_CFG

预期：

两边返回的业务内容一致

响应分别走各自通道返回

统一日志仍从 UART 打印

 用例 10：BLE 使用注意事项

步骤：

BLE 连接设备

对 FDF1 打开 Notify

再发送任意读命令

预期：

不打开 Notify 时，请求可能执行，但客户端收不到响应

打开 Notify 后即可正常收到响应

 10. 日志观察点

当前建议重点观察 UART 日志：

启动时：

[DTU LOG] ... boot ...

读取配置时：

[DTU LOG] DTU cfg read ...

写入配置时：

[DTU LOG] DTU cfg write ...

被拒绝时：

[DTU LOG] ... reject ...

COMMIT 后：

[DTU LOG] ... commit ...

BLE transport 自己的日志前缀为：



1

[BLE dtu server]

 11. 建议最终验收清单

最终建议至少完成以下验收：

配置模式下，全部读取命令通过

配置模式下，全部写入命令通过

ROOT 相关命令的角色限制正确

COMMIT + REBOOT 持久化正确

运行模式下拒配正确

UART 和 BLE 双通道都能访问同一套 service

BLE 在客户端打开 Notify 后可正常回包