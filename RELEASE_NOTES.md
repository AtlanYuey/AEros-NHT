原生 iPhone / iPad 版（SwiftUI）和 Android 版（Kotlin、Jetpack Compose），功能和设计一致，基于 [honjow/eros_n](https://github.com/honjow/eros_n) 修改。

## 下载

| 设备 | 文件 | 要求 |
| --- | --- | --- |
| iPhone / iPad | `.ipa` | iOS / iPadOS 18 或更高版本，自行签名安装 |
| Android 手机 / 平板 | `.apk` | Android 8.0 或更高版本，直接安装 |

## 2.1.0 更新内容

- 新增 Android 版（手机和平板）
- 全新的 App 图标；「更多」改为「我的」
- 新增 14 种界面语言：English、日本語、简体中文、繁體中文、한국어、Español、Français、Deutsch、Italiano、Português (Brasil)、Русский、Tiếng Việt、ไทย、Bahasa Indonesia。默认跟随系统，也可以在「我的 › 语言」中选择
- 主页：「最新 · 所有语言」一行可以直接切换排序，右侧是语言和搜索按钮；向下滑过顶部栏时，排序吸附到顶部栏左侧，语言和搜索吸附到右侧
- 搜索在主页原地进行：键盘直接弹出，标签补全、搜索历史和结果都显示在主页上，取消后回到原来的位置。输入作品编号时，上方显示该作品，下方是搜索结果
- 搜索历史：长按或左滑删除，可在「我的 › 通用」中关闭保存；iOS 上随设置通过 iCloud 同步
- 底部标签栏：向下滑动时收起（「我的 › 外观」中可关闭）。iPhone 使用系统标签栏，由 iOS 26 收起成小按钮；iPad 和 Android 平板上可固定靠左、居中、靠右，或打开「标签栏跟随手的位置」（快、中、慢）
- 历史和下载：和收藏一样以卡片显示（跟随列表样式），封面上显示阅读进度 / 下载进度，长按可删除、暂停或继续；「我的 › 外观 › 历史和下载」可切换回列表
- 下载的作品先打开详情页，点「阅读」再看图；没有网络时也能打开详情页
- 画廊页：过长的标题收起到封面高度，点按展开；每组标签只占一行，可左右滑动，放不下时可点按展开全部
- 阅读器：翻页、滚动时自动隐藏控制栏；控制栏 3–10 秒（可调，默认 3 秒）无操作后也会自动隐藏
- 日语标记改为 JP
- 关于页面的图标藏了一个小彩蛋，长按试试

## 安装

**iPhone / iPad**

- 需要 iOS / iPadOS 18 或更高版本；在 iOS 26 上使用 Liquid Glass 效果。
- 安装包未签名，请用 Feather、SideStore、AltStore、Sideloadly 等工具自行签名安装。
- 设置自动同步需要用带 iCloud 功能的描述文件签名（付费开发者账号，为 `com.atlanyuey.nhentai` 注册开启 iCloud 的 App ID）。用通配符描述文件签名时其他功能都正常，设置可以用导出、导入代替。

**Android**

- 需要 Android 8.0 或更高版本。Liquid Glass 的折射效果需要 Android 13 及以上，Android 12 有模糊效果，更早的版本显示为半透明。
- 下载 APK 直接安装，以后的版本可以直接覆盖更新。

套装 ID / 包名：`com.atlanyuey.nhentai`

## 功能

- Apple 风格界面：Liquid Glass 标签栏和按钮、玻璃弹出菜单、大标题、分组列表；横屏、竖屏可分别设置卡片大小
- 首页：热门与最新，按语言、排序筛选；瀑布流、瀑布流（紧凑）、网格、列表四种样式
- 画廊页：模糊封面背景，阅读、收藏、下载按钮，分组标签（可显示中文翻译），横向页面预览，相似推荐，评论
- 阅读器：从左到右、从右到左、上下翻页、上下连续（条漫）、上下连续（有间距，可调）；双击和双指缩放，点按两侧立即翻页，自动阅读，预加载
- 搜索：标签补全、搜索历史、按作品编号打开
- 登录 nhentai 账号：收藏、发表评论
- 离线下载：暂停、继续、离线阅读（没有网络时也能打开详情页）
- 浏览记录，剪贴板画廊链接识别
- 设置可以导出、导入（iOS 和 Android 通用的文件）；iOS 上可通过 iCloud 同步，Android 上随系统备份保存

## 许可

本项目是 [honjow/eros_n](https://github.com/honjow/eros_n)（Apache License 2.0）的修改版，与原作者及 nhentai 均无关联。第三方组件的许可见 App 内「关于 › 开源许可」。仅供 18 岁以上用户使用。

---

**English.** Native apps for iPhone / iPad (SwiftUI) and Android (Kotlin, Jetpack Compose) with the same features and design, based on [honjow/eros_n](https://github.com/honjow/eros_n). The iOS / iPadOS IPA (iOS 18 or later, Liquid Glass on iOS 26) is unsigned: sign and install it with Feather, SideStore, AltStore, Sideloadly or similar; settings sync over iCloud needs a provisioning profile with the iCloud capability. The Android APK (Android 8.0 or later, glass refraction on Android 13+) installs directly. Bundle ID / package `com.atlanyuey.nhentai`. This is a modified version of eros_n (Apache License 2.0) and is not affiliated with its author or with nhentai. For adults (18+) only.
