# AEros-NHT for Android

Native Android app (Kotlin, Jetpack Compose) with the features and the Apple-style design of the iOS app in `../apple`.

- Liquid Glass: [Backdrop](https://github.com/Kyant0/AndroidLiquidGlass) (refraction on Android 13+, blur on 12, translucent fill before).
- Icons: Ionicons. Font: Inter.
- Strings: generated from the iOS translations (`app/src/main/res/values*/strings.xml`, `core/L10nKeys.kt`); the keys are the iOS keys.

## Build

```sh
./gradlew :app:assembleDebug      # debug APK
./gradlew :app:assembleRelease    # release APK (signed when the variables below are set)
./gradlew :app:testDebugUnitTest  # renders screenshots of the main screens to app/build/screens
```

## Release signing

CI signs the APK with the key from these repository secrets (Settings › Secrets and variables › Actions):

| Secret | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | the keystore file, base64 encoded |
| `ANDROID_KEYSTORE_PASSWORD` | keystore password |
| `ANDROID_KEY_ALIAS` | key alias |
| `ANDROID_KEY_PASSWORD` | key password |

Releases: a commit whose message contains `[publish]` builds both apps and publishes one GitHub release with the IPA and the APK (`.github/workflows/native-release.yml`, description from `RELEASE_NOTES.md`).

Locally, set `ANDROID_KEYSTORE_PATH`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` and `ANDROID_KEY_PASSWORD`. Without them the release build is signed with the debug key. Keep the keystore safe: updates only install over a build signed with the same key.
