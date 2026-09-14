#!/usr/bin/env python3
"""鼠鬚管外觀編輯器 —— 本機 GUI。

只用 Python 標準函式庫。在 127.0.0.1 上開一個小網頁伺服器，
瀏覽器負責預覽（字型可以直接用系統字型渲染），這支程式負責讀寫設定、部署與快照。

用法：python3 server.py  然後開啟它印出的網址。
"""

import http.server
import json
import os
import re
import shutil
import socketserver
import subprocess
import sys
import time
import webbrowser
from datetime import datetime

HERE = os.path.dirname(os.path.abspath(__file__))
RIME_DIR = os.path.abspath(os.path.join(HERE, "..", ".."))
CUSTOM = os.path.join(RIME_DIR, "squirrel.custom.yaml")
BUILT = os.path.join(RIME_DIR, "build", "squirrel.yaml")
SNAP_DIR = os.path.join(HERE, "snapshots")
FONT_CACHE = os.path.join(HERE, ".fonts.json")
SQUIRREL_APP = "/Library/Input Methods/Squirrel.app"
SQUIRREL_BIN = os.path.join(SQUIRREL_APP, "Contents/MacOS/Squirrel")
SHARED = os.path.join(SQUIRREL_APP, "Contents/SharedSupport/squirrel.yaml")

# patch 區塊中本工具負責的設定。值型別用來決定寫回時要不要加引號。
FIELDS = {
    "color_scheme": "str", "color_scheme_dark": "str",
    "candidate_list_layout": "str", "text_orientation": "str",
    "inline_preedit": "bool", "inline_candidate": "bool",
    "status_message_type": "str", "mutual_exclusive": "bool",
    "memorize_size": "bool", "show_paging": "bool",
    "candidate_format": "quoted",
    "font_face": "quoted", "font_point": "num",
    "comment_font_face": "quoted", "comment_font_point": "num",
    "label_font_face": "quoted", "label_font_point": "num",
    "corner_radius": "num", "hilited_corner_radius": "num",
    "border_height": "num", "border_width": "num",
    "line_spacing": "num", "spacing": "num",
    "alpha": "num", "translucency": "bool",
}

COLOR_KEYS = [
    "back_color", "border_color", "text_color", "hilited_text_color",
    "hilited_back_color", "candidate_text_color", "comment_text_color",
    "label_color", "hilited_candidate_text_color",
    "hilited_candidate_back_color", "hilited_comment_text_color",
    "hilited_label_color",
]


# ---------------------------------------------------------------- 設定讀寫

def _strip_comment(raw):
    """去掉行尾註解。引號內的 # 不算註解。"""
    out, quote = [], None
    for ch in raw:
        if quote:
            out.append(ch)
            if ch == quote:
                quote = None
        elif ch in "\"'":
            quote = ch
            out.append(ch)
        elif ch == "#":
            break
        else:
            out.append(ch)
    return "".join(out).strip()


def _parse_scalar(text):
    t = _strip_comment(text)
    if len(t) >= 2 and t[0] == t[-1] and t[0] in "\"'":
        return t[1:-1]
    if t in ("true", "false"):
        return t == "true"
    try:
        return int(t)
    except ValueError:
        pass
    try:
        return float(t)
    except ValueError:
        pass
    return t


def read_settings():
    """讀 patch 區塊裡 style/xxx 的目前值。"""
    settings = {}
    if not os.path.exists(CUSTOM):
        return settings
    with open(CUSTOM, encoding="utf-8") as fh:
        for line in fh:
            m = re.match(r"^\s*style/([a-z_]+)\s*:\s*(.*)$", line)
            if m and m.group(1) in FIELDS and not line.lstrip().startswith("#"):
                settings[m.group(1)] = _parse_scalar(m.group(2))
    return settings


def _format_value(key, value):
    kind = FIELDS[key]
    if kind == "bool":
        return "true" if value else "false"
    if kind == "num":
        if isinstance(value, float) and value.is_integer():
            value = int(value)
        return str(value)
    if kind == "quoted":
        return "'%s'" % value if "'" not in str(value) else '"%s"' % value
    return str(value)


