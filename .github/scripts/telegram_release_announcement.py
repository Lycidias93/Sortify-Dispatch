#!/usr/bin/env python3
import datetime as dt
import html
import json
import os
import re
import time
import urllib.parse
import urllib.request

API = "https://api.github.com"

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

def log(msg):
    print(msg, flush=True)

def gh_json(path):
    req = urllib.request.Request(API + path, headers=HEADERS)
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read().decode("utf-8"))

def parse_time(value):
    if not value:
        return None
    try:
        return dt.datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None

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
        "published_at": env("PUBLISHED_AT"),
        "draft": False,
    }

def clean_line(line):
    line = re.sub(r"^\s{0,3}#{1,6}\s*", "", line.strip())
    line = re.sub(r"^\s*[-*+•]\s+", "", line)
    line = re.sub(r"^\s*\d+[.)]\s+", "", line)
    line = re.sub(r"`([^`]+)`", r"\1", line)
    line = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", line)
    line = re.sub(r"[*_~]", "", line)
    line = re.sub(r"\s+", " ", line).strip()
    return line

def release_body_items(body):
    skip_heading = re.compile(
        r"^(artifact unchanged|artifact sha256|sha256|checksum|checksums|assets|downloads?|download|install command|usage|output)\s*:?$",
        re.I,
    )
    hash_line = re.compile(r"^(sha256:\s*)?[a-f0-9]{32,}(\s+\S+)?$", re.I)
    skip_noise = re.compile(r"(```|</?details|</?summary)", re.I)
    items = []
    seen = set()
    skip_artifact_block = False
    in_code = False
    for raw in (body or "").splitlines():
        raw_s = raw.strip()
        if raw_s.startswith("```"):
            in_code = not in_code
            continue
        if in_code:
            continue
        if not raw_s:
            skip_artifact_block = False
            continue
        line = clean_line(raw_s)
        if not line:
            continue
        if skip_heading.match(line):
            skip_artifact_block = True
            continue
        if skip_artifact_block and (hash_line.match(line) or line.lower().endswith((".zip", ".apk", ".tgz", ".tar.gz"))):
            continue
        if hash_line.match(line):
            continue
        if skip_noise.search(line):
            continue
        if line.lower().startswith(("http://", "https://")):
            continue
        if line.endswith(":"):
            continue
        item = line[:300]
        key = item.lower()
        if key not in seen:
            seen.add(key)
            items.append(item)
    return items


def compact_prerelease_line(line):
    line = clean_line(str(line))
    line = re.sub(r"\s*[:：]\s*$", "", line).strip()
    line = re.sub(r"\s+", " ", line).strip()
    return line[:180]


def prerelease_candidate_items(body, limit=8):
    """Return compact end-user candidate lines for prerelease posts."""
    skip = re.compile(
        r"(verified|verification|android |pixel 10|mustang|credits?|harish|codecity|joshua|sha256|"
        r"artifact|download|install command|tombstone|tensorconservative|research-only|blocked:|"
        r"commit|cherry-pick|mockup|audit|docs?|read-only helper|pass\.?$|^no |^final verified|"
        r"contributors?|github release|http|```|</?details|</?summary)",
        re.I,
    )
    heading = re.compile(r"^(highlights?|what changed|changes?|changelog|summary|verified|credits?|artifact unchanged)\s*:?$", re.I)
    positive = re.compile(
        r"(add|adds|added|enable|enables|enabled|support|supports|supported|fix|fixes|fixed|"
        r"improve|improves|improved|preserve|preserves|preserved|keep|keeps|kept|restore|restores|"
        r"restored|prevent|prevents|prevented|fallback|use-last|saved settings|setting|settings|"
        r"outdoor|profile|zram|thermal|battery|boot|runtime|module manager|description|layout|"
        r"overlay|polling|throttle|memory|control)",
        re.I,
    )
    out = []
    seen = set()
    in_code = False
    for raw in (body or "").splitlines():
        raw_s = raw.strip()
        if raw_s.startswith("```"):
            in_code = not in_code
            continue
        if in_code or not raw_s:
            continue
        item = compact_prerelease_line(raw_s)
        if not item or len(item) < 8:
            continue
        if heading.match(item):
            continue
        if skip.search(item):
            continue
        if not positive.search(item):
            continue
        key = item.lower()
        if key not in seen:
            seen.add(key)
            out.append(item)
        if len(out) >= limit:
            return out
    return out


