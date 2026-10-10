#!/usr/bin/env python3
"""tools/gen_icon_map.py - regenerate helpers/icons.lua as a VMNF map.

Deterministic generator: parses the archive's sketchybar-app-font ligature
table (~340 app names) + the legacy hand-written map, resolves every
ligature name to a VictorMono Nerd Font glyph, and emits helpers/icons.lua
with UTF-8 glyph literals. Run twice → identical output.

  python3 tools/gen_icon_map.py

Resolution order (per ligature name, e.g. "microsoft_teams"):
  1. OVERRIDES        explicit brand fixes (curated - edit HERE, not the
                      output, so regen stays stable)
  2. exact            prefix preference: md- > dev- > fa- > seti- >
                      custom- > bare
  3. normalized       underscores↔spaces; progressive token stripping
                      (suffix: microsoft_power_point → power_point →
                      power; prefix: drop microsoft_/google_/apple_/
                      jetbrains_ platform tokens first)
  4. KEYWORDS         the archive's generic ligatures (bank, book,
                      calculator, calendar, gear, dollar, desktop,
                      terminal, default, one_password, …)
  5. CATEGORIES       token-set heuristics (browser/terminal/chat/…)
  6. fallback         md-window_maximize - generic window glyph.
                      (NOTE: the task spec named U+F03A4 as the generic
                      window, but in THIS VMNF build F03A4 is
                      md-numeric_1_box - a "1" in a box. F05AF is the
                      real filled window glyph; flip FALLBACK if the
                      other codepoint is ever insisted upon.)

Only cmap codepoints are ever emitted (every tier resolves THROUGH the
cmap index), so tofu is impossible by construction. The script asserts
every OVERRIDES/KEYWORDS/CATEGORIES glyph exists and exits nonzero on a
miss (fail loudly at generation time, never at bar-render time).
"""

import re
import sys
from pathlib import Path

from fontTools.ttLib import TTFont

CONFIG = Path(__file__).resolve().parent.parent
ARCHIVE = Path.home() / ".config/sketchybar.archive-20260814220554/config/icons.lua"
OUTPUT = CONFIG / "helpers/icons.lua"
FONT = Path.home() / "Library/Fonts/VictorMonoNerdFont-Regular.ttf"

# The pre-rewrite hand-written helpers/icons.lua merged at generation time.
# FROZEN here (not parsed live): the generator's own output replaces that
# file, so re-parsing it would silently drop these entries after the first
# run (observed live - the first idempotency check lost 8 apps).
LEGACY_EXTRA = {
    "Activity Monitor": "default",
    "Another Redis Desktop Manager": "mongodb",
    "LibreOffice": "default",
    "MacVirt": "parallels",
    "Microsoft OneNote": "notes",
    "Sublime Merge": "sublime_text",
    "ZOC": "terminal",
    "draw.io": "draw_io",
}

# ---------------------------------------------------------------------------
# curation tables (edit these, NOT the generated output)
# ---------------------------------------------------------------------------

