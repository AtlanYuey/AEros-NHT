#!/usr/bin/env bash
# Installs an APK on the running emulator, opens it, taps around with the
# monkey and reports crashes (logcat FATAL EXCEPTION / ANR) with screenshots.
# Usage: smoke-test.sh <apk> <output dir>
set -u
APK=$1
OUT=$2
PKG=com.atlanyuey.nhentai
mkdir -p "$OUT"

adb wait-for-device
adb shell getprop ro.build.version.release | sed 's/^/Android /'
adb install -r "$APK"
adb logcat -c
adb logcat -v time > "$OUT/logcat.txt" 2>&1 &
LOGCAT=$!

shot() { adb exec-out screencap -p > "$OUT/$1.png" 2>/dev/null || true; }
alive() { adb shell pidof "$PKG" > /dev/null 2>&1; }

adb shell am start -W -n "$PKG/.MainActivity"
sleep 20
shot 01_launch
alive && echo "Running after launch" || echo "NOT RUNNING after launch"

# Background and back (saves and restores state).
adb shell input keyevent KEYCODE_HOME
sleep 3
adb shell am start -W -n "$PKG/.MainActivity"
sleep 5
shot 02_resumed
alive && echo "Running after resume" || echo "NOT RUNNING after resume"

# Random taps, swipes and key presses inside the app.
adb shell monkey -p "$PKG" -s 7 --throttle 300 --pct-syskeys 2 --pct-appswitch 2 -v 1500 > "$OUT/monkey.txt" 2>&1 || true
shot 03_after_monkey
grep -E "CRASH|ANR|Monkey finished|Events injected" "$OUT/monkey.txt" || true

sleep 2
kill "$LOGCAT" 2>/dev/null || true
echo "=== Crashes ==="
if grep -q -E "FATAL EXCEPTION|ANR in $PKG" "$OUT/logcat.txt"; then
  grep -n -A60 -E "FATAL EXCEPTION|ANR in $PKG" "$OUT/logcat.txt" | head -300
  echo "CRASHED" > "$OUT/result.txt"
else
  echo "none"
  echo "OK" > "$OUT/result.txt"
fi
