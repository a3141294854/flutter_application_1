# AGENTS.md — flutter_application_1

## 这个项目是什么

DTU（无线数传终端）的配置工具，三块内容：

- `lib/` —— Flutter Android App「DTU 配置助手」。BLE 连接 DTU，读写设备/串口/Modbus/白名单/电源等配置；启动页可选「蓝牙配置」和「监视系统」（后者是 WebView 嵌远程看板）。
- `web_serial_vue/` —— 网页版（浏览器 Web Serial API 直连串口），原生 JS + CSS，**没有构建步骤**。这是网页的唯一权威副本（git 跟踪）。
- 根目录和 `web_serial_vue/` 下的 `DTU*.md` —— 协议与测试流程文档。改协议相关代码前先读。

## 怎么跑

Flutter SDK 在 `D:\flutter`，**没进 PATH**，必须写全路径：

```
D:\flutter\bin\flutter.bat pub get
D:\flutter\bin\flutter.bat analyze        # 改完代码至少跑一次
D:\flutter\bin\flutter.bat run -d <device>
D:\flutter\bin\flutter.bat build apk --release
```

网页版：不用构建，浏览器直接打开 `web_serial_vue/index.html`。注意 Web Serial 只在安全上下文可用（`localhost` 或 https），用 `http://<IP>` 打开会拿不到 `navigator.serial`。

## 禁区

- `lib/protocol/dtu_protocol.dart` 的命令字（0x01/0x02/0x03/0x10…）和帧格式是与固件的约定，改动必须固件同步，并更新对应 `DTU*.md`。
- `jiancha/` 是网页版的旧副本（UTF-16LE 编码、未跟踪、内容落后于 `web_serial_vue/`）。不要在这里改功能，改 `web_serial_vue/`。
- 不要提交 `build/`、`.dart_tool/`、`web_serial_vue/web_serial_vue.rar`。
- `lib/app.dart` 里的 `kDevMode` 和 `_onDevSkipConnected` 是联调跳过 BLE 的开关，发版前删掉（代码里有 TODO 标记）。
- personal-server（114.132.238.176）上 `pet-app` / `pet-mysql` / `pet-redis` 是另一套生产环境，不要动；`/www/wwwroot/dtu` 的监控服务由 systemd `dtu-monitor` 管理，重启用 `systemctl`，别直接 kill python 进程。

## 约定

- 代码注释、UI 文案都用中文。
- 改网页样式先读 `web_serial_vue/DESIGN_GUIDE.md`（新拟态 Neumorphism 风格）。
- 网页源码是 UTF-8（无 BOM），`jiancha/` 是 UTF-16LE。用 PowerShell 读文件必须显式指定编码，否则中文乱码。
- 提交信息用中文短句（例：「增加串口参数的同步」），一次提交只做一件事。
- 网页发布没有自动化脚本。当前线上部署见下节，要换地址先跟用户确认。

## 上传 GitHub

- 仓库 `https://github.com/a3141294854/flutter_application_1`（公开），本地 `main` 推 `origin main`。
- 全局 git 配了代理 `http(s).proxy=127.0.0.1:7897`（Clash，需开着）。
- 在 DSH 沙箱里直接 `git push` 会失败：schannel 报 `SEC_E_NO_CREDENTIALS`，Git 凭据管理器也起不来。读操作（`ls-remote` / `fetch`）加 `-c http.sslBackend=openssl` 就够；推送要同样加后端并申请一次完整权限（full access）：

  ```
  git -c http.sslBackend=openssl -c http.sslCAInfo='C:/Program Files/Git/mingw64/etc/ssl/certs/ca-bundle.crt' push origin main
  ```

## 网页线上部署（personal-server）

- **正式地址：`https://fazeclan.cloud/`**（Let's Encrypt 证书，无需警告，WebSerial 可用）；`http://fazeclan.cloud/` 会 301 到 https；`www.fazeclan.cloud` 同样可用。
- 兜底地址：`https://114.132.238.176/`（自签证书，浏览器会警告，WebSerial 可用）。
- 文件：`/www/wwwroot/dtu-web/`（`index.html` + `css/style.css` + `js/app.js`），对应仓库 `web_serial_vue/` 的同名文件。更新页面只需覆盖文件，不用 reload。
- nginx：`/www/server/panel/vhost/nginx/dtu-web.conf`，三个 server 块：域名 80（301 + ACME 验证）、域名 443（正式证书）、IP 兜底 80/443（自签证书）。
- 证书：`/www/server/panel/vhost/cert/fazeclan.cloud/`，由 `acme.sh`（ECC）签发并装好自动续期 cron（`0,6,12,18 * * *`），续期后自动 reload nginx。再手动续：`/root/.acme.sh/acme.sh --cron --home /root/.acme.sh`。
- 域名 `fazeclan.cloud` 在腾讯云/DNSPod（NS `screw.dnspod.net` / `date.dnspod.net`），A 记录 `@` 和 `www` → 114.132.238.176。实测正式域名 80/443 未被腾讯云备案墙拦（未备案的临时域名 sslip.io 会被拦，别拿它当参考）。
- 备用方案：服务器已装 `cloudflared`（`/usr/local/bin/cloudflared`），隧道端口可达，若哪天域名被拦可改走 Cloudflare Tunnel。
- 旧版残留：`/study/web/`（5 月 5 日版本，没挂到任何 Web 服务，不要拿它当线上）。
- 服务器上 `114.132.238.176:8000` 是另一套「分布式新能源运行监控看板」（systemd `dtu-monitor`），不是本项目的网页。
