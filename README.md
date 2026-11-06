# AEros-NHT

> AEros-NHT is a modified version of [honjow/eros_n](https://github.com/honjow/eros_n), maintained by [AtlanYuey](https://github.com/AtlanYuey). It is not a release by the original author.
>
> Main changes:
> - A native SwiftUI app for iOS / iPadOS (`apple/`, bundle ID `com.atlanyuey.nhentai`): system controls and Liquid Glass, an iPad bottom tab bar that moves to the hand you use, several reading modes, offline downloads, tag translation, settings sync over iCloud.
> - A native Android app (`android-native/`, Kotlin and Jetpack Compose) with the features of the iOS app and the same Apple-style design with Liquid Glass.
> - Flutter app: interface redone after Apple's design guidelines, data layer moved to nhentai API v2, and other fixes. See the Git history for the individual changes.
>
> The original project is licensed under the Apache License 2.0; its copyright and license notices are kept unchanged, see [LICENSE](LICENSE). Licenses of third-party components are listed in the app under About › Open Source Licenses.

---

The original project's README follows:

# Eros-N
English | [简体中文](https://github.com/erosTeam/eros_n/blob/master/README_cn.md)

[![](https://img.shields.io/github/downloads/erosTeam/eros_n/total.svg)](https://gitHub.com/erosTeam/eros_n/releases)
[![](https://img.shields.io/github/downloads/erosTeam/eros_n/latest/total)](https://github.com/erosTeam/eros_n/releases/latest)
[![](https://img.shields.io/github/v/release/erosTeam/eros_n)](https://github.com/erosTeam/eros_n/releases/latest)
[![](https://img.shields.io/github/stars/erosTeam/eros_n)]()

## Introduction
An unofficial Nhentai app.

## Features
- [x] Front page
- [x] User login
- [x] Favorites
- [x] View gallery
- [x] Gallery tags
- [ ] More view settings
- [ ] Download gallery
- [x] Similar galleries
- [x] Gallery comments
- [x] Post comments
- [x] History
- [x] Search
- [ ] More settings

## iOS installation
GitHub Actions builds an **unsigned** `Eros-N_<version>.ipa` (download it from a Release or from the Actions run artifacts).
Sign and install it with one of:
- [AltStore](https://altstore.io) / [SideStore](https://sidestore.io) / [Sideloadly](https://sideloadly.io) using your own Apple ID (free accounts must re-sign every 7 days)
- [TrollStore](https://github.com/opa334/TrollStore) on supported iOS versions

Requires iOS 13 or later.

## Windows platform requirements
- [WebView2 Runtime](https://developer.microsoft.com/en-us/microsoft-edge/webview2/)
- [Microsoft Visual C++ Redistributable](https://learn.microsoft.com/en-US/cpp/windows/latest-supported-vc-redist?view=msvc-170)
- Windows 10 1809+


## Screenshots
|                                                                                              |                                                                                              |                                                                                              |
|:--------------------------------------------------------------------------------------------:|:--------------------------------------------------------------------------------------------:|:--------------------------------------------------------------------------------------------:|
|   Front![](https://raw.githubusercontent.com/honjow/eros_n/master/screenshots/home_1.jpg)    | Gallery![](https://raw.githubusercontent.com/honjow/eros_n/master/screenshots/gallery_1.jpg) | Gallery![](https://raw.githubusercontent.com/honjow/eros_n/master/screenshots/gallery_2.jpg) |
| Comment![](https://raw.githubusercontent.com/honjow/eros_n/master/screenshots/comment_1.jpg) | History![](https://raw.githubusercontent.com/honjow/eros_n/master/screenshots/history_1.jpg) ||