def important_prerelease_items(items, limit=2):
    """Pick only important end-user prerelease features/fixes."""
    positive = re.compile(
        r"(add|adds|added|enable|enables|enabled|support|supports|supported|fix|fixes|fixed|"
        r"improve|improves|improved|preserve|preserves|preserved|keep|keeps|kept|restore|restores|"
        r"restored|prevent|prevents|prevented|fallback|use-last|saved settings|setting|settings|"
        r"outdoor|profile|zram|thermal|battery|boot|runtime|module manager|description|layout|"
        r"overlay|polling|throttle|memory|control)",
        re.I,
    )
    noise = re.compile(
        r"(verified|verification|android |pixel 10|mustang|credits?|harish|codecity|joshua|sha256|"
        r"artifact|download|install command|tombstone|tensorconservative|research-only|blocked:|"
        r"commit|cherry-pick|mockup|audit|docs?|read-only helper|pass\.?$|^no |^final verified|"
        r"contributors?|github release|http)",
        re.I,
    )
    shouting = re.compile(r"^[A-Z0-9_ ./-]{18,}$")
    out = []
    seen = set()
    for raw in items or []:
        item = compact_prerelease_line(raw)
        if not item or len(item) < 8 or noise.search(item):
            continue
        if shouting.match(item) and item.upper() == item:
            continue
        if not positive.search(item):
            continue
        key = item.lower()
        if key not in seen:
            seen.add(key)
            out.append(item)
        if len(out) >= limit:
            return out
    return out

def previous_public_release(release):
    try:
        releases = gh_json(f"/repos/{REPO}/releases?per_page=100")
    except Exception as exc:
        log(f"WARN: previous_release_lookup_failed {exc}")
        return None
    current_id = str(release.get("id") or "")
    tag = release.get("tag_name") or ""
    current_time = parse_time(release.get("published_at") or release.get("created_at") or "")
    candidates = []
    for rel in releases:
        if str(rel.get("id") or "") == current_id:
            continue
        if rel.get("tag_name") == tag:
            continue
        if rel.get("draft") or rel.get("prerelease"):
            continue
        rel_time = parse_time(rel.get("published_at") or rel.get("created_at") or "")
        if current_time and rel_time and rel_time >= current_time:
            continue
        candidates.append((rel_time or dt.datetime.min.replace(tzinfo=dt.timezone.utc), rel))
    if not candidates:
        return None
    candidates.sort(key=lambda item: item[0], reverse=True)
    return candidates[0][1]

def compare_commit_bullets(previous_tag, current_tag):
    if not previous_tag or not current_tag:
        return []
    base = urllib.parse.quote(previous_tag, safe="")
    head = urllib.parse.quote(current_tag, safe="")
    try:
        data = gh_json(f"/repos/{REPO}/compare/{base}...{head}")
    except Exception as exc:
        log(f"WARN: compare_failed {exc}")
        return []
    out = []
    seen = set()
    for commit in data.get("commits", []):
        msg = (commit.get("commit", {}).get("message") or "").splitlines()[0]
        item = clean_line(msg)[:180]
        lower = item.lower()
        if not item:
            continue
        if lower.startswith(("merge pull request", "merge branch", "release ")):
            continue
        if "telegram release" in lower:
            continue
        if lower not in seen:
            seen.add(lower)
            out.append(item)
    return out

def split_messages(header_parts, changelog_heading, bullets, release_url, max_len=3600):
    messages = []
    header = "\n\n".join(header_parts + [changelog_heading])
    current = header
    base = header
    for item in bullets:
        bullet = f"• {html.escape(item)}"
        candidate = current + "\n" + bullet
        if len(candidate) > max_len and current != base:
            messages.append(current)
            current = f"{changelog_heading} (continued)\n{bullet}"
            base = f"{changelog_heading} (continued)"
        elif len(candidate) > max_len:
            messages.append(current)
            current = f"{changelog_heading} (continued)\n{bullet}"
            base = f"{changelog_heading} (continued)"
        else:
            current = candidate
    link = f'<a href="{html.escape(release_url)}">Open GitHub Release</a>'
    if len(current + "\n\n" + link) > max_len:
        messages.append(current)
        messages.append(link)
    else:
        messages.append(current + "\n\n" + link)
    return messages