def write_settings(new):
    """就地改值，保留註解與縮排。沒有的鍵補在 patch 區塊末尾。"""
    with open(CUSTOM, encoding="utf-8") as fh:
        lines = fh.read().split("\n")

    seen, last_style_idx = set(), -1
    for i, line in enumerate(lines):
        m = re.match(r"^(\s*)style/([a-z_]+)(\s*):\s*(.*)$", line)
        if not m or line.lstrip().startswith("#"):
            continue
        indent, key, pad, rest = m.groups()
        last_style_idx = i
        if key not in new or key not in FIELDS:
            continue
        comment = ""
        stripped = _strip_comment(rest)
        if len(stripped) < len(rest.rstrip()):
            comment = rest.rstrip()[len(stripped):]
            comment = " " + comment.lstrip()
        lines[i] = "%sstyle/%s%s: %s%s" % (
            indent, key, pad, _format_value(key, new[key]), comment)
        seen.add(key)

    missing = [k for k in new if k in FIELDS and k not in seen]
    if missing and last_style_idx >= 0:
        add = ["  style/%s: %s" % (k, _format_value(k, new[k])) for k in missing]
        lines[last_style_idx + 1:last_style_idx + 1] = add

    with open(CUSTOM, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines))


# ---------------------------------------------------------------- 配色

def _rime_color_to_css(value):
    """Rime 色值是 0xBBGGRR 或 0xAABBGGRR（BGR 順序），轉成 CSS rgba()。"""
    if not isinstance(value, str):
        return None
    v = _strip_comment(value).strip().strip('"\'')
    if not v.lower().startswith("0x"):
        return None
    h = v[2:]
    if len(h) <= 6:
        h = h.rjust(6, "0")
        a, b, g, r = "ff", h[0:2], h[2:4], h[4:6]
    else:
        h = h.rjust(8, "0")
        a, b, g, r = h[0:2], h[2:4], h[4:6], h[6:8]
    try:
        return "rgba(%d,%d,%d,%.3f)" % (
            int(r, 16), int(g, 16), int(b, 16), int(a, 16) / 255.0)
    except ValueError:
        return None


def _collect_schemes(path, pattern, source):
    """從一個檔案抓出所有配色區塊。pattern 要能捕捉配色名稱。"""
    schemes = {}
    if not os.path.exists(path):
        return schemes
    with open(path, encoding="utf-8") as fh:
        lines = fh.read().split("\n")
    current, indent = None, 0
    for line in lines:
        m = re.match(pattern, line)
        if m:
            current = m.group(1)
            indent = len(line) - len(line.lstrip())
            schemes[current] = {"id": current, "label": current,
                                "source": source, "colors": {}}
            continue
        if current is None:
            continue
        if line.strip() and not line.startswith(" " * (indent + 1)):
            current = None
            continue
        km = re.match(r"^\s*([a-z_]+)\s*:\s*(.+)$", line)
        if km and not line.lstrip().startswith("#"):
            key, raw = km.group(1), km.group(2)
            if key in COLOR_KEYS:
                css = _rime_color_to_css(raw)
                if css:
                    schemes[current]["colors"][key] = css
            elif key == "name":
                # 顯示用標籤，不可覆蓋 id —— id 才是 color_scheme: 要填的值
                schemes[current]["label"] = _parse_scalar(raw)
            elif key == "author":
                schemes[current]["author"] = _parse_scalar(raw)
    return {k: v for k, v in schemes.items() if v["colors"]}


def read_schemes():
    merged = {}
    merged.update(_collect_schemes(
        SHARED, r"^  ([A-Za-z_][A-Za-z_0-9]*):\s*$", "內建"))
    merged.update(_collect_schemes(
        CUSTOM, r"^\s*preset_color_schemes/([A-Za-z_][A-Za-z_0-9]*):\s*$", "自訂"))
    return sorted(merged.values(), key=lambda s: (s["source"] != "自訂", s["id"]))