OVERRIDES = {
    # ligature name          -> NF glyph name          (why)
    # browsers without NF brand glyphs
    "arc": "md-web_box",  # Arc browser
    "brave_browser": "md-web_box",
    "vivaldi": "md-web_box",
    "libre_wolf": "md-web_box",
    "min_browser": "md-web_box",
    "qute_browser": "md-web_box",
    "mullvad_browser": "md-shield_lock",  # privacy browser
    "tor_browser": "md-shield_lock",
    # chat platforms without glyphs
    "dingtalk": "md-forum",
    "kakaotalk": "md-forum",
    "line": "md-message_text",
    "messenger": "md-message_text",
    "mattermost": "md-forum",
    "wecom": "md-wechat",  # WeChat Work
    "signal": "md-message_text",  # md-signal is the BARS glyph - wrong
    "bilibili": "md-play_box",  # video platform
    # terminals without glyphs
    "kitty": "md-console",
    "iterm": "md-console",
    "warp": "md-console",
    "wezterm": "md-console",
    "alacritty": "md-console",
    "hyper": "md-console",
    "kakoune": "md-console",
    "zoc": "md-console",
    # editors/IDEs
    "sublime_text": "md-code_tags",  # no Sublime glyph in NF
    "zed": "md-code_tags",
    "nova": "md-code_tags",
    "tower": "md-source_branch",  # Git Tower
    "vscodium": "cod-vscode",
    "code": "cod-vscode",
    "web_storm": "dev-webstorm",
    "idea": "md-code_tags",  # no dev-idea in VMNF; generic IDE
    # Apple system apps
    "app_store": "md-apple",
    "sf_symbols": "md-apple_keyboard_command",
    "spotlight": "md-magnify",
    "face_time": "md-video",
    "messages": "md-message_text",
    "maps": "md-map",
    "notes": "md-notebook",
    "reminders": "md-calendar_clock",
    "things": "md-calendar_check",  # assert present
    "pages": "md-file_document_edit",  # assert present
    "keynote": "md-presentation",  # assert present
    "numbers": "md-chart_bar",
    "preview": "md-file_pdf_box",
    "pdf": "md-file_pdf_box",
    "pdf_expert": "md-file_pdf_box",
    "finder": "md-apple_finder",
    "default": "md-window_maximize",  # generic window
    "power": "md-power",
    # security/passwords
    "one_password": "md-onepassword",
    "bit_warden": "md-shield_lock",  # dev-bitwarden absent in VMNF
    "kee_pass_x_c": "md-key",
    # media
    "mpv": "md-play_circle",
    "vlc": "md-play_circle",
    "jellyfin": "md-play_box",
    "tidal": "md-music",
    "qqmusic": "md-music",
    "podcasts": "md-podcast",
    "music": "md-music",
    # MS brand fixes (some exist, some don't - pin them all)
    "microsoft_power_point": "md-microsoft_powerpoint",
    "microsoft_word": "md-microsoft_word",
    "microsoft_excel": "md-microsoft_excel",
    "microsoft_outlook": "md-microsoft_outlook",
    "microsoft_teams": "md-microsoft_teams",
    "microsoft_edge": "md-microsoft_edge",
    "microsoft_remote_desktop": "md-monitor",
    "openvpn_connect": "md-shield_lock",
    "nord_vpn": "md-shield_lock",
    # misc archive generics
    "desktop": "md-desktop_mac",
    "gear": "md-cog",
    "dollar": "md-currency_usd",
    "bank": "md-bank",
    "book": "md-book_open",
    "calculator": "md-calculator",
    "calendar": "md-calendar_month",
    "terminal": "md-console",
    "mail": "md-email",
    "text": "md-text_box",
    "twitter": "md-twitter",
    "github_desktop": "dev-git",
    "draw_io": "md-vector_square",
    "affinity_designer": "md-vector_square",
    "affinity_designer_2": "md-vector_square",
    "affinity_photo": "md-image",
    "affinity_photo_2": "md-image",
    "affinity_publisher": "md-book_open",
    "affinity_publisher_2": "md-book_open",
    "final_cut_pro": "md-movie_edit",
    "logicpro": "md-music",
    "lightroom": "md-image",
    "lightroomclassic": "md-image",
    "photoshop": "dev-photoshop",
    "davinciresolve": "md-movie_edit",
    "prusaslicer": "md-cube",
    "orcaslicer": "md-cube",
    "bambu_studio": "md-cube",
    "fusion": "md-cube",
    "godot": "md-cube",  # game engine
    "league_of_legends": "md-controller_classic",
    "steam": "md-steam",
    "minecraft": "md-minecraft",
    "parallels": "md-laptop",
    "vmware_fusion": "md-laptop",
    "citrix": "md-laptop",
    "sequel_ace": "md-database",
    "sequel_pro": "md-database",
    "tinyrdm": "md-database",
    "mongodb": "dev-mongodb",
    "mamp": "md-server",
    "pihole": "md-shield",
    "home_assistant": "md-home",
    "obs": "md-video",
    "obsstudio": "md-video",
    "team_speak": "md-headphones",
    "toggl_track": "md-timer",  # assert present
    "raindrop_io": "md-bookmark",  # assert present
    "reeder5": "md-newspaper",
    "zotero": "md-book_open",
    "joplin": "md-notebook",
    "logseq": "md-notebook",
    "anytype": "md-notebook",
    "inkdrop": "md-notebook",
    "bear": "md-notebook",
    "drafts": "md-pen",
    "pomodone": "md-calendar_clock",
    "todoist": "md-calendar_check",
    "tick_tick": "md-calendar_check",
    "omni_focus": "md-calendar_check",
    "notability": "md-pen",
    "keyboard_maestro": "md-apple_keyboard_command",
    "alfred": "md-magnify",
    "bettertouchtool": "md-tune",
    "devonthink3": "md-file_document",
    "element": "md-forum",
    "pine": "md-email",
    "iris": "md-widgets",
    "miro": "md-palette",
    "linear": "md-layers",
    "notion": "dev-notion",
    "click_up": "md-check_bold",  # assert present
    "trello": "md-layers",
    "grammarly": "md-pen",
    "matlab": "md-math_integral",  # wait: probed md-math_integral OK
    "noodl": "md-widgets",
    "quantumult_x": "md-shield_lock",
    "yuque": "md-notebook",
    "xcode": "md-language_swift",
    # second curation pass (archive names that fell through)
    "adobe_bridge": "md-image",  # Adobe asset browser
    "airmail": "md-email",
    "app_eraser": "md-eraser",
    "bluos_controller": "md-speaker",
    "caprine": "md-message_text",  # FB Messenger wrapper
    "color_picker": "md-eyedropper_variant",
    "coteditor": "md-text_box",  # plain-text editor
    "ableton": "md-music",  # Ableton Live
    "orion": "md-web_box",  # Orion browser
    "parsec": "md-monitor",  # remote desktop
    "setapp": "md-apps",
    "spark": "md-email",  # Spark mail
    "tana": "md-notebook",
    "zeplin": "md-layers",
    "zulip": "md-forum",
    "folx": "md-download",  # assert present
    "doublecmd": "md-folder",
    "transmit": "md-folder",
    "audacity": "md-microphone",
    "blender": "md-cube",
    "inkscape": "dev-inkscape",
    "figma": "dev-figma",
    "sketch": "dev-sketch",
    "discord": "md-discord",
    "slack": "md-slack",
    "zoom": "md-video",
    "firefox": "md-firefox",
    "firefox_developer_edition": "md-firefox",
    "google_chrome": "md-google_chrome",  # assert present
    "opera": "md-opera",
    "telegram": "fa-telegram",
    "whats_app": "md-whatsapp",
    "wechat": "md-wechat",
    "qq": "fa-qq",
    "netease_music": "md-music",
    "yandex_music": "md-music",
    "spotify": "md-spotify",
    "docker": "md-docker",
    "postman": "md-flask",  # hmm: probed md-flask OK
    "insomnia": "md-flask",
    "cypress": "md-flask",
    "replit": "md-code_tags",
    "cloud": "md-cloud",
    "dropbox": "md-cloud",
    "evernote_legacy": "md-notebook",
    "vim": "custom-vim",  # official Vim logo (nicer than dev-vim)
    "neovim": "custom-neovim",
    "neovide": "custom-neovim",
    "emacs": "custom-emacs",
    "macvim": "custom-vim",
    "thunderbird": "linux-thunderbird",
    "localsend": "md-cellphone",
    "lm_studio": "md-brain",
    "openai": "md-robot",  # ChatGPT archive ligature
    "wallpaper": "md-image",
    "weather": "md-weather_partly_rainy",
}

