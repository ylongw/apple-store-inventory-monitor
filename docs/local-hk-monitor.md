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
基础间隔 30 秒（沿用上游随机浮动和失败退避），`soundEnabled=false`、`openOnHit=none`。
只有 Apple 明确返回可取货才发送到货通知；预售、无数据、限流均不代表有货。
沿用上游行为：持续有货时每轮再次提醒。

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
