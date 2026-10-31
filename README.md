# SennixCore iOS

原生 iOS 版本，使用 SwiftUI + CoreBluetooth，界面与功能对应同仓库 Android App。

## 打开与运行

1. 在 macOS 上用 Xcode 15 或更高版本打开 `SennixCore.xcodeproj`。
2. 在 Target 的 Signing & Capabilities 中选择开发团队。
3. 连接 iPhone 后运行。BLE 需要真机，模拟器只能浏览界面和演示数据。

应用扫描名称包含 `MJ-20` 的 BLE 设备，使用 `FFF0/FFF2` 服务与特征收发数据。首次运行时 iOS 会请求蓝牙权限。

## 目录

- `SennixCoreApp.swift`：应用入口
- `AppModel.swift`：登录、设备、控制和报告状态
- `BluetoothService.swift`：CoreBluetooth 连接与通知
- `MJ20Codec.swift`：MJ-20 帧编解码
- `Views/`：登录、设备、控制、报告、我的与设置页面

