# 香港 iPhone 库存监听

本地配置：iPhone 18 Pro Max 256GB 布根地紅色，香港 SKU `MJXQ4ZA/A`。
2026-09-15 已从 Apple 香港实时购买页确认 SKU。

| 门店 | 编号 |
| --- | --- |
| ifc mall | R428 |
| apm Hong Kong | R673 |
| New Town Plaza | R610 |
| Causeway Bay | R409 |
| Canton Road | R499 |
| Festival Walk | R485 |

设置文件：`~/Library/Application Support/apple-store-inventory-monitor/settings.v2.json`。
当前本机基础间隔 60 秒（保留现有设置，沿用随机浮动和失败退避），`soundEnabled=false`、`openOnHit=none`。
只有 Apple 明确返回可取货才发送到货通知；预售、无数据、限流均不代表有货。
沿用上游行为：持续有货时每轮再次提醒。

## 同地区查询与冷却

- 香港门店共用一个浏览器会话和 Cookie，使用同一个库存接口。
- 库存请求加入 `searchNearby=true`。2026-09-15 实测一次请求返回香港六家门店，
  均包含 `MJXQ4ZA/A` 的准确型号数据；正常每轮由 6 次请求降为 1 次。
- 同一轮按地区、零件号组合、送货地区复用响应，并逐个核对门店编号。
  返回结果缺少某家门店或所需型号时，单独补查；每轮开始清空库存缓存，
  不使用上一轮有货状态发送本轮通知。
- 遇到 HTTP 403/541、非 JSON 拦截页、429 或服务端限流错误，整个地区至少冷却
  5 分钟。冷却期间进入下一轮、切换门店都不会发起新的 Apple 请求，亦不取消冷却。
  冷却到期后在下一次调度时探测，仍失败则重新冷却；其他地区独立处理。
- 541/403 会清理已被拒绝的会话，冷却期内不重建浏览器；429 保留会话。
  界面会显示冷却剩余时间，被影响门店显示未知。冷却只保存在进程内，
  完全退出重启会丢失计时，因此不要用反复重启强制重试。

请求数日志以 `Apple 库存请求：` 开头，可与 `cycleComplete` 对照验证。
正常轮次仅需一次库存请求的耗时，再等待当前配置的 60 秒 ±20%，因此更新通常约每分钟一次。
请求量下降不会等比例减少 Chrome 常驻内存；它仍然是同一个浏览器会话。

## 构建与启动

```sh
pnpm install --frozen-lockfile
pnpm tauri build --bundles app --config '{"bundle":{"createUpdaterArtifacts":false}}'
mkdir -p "$HOME/Applications"
ditto 'target/release/bundle/macos/Apple Store Inventory Monitor.app' "$HOME/Applications/Apple Store Inventory Monitor.app"
./scripts/start-hk-monitor.zsh
```

启动脚本读取当前环境，或 `APW_ENV_FILE` 指向的可信 shell 环境文件；默认读取
`~/.config/apple-store-inventory-monitor/env`。该文件可包含：

```sh
export BARK_URL='https://你的Bark服务器/你的设备Key'
```

支持 `BARK_API_URL`、`BARK_API`、`BARK_URL`，依此优先选择第一个非空值。
地址需含服务器和设备 Key；真实密钥只放在仓库之外，环境文件权限建议设为 `600`。
环境地址在通知时读取，不写入设置文件。它优先于界面中保存的 Bark 地址。
缺少环境地址时，启动脚本明确失败，避免误以为手机通知已启用。

`APW_AUTO_START=1` 自动开始已保存的监控；`APW_LOG_EVENTS=1` 将查询事件写入 stderr。
脚本启用两者。双击应用则保留上游手动开始方式，且不会自动读取 shell 环境文件。
电脑休眠或应用退出会停止查询。

## 这台 Mac 的后台服务

已安装用户级 LaunchAgent `com.ylongw.apple-store-inventory-monitor`，登录时自动启动，
异常退出后重启；从应用托盘正常退出则保持停止。本机环境变量文件已设为 `600`，
并由 `~/.zshenv` 载入，后续终端也能使用 `BARK_URL`。
应用安装在 `~/Applications/Apple Store Inventory Monitor.app`，后台启动脚本复制到
`~/.config/apple-store-inventory-monitor/start-hk-monitor.zsh`，避免后台进程读取
macOS 受保护的 Documents 目录。

日志：`~/Library/Logs/apple-store-inventory-monitor/monitor.log`。

```sh
# 停止后台服务
launchctl bootout "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.ylongw.apple-store-inventory-monitor.plist"
# 再次启动（停止之后）
launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.ylongw.apple-store-inventory-monitor.plist"
```

已完成真实查询：六家门店均成功返回暂不可取货；首次 ifc mall 的 HTTP 541
在下一轮恢复。Bark 配置测试返回 HTTP 200 / 业务码 200，不代表有货。

验证：`pnpm test`、`cargo test --workspace`。默认测试不会向真实 Bark 发送通知。