def build_messages(release):
    tag = release.get("tag_name") or ""
    title = (release.get("name") or tag).strip()
    url = release.get("html_url") or f"https://github.com/{REPO}/releases/tag/{urllib.parse.quote(tag)}"
    prerelease = bool(release.get("prerelease"))
    kind = "Pre-release" if prerelease else "Release"
    display_title = title if title and title != tag else f"{kind} {tag}"
    header = [
        f"<b>{html.escape(REPO)}</b>",
        f"<b>{html.escape(display_title)}</b>",
    ]
    if title and title != tag:
        header.append(f"{kind}: {html.escape(tag)}")
    previous = previous_public_release(release)
    prev_tag = previous.get("tag_name") if previous else ""
    bullets = release_body_items(release.get("body") or "")
    if prerelease:
        pre_items = important_prerelease_items(bullets, limit=2)
        if not pre_items:
            pre_items = important_prerelease_items(prerelease_candidate_items(release.get("body") or ""), limit=2)
        if not pre_items:
            pre_items = important_prerelease_items(compare_commit_bullets(prev_tag, tag), limit=2)
        link = f'<a href="{html.escape(url)}">Open GitHub Pre-release</a>'
        if pre_items:
            lines = [f"• {html.escape(item)}" for item in pre_items[:2]]
            return ["\n\n".join(header + ["<b>Important changes</b>"] + lines + [link])]
        return ["\n\n".join(header + ["<b>Important changes</b>", "• See GitHub Pre-release for details.", link])]
    since = f"since {prev_tag}" if prev_tag else "since the previous public release"
    if not bullets:
        bullets = compare_commit_bullets(prev_tag, tag)
    if not bullets:
        bullets = ["See GitHub Release for details."]
    return split_messages(header, f"<b>Changelog {html.escape(since)}</b>", bullets, url)

def send_telegram(text, disable_web_page_preview=False):
    if DRY_RUN:
        log("DRY_RUN telegram_send=skip")
        log(text)
        return
    if not TELEGRAM_BOT_TOKEN or not TELEGRAM_CHAT_ID:
        raise SystemExit("FAIL: TELEGRAM_BOT_TOKEN or TELEGRAM_CHAT_ID missing")
    endpoint = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"
    payload = {"chat_id": TELEGRAM_CHAT_ID, "parse_mode": "HTML", "text": text}
    if disable_web_page_preview:
        payload["disable_web_page_preview"] = "true"
    data = urllib.parse.urlencode(payload).encode("utf-8")
    req = urllib.request.Request(endpoint, data=data, method="POST")
    with urllib.request.urlopen(req, timeout=30) as resp:
        payload = json.loads(resp.read().decode("utf-8"))
    if not payload.get("ok"):
        raise SystemExit(f"FAIL: telegram send failed: {payload}")

def selftest():
    global REPO
    REPO = "Lycidias93/example"
    pre = {
        "tag_name": "v1.5.1-universal-test.2",
        "name": "Pre-release v1.5.1-universal-test.2",
        "html_url": "https://github.com/Lycidias93/example/releases/tag/v1.5.1-universal-test.2",
        "prerelease": True,
        "body": "Prerelease test for Pixel 10 Thermal & Memory Control.\nWhat changed\nAdds dynamic module manager description:\nVerified:\nPixel 10 Pro XL / mustang\nCredits Somebody",
    }
    stable = {
        "tag_name": "v9.9.9",
        "name": "Release v9.9.9",
        "html_url": "https://github.com/Lycidias93/example/releases/tag/v9.9.9",
        "prerelease": False,
        "body": "Highlights:\n• stable changelog line must be posted\nVerified:\n• verified detail must be posted\nArtifact unchanged:\n• file.zip\n• SHA256: 225013f7e51cb29b1ceebb1460f6f5125c134518ae900c2587f4416c2b6f057f",
    }
    pre_msg = build_messages(pre)[0]
    stable_msg = "\n---\n".join(build_messages(stable))
    assert "<b>Important changes</b>" in pre_msg
    assert "Adds dynamic module manager description" in pre_msg
    assert "Pixel 10" not in pre_msg
    assert "Credits" not in pre_msg
    assert "Open GitHub Pre-release" in pre_msg
    assert "stable changelog line must be posted" in stable_msg
    assert "verified detail must be posted" in stable_msg
    assert "225013f7" not in stable_msg
    assert "file.zip" not in stable_msg
    log("PASS: pre_compact_visual_important_changelog")
    log("PASS: pre_noise_filtered")
    log("PASS: stable_full_changelog")
    log("PASS: artifact_noise_filtered")
    log("== prerelease preview ==")
    log(pre_msg)
    log("== stable preview ==")
    log(stable_msg)
    log("RESULT: TELEGRAM_ANNOUNCEMENT_SELFTEST_PASS rc=0")

def main_announcement():
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
    for idx, message in enumerate(messages, 1):
        log(f"telegram_message={idx}/{len(messages)} chars={len(message)}")
        send_telegram(message, disable_web_page_preview=bool(release.get("prerelease")))
        time.sleep(0.5)
    log("RESULT: TELEGRAM_RELEASE_ANNOUNCEMENT_DONE rc=0")

if __name__ == "__main__":
    main_announcement()
