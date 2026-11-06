## 2.1.4 更新内容

- 搜索：输入后直接搜索。输入的是数字时，上方显示这个编号的作品，下方是搜索结果（不再直接跳到作品页）
- 搜索：打开搜索时默认显示搜索历史；长按一条历史可以删除，左滑也可以删除
- 搜索历史随设置通过 iCloud 同步，也会包含在导出的设置文件里
- 设置 › 通用 › 搜索：新增「保存搜索历史」开关，关闭后不再保存新的搜索，历史列表也会隐藏
- 修复搜索框有时要点好几次才能输入的问题：iPhone 打开搜索页时直接弹出键盘；iPad 首页搜索时右上角按钮保持不动，搜索框不会失去焦点

## 2.1.3 更新内容

- iPad：标签栏「自动」位置不再延迟，点按屏幕哪一侧，标签栏立即移到哪一侧（点按标签栏本身不会让它移动）
- iPad：搜索移到首页右上角，和语言、排序按钮并排，点按后直接在首页输入和查看结果，不再切换页面；底部标签栏只保留首页、收藏、历史、更多

## 2.1.2 更新内容

- 画廊页：过长的标题会自动收起，和封面同高，末尾显示「…」；点按标题展开全文，再点一次收起
- 画廊页：每组标签只占一行，可以左右滑动浏览；放不下时右侧出现展开按钮，点按后显示全部标签

## 2.1.1 更新内容

- iPad：标签栏移到屏幕底部，搜索单独放在旁边的玻璃圆形按钮里
- iPad：标签栏位置可选「自动」「左」「中」「右」（更多 › 外观）。「自动」会根据你最常点按屏幕的哪一侧，把标签栏移到那一侧
- 打开阅读器时隐藏标签栏

## 2.1.0 更新内容

- 新增 14 种界面语言：English、日本語、简体中文、繁體中文、한국어、Español、Français、Deutsch、Italiano、Português (Brasil)、Русский、Tiếng Việt、ไทย、Bahasa Indonesia
- 「更多 › 语言」：默认跟随系统语言，也可以手动选择，重新打开 App 后生效

原生 iOS / iPadOS 版，用 SwiftUI 重新编写，基于 [honjow/eros_n](https://github.com/honjow/eros_n) 修改。

## 安装

- 需要 iOS / iPadOS 18 或更高版本；在 iOS 26 上使用 Liquid Glass 效果。
- 安装包未签名，请用 Feather、SideStore、AltStore、Sideloadly 等工具自行签名安装。
- 套装 ID：`com.atlanyuey.nhentai`

## 功能

- 系统原生界面：iOS 26 Liquid Glass、底部标签栏与系统搜索；iPad 底部玻璃标签栏可自动跟随惯用手靠左或靠右（也可固定靠左、居中、靠右），搜索在首页右上角，横屏、竖屏可分别设置卡片大小
- 首页：热门与最新，按语言、排序筛选；瀑布流、瀑布流（紧凑）、网格、列表四种样式
- 画廊页：模糊封面背景，阅读、收藏、下载按钮，分组标签（可显示中文翻译），横向页面预览，相似推荐，评论
- 阅读器：从左到右、从右到左、上下翻页、上下连续（条漫）、上下连续（有间距，可调）；双击和双指缩放，点按两侧立即翻页，自动阅读，预加载，侧滑返回
- 搜索：标签补全、搜索历史（iCloud 同步，可关闭）、输入作品编号时在结果上方显示该作品
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
