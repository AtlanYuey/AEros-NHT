## 2.1.0（首个 Android 版本）

原生 Android 版，用 Kotlin 和 Jetpack Compose 编写，功能和设计与 iOS 版一致，基于 [honjow/eros_n](https://github.com/honjow/eros_n) 修改。

## 安装

- 需要 Android 8.0 或更高版本。Liquid Glass 的折射效果需要 Android 13 及以上，Android 12 有模糊效果，更早的版本显示为半透明。
- 下载 APK 直接安装。包名：`com.atlanyuey.nhentai`

## 功能

- Apple 风格界面：Liquid Glass 浮动标签栏、玻璃导航按钮、渐进模糊的滚动边缘、玻璃弹出菜单、提醒和操作表；大标题，iOS 风格的分组列表、开关、滑块、分段控件
- 标签栏：列表向下滚动时滑走（「更多 › 外观」中可关闭）；平板上可固定靠左、居中、靠右，或打开「标签栏跟随手的位置」（快、中、慢）
- 首页：热门与最新；「最新」一行可以直接切换排序，右侧是语言和搜索按钮，向下滑过顶部栏时吸附到栏上；瀑布流、瀑布流（紧凑）、网格、列表四种样式，横竖屏可分别设置卡片大小
- 搜索：在主页原地进行，键盘直接弹出；标签补全；搜索历史（长按或左滑删除，可在设置中关闭）；输入作品编号时在结果上方显示该作品
- 画廊页：模糊封面背景，长标题可收起，阅读、收藏、下载按钮，分组标签（可显示中文翻译，每组一行可展开），横向页面预览，相似推荐，评论
- 阅读器：从左到右、从右到左、上下翻页、上下连续（条漫）、上下连续（有间距，可调）；双击和双指缩放，点按两侧立即翻页；控制栏在翻页时和 3–10 秒（可调）无操作后自动隐藏；自动阅读，预加载；系统返回手势带预览动画
- 登录 nhentai 账号：收藏、发表评论
- 离线下载：暂停、继续、离线阅读
- 浏览记录，剪贴板画廊链接识别，打开 nhentai.net 画廊链接
- 设置可以导出、导入（与 iOS 版通用的文件），也会随 Android 系统备份保存
- 界面语言：English、日本語、简体中文、繁體中文、한국어、Español、Français、Deutsch、Italiano、Português (Brasil)、Русский、Tiếng Việt、ไทย、Bahasa Indonesia；默认跟随系统，可在「更多 › 语言」中切换（Android 13 及以上也可在系统设置中为本 App 单独设置）
- 关于页面的图标藏了一个小彩蛋，长按试试

## 许可

本项目是 [honjow/eros_n](https://github.com/honjow/eros_n)（Apache License 2.0）的修改版，与原作者及 nhentai 均无关联。第三方组件的许可见 App 内「关于 › 开源许可」。仅供 18 岁以上用户使用。

---

**English.** A native Android app written in Kotlin and Jetpack Compose, with the same features and Apple-style design (Liquid Glass) as the iOS app, based on [honjow/eros_n](https://github.com/honjow/eros_n). Requires Android 8.0 or later (glass refraction on Android 13+). Package `com.atlanyuey.nhentai`. This is a modified version of eros_n (Apache License 2.0) and is not affiliated with its author or with nhentai. For adults (18+) only.
