#!/usr/bin/env python3
from pathlib import Path


def replace_block(path: str, start: str, end: str, replacement: str) -> None:
    file = Path(path)
    text = file.read_text(encoding="utf-8")
    begin = text.find(start)
    if begin < 0:
        raise SystemExit(f"missing start marker in {path}: {start}")
    finish = text.find(end, begin)
    if finish < 0:
        raise SystemExit(f"missing end marker in {path}: {end}")
    finish += len(end)
    file.write_text(text[:begin] + replacement + text[finish:], encoding="utf-8")


def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    text = file.read_text(encoding="utf-8")
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"expected one anchor in {path}, found {count}: {old}")
    file.write_text(text.replace(old, new, 1), encoding="utf-8")


readme_start = "<!-- SORTIFY_DISPATCH_V484_WEBUI_ACTION_LAUNCH_HOTFIX_README_START -->"
readme_end = "<!-- SORTIFY_DISPATCH_V484_WEBUI_ACTION_LAUNCH_HOTFIX_README_END -->"
readme_block = """<!-- SORTIFY_DISPATCH_V484_WEBUI_ACTION_LAUNCH_HOTFIX_README_START -->
## Sortify Dispatch 4.8.4

Current release: `4.8.4-webui-action-launch-hotfix` / `versionCode=31`.

This release fixes two WebUI failures from 4.8.3:

- the module-manager Action button no longer opens a loopback URL after its local WebUI server has already stopped;
- productive **Sort now** no longer depends on one long browser request. Preview stays synchronous and read-only, while productive sorting runs as a background Job and remains observable until completion.

Existing Sortify settings and persistent configuration are preserved during the update. Sortify uses shared WebUI Core 0.6.3 and keeps SSH Drop Dispatcher policy `v4115`.

Install `Sortify-Dispatch-4.8.4-webui-action-launch-hotfix.zip` with a Magisk/KernelSU-compatible module manager and reboot once.
<!-- SORTIFY_DISPATCH_V484_WEBUI_ACTION_LAUNCH_HOTFIX_README_END -->"""
replace_block("README.md", readme_start, readme_end, readme_block)
replace_once("README.md", "Current release: `4.8.3-webui-actions-hotfix`.", "Previous release: `4.8.3-webui-actions-hotfix`.")
replace_once("README.md", "**Version:** 4.8.3-webui-actions-hotfix", "**Version:** 4.8.4-webui-action-launch-hotfix")
replace_once(
    "README.md",
    "1. Download `Sortify-Dispatch-4.8.3-webui-actions-hotfix.zip` from Releases.",
    "1. Download `Sortify-Dispatch-4.8.4-webui-action-launch-hotfix.zip` from Releases.",
)
replace_once(
    "README.md",
    "The shared WebUI Core 0.6.1 provides typed Settings, Actions, Jobs and Inventory views through an authenticated loopback session.",
    "The shared WebUI Core 0.6.3 provides typed Settings, Actions, Jobs and Inventory views through an authenticated loopback session.",
)

changelog_start = "<!-- SORTIFY_DISPATCH_V484_WEBUI_ACTION_LAUNCH_HOTFIX_CHANGELOG_START -->"
changelog_end = "<!-- SORTIFY_DISPATCH_V484_WEBUI_ACTION_LAUNCH_HOTFIX_CHANGELOG_END -->"
changelog_block = """<!-- SORTIFY_DISPATCH_V484_WEBUI_ACTION_LAUNCH_HOTFIX_CHANGELOG_START -->
## 4.8.4-webui-action-launch-hotfix - WebUI Action Launch Hotfix

- Fixed the module-manager Action button opening an unreachable local WebUI.
- Fixed productive **Sort now** showing a network error on large Download trees; productive sorting now runs as a background Job while Preview remains synchronous.
- Preserved existing Sortify settings and persistent configuration across the update.
<!-- SORTIFY_DISPATCH_V484_WEBUI_ACTION_LAUNCH_HOTFIX_CHANGELOG_END -->"""
replace_block("CHANGELOG.md", changelog_start, changelog_end, changelog_block)

Path("RELEASE_NOTES_v4.8.4-webui-action-launch-hotfix.md").write_text(
    """# Sortify Dispatch 4.8.4 – WebUI Action Launch Hotfix

## What changed

- Fixes the module-manager Action button opening an unreachable local WebUI.
- Fixes productive **Sort now** showing a network error on large Download trees. Productive sorting now runs as a background Job while Preview stays synchronous.
- Preserves existing Sortify settings and persistent configuration across the update.

Install or update `Sortify-Dispatch-4.8.4-webui-action-launch-hotfix.zip` with a Magisk/KernelSU-compatible module manager and reboot once.
""",
    encoding="utf-8",
)

Path("update.json").write_text(
    """{
  \"version\": \"4.8.4-webui-action-launch-hotfix\",
  \"versionCode\": 31,
  \"zipUrl\": \"https://github.com/Lycidias93/Sortify-Dispatch/releases/download/v4.8.4-webui-action-launch-hotfix/Sortify-Dispatch-4.8.4-webui-action-launch-hotfix.zip\",
  \"changelog\": \"https://raw.githubusercontent.com/Lycidias93/Sortify-Dispatch/main/RELEASE_NOTES_v4.8.4-webui-action-launch-hotfix.md\"
}
""",
    encoding="utf-8",
)

print("RESULT: SORTIFY_V484_PUBLIC_FRONTDOOR_PROMOTION_PASS")