# Generic archive ligatures that KEYWORDS already handle are folded into
# OVERRIDES above for one-table curation; CATEGORIES below only catches
# names not otherwise resolved.

CATEGORIES = [
    # (token set - match if ANY token of the ligature name is in the set, glyph)
    ({"browser", "wolf", "tor"}, "md-web_box"),
    ({"terminal", "console", "shell"}, "md-console"),
    ({"mail"}, "md-email"),
    ({"chat", "talk", "forum"}, "md-forum"),
    ({"music"}, "md-music"),
    ({"vpn", "proxy"}, "md-shield_lock"),
    ({"password", "secret"}, "md-key"),
    ({"sql", "db", "database", "mongo", "redis"}, "md-database"),
    ({"pdf"}, "md-file_pdf_box"),
    ({"player", "video", "movie"}, "md-movie"),
    ({"editor", "code", "ide"}, "md-code_tags"),
    ({"note", "notes", "journal"}, "md-notebook"),
    ({"calendar", "todo"}, "md-calendar_clock"),
    ({"design", "draw"}, "md-palette"),
    ({"3d", "print", "slicer"}, "md-cube"),
    ({"weather", "forecast"}, "md-weather_partly_rainy"),
]

# Final fallback (see module docstring for the U+F03A4 story).
FALLBACK = "md-window_maximize"

PREFIXES = ["md", "dev", "fa", "seti", "custom"]
PLATFORM_TOKENS = {"microsoft", "google", "apple", "jetbrains", "openai", "apache"}


def load_cmap():
    font = TTFont(str(FONT))
    cmap = font.getBestCmap()
    # glyph name -> codepoint (first codepoint wins; deterministic order)
    by_name = {}
    for cp in sorted(cmap):
        by_name.setdefault(cmap[cp], cp)
    return by_name


def parse_lua_apps(path):
    """Extract ["App"] = ":ligature:" pairs from a Lua icons file."""
    text = path.read_text(encoding="utf-8")
    pairs = {}
    for m in re.finditer(r'\["([^"]+)"\]\s*=\s*":([A-Za-z0-9_.\-]+):"', text):
        pairs[m.group(1)] = m.group(2)
    return pairs


