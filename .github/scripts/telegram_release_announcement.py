#!/usr/bin/env python3
import html
import json
import os
import re
import time
import urllib.parse
import urllib.request

API = "https://api.github.com"
USER_CHANGE_HEADINGS = {
    "what changed",
    "what changes for users",
    "changelog",
}


def env(name, default=""):
    return os.environ.get(name, default)


TOKEN = env("GITHUB_TOKEN") or env("GH_TOKEN")
TELEGRAM_BOT_TOKEN = env("TELEGRAM_BOT_TOKEN")
TELEGRAM_CHAT_ID = env("TELEGRAM_CHAT_ID")
REPO = env("REPO")
DRY_RUN = env("DRY_RUN", "false").lower() == "true"

HEADERS = {
    "Accept": "application/vnd.github+json",
    "User-Agent": "telegram-release-announcement",
    "X-GitHub-Api-Version": "2022-11-28",
}
if TOKEN:
    HEADERS["Authorization"] = f"Bearer {TOKEN}"


def log(message):
    print(message, flush=True)


def gh_json(path):
    request = urllib.request.Request(API + path, headers=HEADERS)
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.loads(response.read().decode("utf-8"))


def release_from_event_or_tag():
    manual_tag = env("MANUAL_RELEASE_TAG").strip()
    if manual_tag:
        return gh_json(f"/repos/{REPO}/releases/tags/{urllib.parse.quote(manual_tag, safe='')}")
    tag = env("TAG_NAME").strip()
    if not tag:
        raise SystemExit("FAIL: TAG_NAME or MANUAL_RELEASE_TAG required")
    return {
        "id": env("RELEASE_ID"),
        "tag_name": tag,
        "name": env("RELEASE_NAME") or tag,
        "html_url": env("RELEASE_URL") or f"https://github.com/{REPO}/releases/tag/{urllib.parse.quote(tag)}",
        "prerelease": env("IS_PRERELEASE", "false").lower() == "true",
        "body": env("RELEASE_BODY"),
        "draft": False,
    }


def clean_inline(value):
    value = re.sub(r"`([^`]+)`", r"\1", value)
    value = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", value)
    value = re.sub(r"[*_~]", "", value)
    return re.sub(r"\s+", " ", value).strip()


def user_change_bullets(body):
    bullets = []
    seen = set()
    in_user_section = False
    for raw in (body or "").splitlines():
        stripped = raw.strip()
        heading = re.match(r"^#{1,6}\s+(.+?)\s*$", stripped)
        if heading:
            title = clean_inline(heading.group(1)).rstrip(":").lower()
            in_user_section = title in USER_CHANGE_HEADINGS
            continue
        if not in_user_section:
            continue
        match = re.match(r"^[-*+•]\s+(.+?)\s*$", stripped)
        if not match:
            continue
        item = clean_inline(match.group(1))
        if not item or item.lower() in seen:
            continue
        seen.add(item.lower())
        bullets.append(item[:320])
    return bullets


def split_messages(header_parts, bullets, release_url, max_len=3600):
    heading = "<b>What changed</b>"
    base = "\n\n".join(header_parts + [heading])
    current = base
    messages = []
    for item in bullets:
        bullet = f"• {html.escape(item)}"
        candidate = current + "\n" + bullet
        if len(candidate) > max_len and current != base:
            messages.append(current)
            current = f"{heading} (continued)\n{bullet}"
        else:
            current = candidate
    link = f'<a href="{html.escape(release_url)}">Open GitHub Release</a>'
    if len(current + "\n\n" + link) > max_len:
        messages.extend([current, link])
    else:
        messages.append(current + "\n\n" + link)
    return messages


def build_messages(release):
    tag = str(release.get("tag_name") or "").strip()
    title = str(release.get("name") or tag).strip()
    url = str(release.get("html_url") or f"https://github.com/{REPO}/releases/tag/{urllib.parse.quote(tag)}")
    prerelease = bool(release.get("prerelease"))
    header = [f"<b>{html.escape(REPO)}</b>", f"<b>{html.escape(title or tag)}</b>"]
    if prerelease:
        return ["\n\n".join(header + [f'<a href="{html.escape(url)}">Open GitHub Pre-release</a>'])]
    bullets = user_change_bullets(release.get("body") or "")
    if not bullets:
        raise SystemExit("FAIL: stable release body must contain bullets under a user-facing 'What changed' section")
    return split_messages(header, bullets, url)


def send_telegram(text):
    if DRY_RUN:
        log("DRY_RUN telegram_send=skip")
        log(text)
        return
    if not TELEGRAM_BOT_TOKEN or not TELEGRAM_CHAT_ID:
        raise SystemExit("FAIL: TELEGRAM_BOT_TOKEN or TELEGRAM_CHAT_ID missing")
    endpoint = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"
    data = urllib.parse.urlencode({
        "chat_id": TELEGRAM_CHAT_ID,
        "parse_mode": "HTML",
        "text": text,
    }).encode("utf-8")
    request = urllib.request.Request(endpoint, data=data, method="POST")
    with urllib.request.urlopen(request, timeout=30) as response:
        payload = json.loads(response.read().decode("utf-8"))
    if not payload.get("ok"):
        raise SystemExit(f"FAIL: telegram send failed: {payload}")


def selftest():
    global REPO
    REPO = "Lycidias93/example"
    release = {
        "tag_name": "v9.9.9",
        "name": "Release 9.9.9",
        "html_url": "https://github.com/Lycidias93/example/releases/tag/v9.9.9",
        "prerelease": False,
        "body": """# Release 9.9.9

## What changed
- User-visible feature
- Fixed a visible bug

## Internal verification
- CI run 123
- sha256 deadbeef

## Compatibility
No action required.
""",
    }
    message = "\n---\n".join(build_messages(release))
    assert "User-visible feature" in message
    assert "Fixed a visible bug" in message
    assert "CI run 123" not in message
    assert "deadbeef" not in message
    try:
        build_messages({**release, "body": "## Internal verification\n- CI only"})
    except SystemExit:
        pass
    else:
        raise AssertionError("stable release without user-facing bullets must fail")
    log("RESULT: TELEGRAM_ANNOUNCEMENT_SELFTEST_PASS rc=0")


def main():
    if env("TELEGRAM_ANNOUNCEMENT_SELFTEST") == "1":
        selftest()
        return
    if not REPO:
        raise SystemExit("FAIL: REPO missing")
    release = release_from_event_or_tag()
    if release.get("draft"):
        raise SystemExit("FAIL: draft release cannot be announced")
    messages = build_messages(release)
    log(f"repo={REPO}")
    log(f"tag={release.get('tag_name')}")
    log(f"prerelease={bool(release.get('prerelease'))}")
    log(f"messages={len(messages)}")
    for index, message in enumerate(messages, 1):
        log(f"telegram_message={index}/{len(messages)} chars={len(message)}")
        send_telegram(message)
        time.sleep(0.5)
    log("RESULT: TELEGRAM_RELEASE_ANNOUNCEMENT_DONE rc=0")


if __name__ == "__main__":
    main()
