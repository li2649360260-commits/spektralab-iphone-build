# iPhone 安装说明

这是基于 SpektraLab 的开源移植版 RA4，非官方发行版。最低系统要求为 iOS 18。
安装前请确认设备运行 iOS 18 或更新版本。

## 构建产物

`RA4-iPhone-unsigned.ipa` 包含编译后的 arm64 真机应用，但没有 Apple 签名，不能直接点开安装。
`BUILD-INFO.txt` 记录实际源码提交、Xcode、SDK 和验证范围；`SHA256SUMS.txt` 用于校验下载文件。

## 接下来

1. 在 Windows 上使用支持个人签名的安装工具完成签名及安装，例如 AltStore Classic。
2. Apple 账号登录、双重认证、设备授权及开发者模式设置由你本人完成。不要把密码、验证码或私钥发到聊天里。
3. 免费 Apple 账号的个人开发签名通常需要每 7 天刷新；付费开发者账号适用其对应的有效期。
4. 完成安装后先用一张小图验证打开、显影和导出，再测试高像素 RAW。

应用请求 increased-memory-limit 权限。随包保留原始 `SpektraProbe.entitlements`，具体能否授予由个人签名工具及 Apple 的描述文件决定。
云端编译没有进行你的手机上的性能或稳定性测试。

## 来源

- iOS 移植：https://github.com/lyolomeister/RA4
- 原项目：https://github.com/JamesQiu2005/SpektraLab
- Apple 开发者账号：https://developer.apple.com/help/account/basics/about-your-developer-account
- AltStore 官方文档：https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows

应用和引擎为 GPL-3.0-or-later，胶片/相纸描述档及 LUT 为 CC BY-SA 4.0，metal-cpp 为 Apache-2.0；完整许可随应用保留。
