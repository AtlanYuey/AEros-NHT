"""Writes <lang>.lproj/Localizable.strings from keys.json and <lang>.py.

Usage: python3 gen.py <resources dir> <lang> [<lang> ...]
Each <lang>.py defines T, a list of translations in the order of keys.json.
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
keys = json.load(open(os.path.join(HERE, "keys.json"), encoding="utf-8"))
SPEC = re.compile(r"%(?:(\d)\$)?(lld|@|d)")


def specs(s):
    return [(m.group(1), m.group(2)) for m in SPEC.finditer(s)]


def check(lang, key, value, index):
    k, v = specs(key), specs(value)
    if sorted(t for _, t in k) != sorted(t for _, t in v):
        raise SystemExit(f"{lang}[{index}] specifiers differ: {key!r} -> {value!r}")
    if len(v) > 1 and any(p is None for p, _ in v):
        raise SystemExit(f"{lang}[{index}] needs positional specifiers: {value!r}")
    if not value.strip() and key.strip():
        raise SystemExit(f"{lang}[{index}] empty: {key!r}")


def escape(s):
    return s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")


resources = sys.argv[1]
for lang in sys.argv[2:]:
    scope = {}
    exec(open(os.path.join(HERE, f"{lang}.py"), encoding="utf-8").read(), scope)
    values = scope["T"]
    if len(values) != len(keys):
        raise SystemExit(f"{lang}: {len(values)} translations for {len(keys)} keys")
    for i, (k, v) in enumerate(zip(keys, values)):
        check(lang, k, v, i)
    folder = os.path.join(resources, f"{lang}.lproj")
    os.makedirs(folder, exist_ok=True)
    with open(os.path.join(folder, "Localizable.strings"), "w", encoding="utf-8") as f:
        f.write(f"/* {lang} */\n")
        for k, v in zip(keys, values):
            f.write(f'"{escape(k)}" = "{escape(v)}";\n')
    print(f"{lang}: {len(values)} strings")