def add_scheme(name, colors):
    """把新配色寫進 squirrel.custom.yaml 的 preset_color_schemes 區。"""
    if not re.match(r"^[A-Za-z_][A-Za-z_0-9]*$", name):
        raise ValueError("配色名稱只能用英數字與底線，且不可用數字開頭")
    with open(CUSTOM, encoding="utf-8") as fh:
        text = fh.read()
    if re.search(r"^\s*preset_color_schemes/%s:\s*$" % re.escape(name), text, re.M):
        raise ValueError("配色「%s」已存在" % name)

    def to_rime(css):
        """CSS rgba() → Rime 色值。

        Rime 是 BGR 順序：不透明寫 0xBBGGRR，帶透明度寫 0xAABBGGRR。
        鼠鬚管兩種長度都吃（SquirrelConfig.swift 的 color(from:) 有兩條規則）。
        """
        m = re.match(r"rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*([\d.]+))?\)", css or "")
        if not m:
            return "0x000000"
        r, g, b = int(m.group(1)), int(m.group(2)), int(m.group(3))
        a = float(m.group(4)) if m.group(4) is not None else 1.0
        if a >= 0.999:
            return "0x%02x%02x%02x" % (b, g, r)
        return "0x%02x%02x%02x%02x" % (round(a * 255), b, g, r)

    block = ["", "  preset_color_schemes/%s:" % name,
             '    name: "%s"' % name,
             '    author: "rime-appearance"']
    for key in COLOR_KEYS:
        if key in colors:
            block.append("    %s: %s" % (key, to_rime(colors[key])))
    anchor = re.search(r"^\s*preset_color_schemes/", text, re.M)
    pos = anchor.start() if anchor else len(text)
    text = text[:pos] + "\n".join(block) + "\n\n" + text[pos:]
    with open(CUSTOM, "w", encoding="utf-8") as fh:
        fh.write(text)


# ---------------------------------------------------------------- 字型

FONT_CACHE_VERSION = 2


def read_fonts(refresh=False):
    """列出本機字型。慢（約 15 秒），所以快取。

    每筆包含 ps 與 name 兩個名稱：
      ps   —— PostScript 名稱（DFKai-W14-WINP-BF），這才是 font_face 要填的值
      name —— 可讀名稱（華康超特楷體(P)），給人看的
    """
    if not refresh and os.path.exists(FONT_CACHE):
        try:
            with open(FONT_CACHE, encoding="utf-8") as fh:
                cached = json.load(fh)
            if isinstance(cached, dict) and cached.get("v") == FONT_CACHE_VERSION:
                return cached["fonts"]
        except (ValueError, OSError, KeyError):
            pass
    try:
        out = subprocess.run(
            ["system_profiler", "-json", "SPFontsDataType"],
            capture_output=True, text=True, timeout=180).stdout
        data = json.loads(out)
    except (subprocess.SubprocessError, ValueError, OSError):
        return []
    entries = {}
    for family in data.get("SPFontsDataType", []):
        for face in family.get("typefaces", []):
            ps = face.get("_name", "")
            # 以 . 或 - 開頭的是系統內部字型，選了也用不到
            if not ps or ps.startswith(".") or ps.startswith("-"):
                continue
            fam = (face.get("family") or "").strip()
            style = (face.get("style") or "").strip()
            name = (face.get("fullname") or "").strip() or fam or ps
            # 可讀名稱以 . 開頭的同樣是系統內部字型（PostScript 名稱看不出來）
            if name.startswith("."):
                continue
            entries[ps] = {"ps": ps, "name": name, "family": fam, "style": style}
    fonts = sorted(entries.values(), key=lambda e: (e["name"], e["ps"]))
    try:
        with open(FONT_CACHE, "w", encoding="utf-8") as fh:
            json.dump({"v": FONT_CACHE_VERSION, "fonts": fonts}, fh)
    except OSError:
        pass
    return fonts


# ---------------------------------------------------------------- 快照與部署

def list_snapshots():
    if not os.path.isdir(SNAP_DIR):
        return []
    out = []
    for fn in sorted(os.listdir(SNAP_DIR), reverse=True):
        if not fn.endswith(".yaml"):
            continue
        path = os.path.join(SNAP_DIR, fn)
        stamp = fn[:-5]
        try:
            when = datetime.strptime(stamp.split("_")[0], "%Y%m%d-%H%M%S")
            label = when.strftime("%m/%d %H:%M:%S")
        except ValueError:
            label = stamp
        note_path = path + ".note"
        note = ""
        if os.path.exists(note_path):
            with open(note_path, encoding="utf-8") as fh:
                note = fh.read().strip()
        out.append({"id": stamp, "label": label, "note": note,
                    "size": os.path.getsize(path)})
    return out


