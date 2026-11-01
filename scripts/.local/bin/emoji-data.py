#!/usr/bin/env python3
"""fcitx5 の絵文字辞書 (ja / en) を、quickshell のランチャー用の JSON に変換する。

入力 : /usr/share/fcitx5/emoji/data/{ja,en}.dict
       (zlib 圧縮。先頭 4 バイトは展開後のサイズ。展開後は「件数 u32、その後に (絵文字, キーワードの配列) の繰り返し」で、
        文字列は u32 の長さ + UTF-8、配列は u32 の個数 + 文字列)
出力 : 引数 1 (既定 ~/.cache/shell/emoji.json)
       [{"e": "😀", "ja": ["スマイル", ...], "en": ["face", "grin", "grinning face"]}, ...]  (辞書の並び = 絵文字の標準の順)
肌色のバリエーション (U+1F3FB..1F3FF を含むもの) は除く。
"""
import json
import os
import struct
import sys
import zlib

DATA = "/usr/share/fcitx5/emoji/data"


def read_dict(path):
    raw = open(path, "rb").read()
    buf = zlib.decompress(raw[4:])
    pos = 0

    def u32():
        nonlocal pos
        (v,) = struct.unpack_from("<I", buf, pos)
        pos += 4
        return v

    def string():
        nonlocal pos
        n = u32()
        s = buf[pos:pos + n].decode("utf-8")
        pos += n
        return s

    count = u32()
    out = []
    for _ in range(count):
        key = string()
        words = [string() for _ in range(u32())]
        out.append((key, words))
    if pos != len(buf):
        raise ValueError(f"{path}: 末尾に {len(buf) - pos} バイト余りました (形式が違う可能性)")
    return out


def is_skin_variant(s):
    return any(0x1F3FB <= ord(c) <= 0x1F3FF for c in s)


def main():
    dest = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/.cache/shell/emoji.json")
    ja = {k: w for k, w in read_dict(f"{DATA}/ja.dict")}
    en_list = read_dict(f"{DATA}/en.dict")
    en = {k: w for k, w in en_list}

    # 並びは、キーが多い方 (ja か en) の辞書の順。肌色のバリエーションは除く
    order = [k for k, _ in en_list]
    seen = set(order)
    order += [k for k in ja if k not in seen]
    items = []
    for k in order:
        if is_skin_variant(k):
            continue
        items.append({"e": k, "ja": ja.get(k, []), "en": en.get(k, [])})

    os.makedirs(os.path.dirname(dest), exist_ok=True)
    tmp = dest + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(items, f, ensure_ascii=False, separators=(",", ":"))
    os.replace(tmp, dest)
    print(f"{len(items)} 件 -> {dest}")


if __name__ == "__main__":
    main()
