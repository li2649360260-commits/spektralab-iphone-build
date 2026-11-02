# SpektraLab iPhone 云端编译

从公开源码编译一个供自己安装的 iPhone 应用，不依赖 App Store 会员功能。
使用 RA4 的 iOS 移植工程，原始 SpektraLab C++/Metal 渲染引擎保持不变。

源码固定为 [lyolomeister/RA4](https://github.com/lyolomeister/RA4) 的
`51e1e15fcbd0f192b9fbd651d71c73912c1cafbb`（`ios-port` 分支）。
本仓库只保存构建流程和脚本，编译时拉取这份公开源码。

## 云端构建

1. 在自己的 GitHub 账号下创建构建仓库，保留本目录结构上传这些文件。
2. 上传到 `main` 分支的构建脚本或工作流会自动开始编译；也可进入 **Actions → Build iPhone IPA → Run workflow** 手动启动。
3. 手动启动时可填写自己的 Bundle ID；默认 `org.spektrafork.iphone`，与原作者的标识分开。
4. 构建成功后下载 `RA4-iPhone-unsigned`，解压得到 IPA、构建记录、校验值和安装说明。

流程由 `main` 分支的构建文件变更或手动操作触发，使用 GitHub 标准 `xcode-27` arm64 macOS runner，超时 45 分钟。
不需要向云端提交 Apple 账号、证书、私钥或手机照片。只读仓库权限，构建动作和上游源码均固定提交。
标准公开仓库构建的计费政策以 [GitHub 官方说明](https://docs.github.com/en/actions/reference/runners/github-hosted-runners) 为准；此流程不配置付费 runner。

## 本地 Mac 构建

准备 Xcode、Metal 工具链及上述固定提交的干净源码 checkout，然后运行：

```bash
APP_BUNDLE_ID=org.spektrafork.iphone bash scripts/build-iphone.sh /path/to/RA4 /path/to/new-output
```

Windows 不能运行 Apple 的 Xcode/iOS SDK；本地可检查脚本，实际编译在云端 Mac 上完成。
输出目录必须是新的目录，脚本拒绝复用旧的归档或 IPA。

## 验证范围

构建脚本检查 Xcode 归档、arm64 架构、Bundle ID、引擎资源、许可文件及 IPA 压缩包完整性。
这些检查不等于手机实测；首次安装后仍需验证打开照片、显影及导出。
IPA 未签名，详见 [iPhone 安装说明](docs/INSTALL-iPhone.zh-CN.md)。

此构建工具项目不宣称是 SpektraLab 或 RA4 的官方发行版。
上游代码和数据的完整许可随应用保留，不修改上游模型数据。
