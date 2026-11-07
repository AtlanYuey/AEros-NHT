## 2.1.0 更新内容（相对 2.0.0）

- 新增 14 种界面语言：English、日本語、简体中文、繁體中文、한국어、Español、Français、Deutsch、Italiano、Português (Brasil)、Русский、Tiếng Việt、ไทย、Bahasa Indonesia。「更多 › 语言」默认跟随系统，也可以手动选择
- 主页：「最新 · 所有语言」一行可以直接切换排序，右侧是语言和搜索按钮；向下滑过顶部栏时，排序吸附到顶部栏左侧，语言和搜索吸附到右侧
- 搜索在主页原地进行：键盘直接弹出，标签补全、搜索历史和结果都显示在主页上，取消后回到原来的位置。输入作品编号时，上方显示该作品，下方是搜索结果
- 搜索历史：长按或左滑删除，随设置通过 iCloud 同步；「更多 › 通用」中可以关闭保存
- iPhone：系统底部标签栏，向下滑动时由 iOS 26 收起成小按钮（「更多 › 外观」中可关闭）
- iPad：标签栏移到屏幕底部，可固定靠左、居中、靠右，或打开「标签栏跟随手的位置」（快、中、慢）；向下滑动时滑走
- 画廊页：过长的标题收起到封面高度，点按展开；每组标签只占一行，可左右滑动，放不下时可点按展开全部
- 阅读器：翻页、滚动时自动隐藏控制栏；控制栏 3–10 秒（可调，默认 3 秒）无操作后也会自动隐藏
- 日语标记改为 JP
- 关于页面的图标藏了一个小彩蛋，长按试试

原生 iOS / iPadOS 版，用 SwiftUI 重新编写，基于 [honjow/eros_n](https://github.com/honjow/eros_n) 修改。

## 安装

- 需要 iOS / iPadOS 18 或更高版本；在 iOS 26 上使用 Liquid Glass 效果。
- 安装包未签名，请用 Feather、SideStore、AltStore、Sideloadly 等工具自行签名安装。
- 套装 ID：`com.atlanyuey.nhentai`

## 功能

- 系统原生界面：iOS 26 Liquid Glass；iPhone 系统底部标签栏（滚动时可收起）；iPad 底部玻璃标签栏，可固定靠左、居中、靠右或跟随惯用手；横屏、竖屏可分别设置卡片大小
- 首页：热门与最新，按语言、排序筛选（筛选按钮滑过顶部栏时吸附到栏上）；瀑布流、瀑布流（紧凑）、网格、列表四种样式
- 画廊页：模糊封面背景，长标题可收起，阅读、收藏、下载按钮，分组标签（可显示中文翻译，每组一行可展开），横向页面预览，相似推荐，评论
- 阅读器：从左到右、从右到左、上下翻页、上下连续（条漫）、上下连续（有间距，可调）；双击和双指缩放，点按两侧立即翻页，控制栏自动隐藏，自动阅读，预加载，侧滑返回
- 搜索：在主页原地搜索；标签补全、搜索历史（iCloud 同步，可关闭）、输入作品编号时在结果上方显示该作品
- 登录 nhentai 账号：收藏、发表评论
- 离线下载：暂停、继续、离线阅读
- 浏览记录，剪贴板画廊链接识别
- 设置可通过 iCloud 同步（所有设备，或仅同类设备）；也可以导出、导入设置文件
- 界面语言：English、日本語、简体中文、繁體中文、한국어、Español、Français、Deutsch、Italiano、Português (Brasil)、Русский、Tiếng Việt、ไทย、Bahasa Indonesia；默认跟随系统，可在「更多 › 语言」中切换

## iCloud 同步

自动同步需要用带 iCloud 功能的描述文件签名：付费开发者账号，为 `com.atlanyuey.nhentai` 注册开启 iCloud 的 App ID 并生成描述文件。用通配符描述文件签名时其他功能都正常，设置可以用导出、导入代替。

## 许可

本项目是 [honjow/eros_n](https://github.com/honjow/eros_n)（Apache License 2.0）的修改版，与原作者及 nhentai 均无关联。第三方组件的许可见 App 内「关于 › 开源许可」。仅供 18 岁以上用户使用。

---

**English.** A native iOS / iPadOS app written in SwiftUI, based on [honjow/eros_n](https://github.com/honjow/eros_n). Requires iOS / iPadOS 18 or later (Liquid Glass on iOS 26). The IPA is unsigned: sign and install it with Feather, SideStore, AltStore, Sideloadly or similar. Bundle ID `com.atlanyuey.nhentai`. Settings sync over iCloud needs a provisioning profile with the iCloud capability; export / import works with any signing. This is a modified version of eros_n (Apache License 2.0) and is not affiliated with its author or with nhentai. For adults (18+) only.
