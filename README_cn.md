# AEros-NHT

> AEros-NHT 是 [honjow/eros_n](https://github.com/honjow/eros_n) 的修改版，由 [AtlanYuey](https://github.com/AtlanYuey) 维护，并非原作者发布的版本。
>
> 主要修改：
> - 新增原生 SwiftUI 编写的 iOS / iPadOS 版（`apple/` 目录，套装 ID `com.atlanyuey.nhentai`）：系统控件与 Liquid Glass、iPad 侧边栏、多种阅读模式、离线下载、标签翻译、iCloud 同步设置。
> - 新增原生 Android 版（`android-native/` 目录，Kotlin + Jetpack Compose），功能与 iOS 版一致，同样是 Apple 风格界面与 Liquid Glass 效果。
> - Flutter 版：界面按 Apple 设计规范重做，数据层迁移到 nhentai API v2，以及其他修复。具体改动见 Git 提交记录。
>
> 原项目采用 Apache License 2.0，原有版权与许可声明保留不变，见 [LICENSE](LICENSE)。第三方组件的许可见 App 内「关于 › 开源许可」。

---

以下为原项目说明：

# Eros-N
[English](https://github.com/honjow/eros_n/blob/master/README.md) | 简体中文

[![](https://img.shields.io/github/downloads/honjow/eros_n/total.svg)](https://gitHub.com/honjow/eros_n/releases)
[![](https://img.shields.io/github/downloads/honjow/eros_n/latest/total)](https://github.com/honjow/eros_n/releases/latest)
[![](https://img.shields.io/github/v/release/honjow/eros_n)](https://github.com/honjow/eros_n/releases/latest)
[![](https://img.shields.io/github/stars/honjow/eros_n)]()
[![Telegram](https://img.shields.io/badge/chat-on%20Telegram-blue.svg)](https://t.me/joinchat/AEj27KMQe0JiMmUx)


## 应用简介
一个第三方nh客户端.

## 功能
- [x] 首页
- [x] 用户登录
- [x] 收藏列表
- [x] 查看画廊
- [x] 画廊标签 (翻译)
- [ ] 更多查看设置
- [ ] 下载画廊
- [x] 相似画廊
- [x] 画廊评论
- [x] 发布评论
- [x] 画廊历史
- [x] 搜索
- [ ] 更多设置

## iOS 安装
GitHub Actions 会构建**未签名**的 `Eros-N_<版本>.ipa`（在 Release 或 Actions 运行的 Artifacts 中下载）。
未签名的 IPA 需要自行签名后安装，可任选其一：
- [AltStore](https://altstore.io) / [SideStore](https://sidestore.io) / [Sideloadly](https://sideloadly.io)：使用自己的 Apple ID 签名安装（免费账号每 7 天需重新签名）
- [TrollStore](https://github.com/opa334/TrollStore)：在受支持的系统版本上可直接永久安装

最低系统要求：iOS 13

## Windows 平台需求
- [WebView2 运行时](https://developer.microsoft.com/zh-CN/microsoft-edge/webview2/)
- [Microsoft Visual C++ 可再发行程序包](https://learn.microsoft.com/zh-CN/cpp/windows/latest-supported-vc-redist?view=msvc-170)
- Windows 10 1809+

## 截图
|                                                                                         |                                                                                         |                                                                                         |
|:---------------------------------------------------------------------------------------:|:---------------------------------------------------------------------------------------:|:---------------------------------------------------------------------------------------:|
|  首页![](https://raw.githubusercontent.com/honjow/eros_n/master/screenshots/home_1.jpg)   | 画廊![](https://raw.githubusercontent.com/honjow/eros_n/master/screenshots/gallery_1.jpg) | 画廊![](https://raw.githubusercontent.com/honjow/eros_n/master/screenshots/gallery_2.jpg) |
| 评论![](https://raw.githubusercontent.com/honjow/eros_n/master/screenshots/comment_1.jpg) | 历史![](https://raw.githubusercontent.com/honjow/eros_n/master/screenshots/history_1.jpg) ||