def resolve(name, by_name):
    """Return (glyph_name, tier)."""

    def exists(g):
        return g if g in by_name else None

    # 1. overrides
    if name in OVERRIDES:
        g = OVERRIDES[name]
        if g and exists(g):
            return g, "override"
        if g is None:
            del OVERRIDES[name]  # scrubbed placeholder
        # a missing override glyph falls through - the assert pass below
        # will catch it separately

    # 2. exact with prefix preference
    for p in PREFIXES:
        g = exists(f"{p}-{name}")
        if g:
            return g, "exact"

    # 3. normalized: spaces<->underscores, token stripping
    tokens = name.replace(" ", "_").split("_")
    candidates = []
    # suffix stripping (full first): a_b_c -> a_b -> a
    for i in range(len(tokens) - 1, 0, -1):
        candidates.append("_".join(tokens[:i]))
    # platform-prefix stripping
    if tokens[0] in PLATFORM_TOKENS and len(tokens) > 1:
        candidates.append("_".join(tokens[1:]))
        for i in range(len(tokens) - 1, 1, -1):
            candidates.append("_".join(tokens[1:i]))
    for cand in candidates:
        for p in PREFIXES:
            g = exists(f"{p}-{cand}")
            if g:
                return g, "normalized"

    # 4/5. categories (token match) - overrides table above covers the
    # archive's generic ligatures explicitly
    tok = set(tokens)
    for members, glyph in CATEGORIES:
        if tok & members and exists(glyph):
            return glyph, "category"

    # 6. fallback
    return FALLBACK, "fallback"


def main():
    by_name = load_cmap()

    # assert every curated glyph exists (fail loudly, not at render time)
    missing = []
    for table in (OVERRIDES, {v: v for _, v in CATEGORIES}, {"__fb__": FALLBACK}):
        for g in set(table.values()):
            if g and g not in by_name:
                missing.append(g)
    if missing:
        print("MISSING CURATED GLYPHS:", sorted(set(missing)))
        sys.exit(1)

    apps = parse_lua_apps(ARCHIVE)
    apps.update(LEGACY_EXTRA)

    stats = {"override": 0, "exact": 0, "normalized": 0, "category": 0, "fallback": 0}
    fell_back, resolved = [], {}
    for app in sorted(apps):
        glyph, tier = resolve(apps[app], by_name)
        stats[tier] += 1
        resolved[app] = (glyph, by_name[glyph], tier)
        if tier == "fallback":
            fell_back.append(f"{app} -> {apps[app]}")

    lines = [
        "-- helpers/icons.lua - app-name → VictorMono Nerd Font glyph map.",
        "-- GENERATED by tools/gen_icon_map.py - do not hand-edit; curate the",
        "--   generator's OVERRIDES/CATEGORIES tables instead, then regen:",
        "--     python3 tools/gen_icon_map.py",
        f"--   (archive ligature table + legacy map → VMNF cmap, {len(resolved)} apps;",
        "--    every codepoint verified against the font's cmap - no tofu)",
        "",
        "local map = {",
    ]
    for app in sorted(resolved):
        glyph, cp, tier = resolved[app]
        note = "" if tier in ("override", "exact", "normalized") else f" -- {tier}"
        lines.append(f'\t["{app}"] = "{chr(cp)}",{note}')
    fallback_cp = by_name[FALLBACK]
    lines += [
        "}",
        "",
        f'local DEFAULT_ICON = "{chr(fallback_cp)}" -- {FALLBACK} (U+{fallback_cp:04X})',
        "",
        "-- case-insensitive index (built once at load)",
        "local lower_map = {}",
        "for name, glyph in pairs(map) do",
        "\tlower_map[name:lower()] = glyph",
        "end",
        "",
        "local icons = {}",
        "",
        "--- Return the NF glyph for an application name (generic window if unknown).",
        "function icons.get(app_name)",
        "\tif app_name == nil then",
        "\t\treturn DEFAULT_ICON",
        "\tend",
        "\treturn map[app_name] or lower_map[app_name:lower()] or DEFAULT_ICON",
        "end",
        "",
        "return icons",
        "",
    ]
    OUTPUT.write_text("\n".join(lines), encoding="utf-8")

    print(f"resolved {len(resolved)} apps from {ARCHIVE.name} + legacy map")
    for tier in ("override", "exact", "normalized", "category", "fallback"):
        print(f"  {tier:11} {stats[tier]}")
    if fell_back:
        print("FELL BACK TO GENERIC:")
        for f in fell_back:
            print("  ", f)
    else:
        print("no fallbacks - full coverage")


if __name__ == "__main__":
    main()