def take_snapshot(note=""):
    os.makedirs(SNAP_DIR, exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    dest = os.path.join(SNAP_DIR, stamp + ".yaml")
    n = 1
    while os.path.exists(dest):
        dest = os.path.join(SNAP_DIR, "%s_%d.yaml" % (stamp, n))
        n += 1
    shutil.copy2(CUSTOM, dest)
    if note:
        with open(dest + ".note", "w", encoding="utf-8") as fh:
            fh.write(note)
    return os.path.basename(dest)[:-5]


def restore_snapshot(snap_id):
    path = os.path.join(SNAP_DIR, snap_id + ".yaml")
    if not os.path.exists(os.path.realpath(path)) or \
            os.path.dirname(os.path.realpath(path)) != os.path.realpath(SNAP_DIR):
        raise ValueError("找不到這個快照")
    take_snapshot("還原前自動備份")
    shutil.copy2(path, CUSTOM)


def deploy(timeout=25):
    """觸發部署並確認真的生效。

    Squirrel 的 --reload 只是送出一個 DistributedNotification，送完就結束，
    不回報成敗。所以這裡改看 build/squirrel.yaml 的 mtime 有沒有變。
    """
    before = os.path.getmtime(BUILT) if os.path.exists(BUILT) else 0
    try:
        subprocess.run([SQUIRREL_BIN, "--reload"], capture_output=True, timeout=15)
    except (subprocess.SubprocessError, OSError) as exc:
        return {"ok": False, "message": "無法執行鼠鬚管：%s" % exc}
    deadline = time.time() + timeout
    while time.time() < deadline:
        now = os.path.getmtime(BUILT) if os.path.exists(BUILT) else 0
        if now > before:
            return {"ok": True, "message": "已部署並確認生效"}
        time.sleep(0.5)
    return {"ok": False, "message":
            "設定已寫入，但部署沒有生效。--reload 只是送通知給執行中的程序，"
            "有時會被忽略——請從選單列的鼠鬚管圖示點「重新部署」。"}


# ---------------------------------------------------------------- HTTP

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=HERE, **kwargs)

    def log_message(self, fmt, *args):
        pass

    def _json(self, payload, status=200):
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path.startswith("/api/state"):
            return self._json({
                "settings": read_settings(),
                "schemes": read_schemes(),
                "fonts": read_fonts(),
                "snapshots": list_snapshots(),
                "rime_dir": RIME_DIR,
            })
        if self.path.startswith("/api/fonts/refresh"):
            return self._json({"fonts": read_fonts(refresh=True)})
        if self.path == "/":
            self.path = "/index.html"
        return super().do_GET()

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        try:
            payload = json.loads(self.rfile.read(length) or b"{}")
        except ValueError:
            return self._json({"ok": False, "message": "請求格式錯誤"}, 400)
        try:
            if self.path == "/api/apply":
                snap = take_snapshot(payload.get("note", ""))
                write_settings(payload.get("settings", {}))
                result = deploy()
                result["snapshot"] = snap
                result["snapshots"] = list_snapshots()
                return self._json(result)
            if self.path == "/api/rollback":
                restore_snapshot(payload["id"])
                result = deploy()
                result["snapshots"] = list_snapshots()
                result["settings"] = read_settings()
                return self._json(result)
            if self.path == "/api/scheme":
                take_snapshot("新增配色前自動備份")
                add_scheme(payload["name"], payload.get("colors", {}))
                return self._json({"ok": True, "message": "配色已新增",
                                   "schemes": read_schemes(),
                                   "snapshots": list_snapshots()})
        except (ValueError, KeyError, OSError) as exc:
            return self._json({"ok": False, "message": str(exc)}, 400)
        return self._json({"ok": False, "message": "未知的請求"}, 404)


def main():
    if not os.path.exists(CUSTOM):
        sys.exit("找不到 %s" % CUSTOM)
    if not os.path.exists(SQUIRREL_BIN):
        print("警告：找不到鼠鬚管，套用後無法自動部署。", file=sys.stderr)
    if not os.path.exists(FONT_CACHE):
        print("首次啟動，正在讀取系統字型（約 15 秒）…", flush=True)
        read_fonts()
    with socketserver.TCPServer(("127.0.0.1", 0), Handler) as httpd:
        port = httpd.server_address[1]
        url = "http://127.0.0.1:%d/" % port
        print("鼠鬚管外觀編輯器：%s" % url)
        print("設定檔：%s" % CUSTOM)
        print("按 Control+C 結束。")
        try:
            webbrowser.open(url)
        except Exception:
            pass
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n已結束。")


if __name__ == "__main__":
    main()
