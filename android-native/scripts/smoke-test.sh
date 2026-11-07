#!/usr/bin/env bash
# Installs an APK on the running emulator, opens it, sends it to the
# background and back, taps around with the monkey and checks that the app
# never crashed (logcat). Writes OK or CRASHED to <output dir>/result.txt,
# with logcat, the monkey's log and screenshots next to it.
# Usage: smoke-test.sh <apk> <output dir>
set -u
APK=$1
OUT=$2
PKG=com.atlanyuey.nhentai
mkdir -p "$OUT"

adb wait-for-device
echo "Android $(adb shell getprop ro.build.version.release | tr -d '\r')"
adb install -r "$APK"
adb logcat -c
adb logcat -v time > "$OUT/logcat.txt" 2>&1 &
LOGCAT=$!

shot() { adb exec-out screencap -p > "$OUT/$1.png" 2>/dev/null || true; }
alive() { adb shell pidof "$PKG" > /dev/null 2>&1 && echo "running" || echo "NOT RUNNING"; }

adb shell am start -W -n "$PKG/.MainActivity"
sleep 25   # first page of galleries loads and shows
shot 01_launch
echo "After launch: $(alive)"

adb shell input keyevent KEYCODE_HOME
sleep 3
adb shell am start -W -n "$PKG/.MainActivity"
sleep 5
shot 02_resumed
echo "After resume: $(alive)"

adb shell monkey -p "$PKG" -s 7 --throttle 250 --pct-syskeys 2 --pct-appswitch 2 -v 800 > "$OUT/monkey.txt" 2>&1 || true
shot 03_after_monkey
echo "After monkey: $(alive)"

sleep 2
kill "$LOGCAT" 2>/dev/null || true

# Java crashes of the app (FATAL EXCEPTION followed by its process) and native ones.
awk -v pkg="$PKG" '
  /FATAL EXCEPTION/ { if (grab == 1 && n >= 1) print buf "\n--"; buf = $0; grab = 1; n = 0; next }
  grab == 1 { buf = buf "\n" $0; n++; if (n == 1 && index($0, "Process: " pkg) == 0) { grab = 0; next }
              if (n >= 60) { print buf "\n--"; grab = 0 } ; next }
  index($0, ">>> " pkg " <<<") { print "Native crash: " $0 }
  END { if (grab == 1 && n >= 1) print buf }
' "$OUT/logcat.txt" > "$OUT/crashes.txt"

{
  echo "=== Crashes ==="
  if [ -s "$OUT/crashes.txt" ]; then cat "$OUT/crashes.txt"; else echo "none"; fi
  echo "=== ANRs (often the slow emulator; not counted as failures) ==="
  grep -E "ANR in $PKG|NOT RESPONDING: $PKG" "$OUT/logcat.txt" "$OUT/monkey.txt" | head -5 || true
  grep -E "Events injected|Monkey finished|CRASH" "$OUT/monkey.txt" || true
} | tee "$OUT/summary.txt"

if [ -s "$OUT/crashes.txt" ] || grep -q "CRASH: $PKG" "$OUT/monkey.txt"; then
  echo CRASHED > "$OUT/result.txt"
else
  echo OK > "$OUT/result.txt"
fi
