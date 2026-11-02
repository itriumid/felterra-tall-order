#!/usr/bin/env python3
"""Posts a published release to Itrium's Discord server, in #releases.

    python3 tools/announce_release.py <release.json> [--ping-role <role ID>] [--dry-run]

<release.json> is a GitHub release object: the event payload's `release` in a workflow, or
`gh api repos/itriumid/felterra-tall-order/releases/tags/<tag>` by hand. The webhook address
comes from the DISCORD_RELEASES_WEBHOOK environment variable and is never printed. With
--dry-run, the message is printed instead of sent. Standard library only.
"""
import argparse
import json
import os
import re
import sys
import urllib.error
import urllib.request

PINK = 0xFEBFCA  # Rhodonite's pastel pink, the brand's accent.
DESCRIPTION_LIMIT = 4096  # Discord's limit for an embed's description.
ICON = "https://raw.githubusercontent.com/itriumid/felterra-tall-order/main/icon.png"
PLATFORMS = [  # (part of the build's file name, what players call it)
    ("windows", "Windows"),
    ("macos", "macOS"),
    ("linux_x86_64", "Linux"),
    ("linux_arm64", "Linux (ARM)"),
]


def notes(body, url):
    """The release notes in Discord's markdown: headings become bold lines (embeds don't
    show headings), and GitHub's own footer lines go."""
    lines = []
    for line in (body or "").replace("\r\n", "\n").split("\n"):
        heading = re.match(r"^#{1,6}\s+(.*)$", line)
        if heading:
            if heading.group(1).strip().lower() == "what's new":
                continue  # The title already says it.
            line = f"**{heading.group(1).strip()}**"
        if line.startswith("**Full Changelog**") or line.startswith("## New Contributors"):
            continue
        lines.append(line)
    text = re.sub(r"\n{3,}", "\n\n", "\n".join(lines)).strip()
    if len(text) <= DESCRIPTION_LIMIT:
        return text
    more = f"\n\n[Read the rest on GitHub]({url})"
    cut = text[: DESCRIPTION_LIMIT - len(more)]
    # End at a whole line, so a bullet or a link is never cut in half.
    return cut[: cut.rfind("\n")].rstrip() + more


def downloads(assets):
    links = []
    for key, name in PLATFORMS:
        asset = next((a for a in assets if key in a["name"].lower()), None)
        if asset:
            links.append(f"[{name}]({asset['browser_download_url']})")
    return " · ".join(links)


def message(release, ping_role=None):
    embed = {
        "title": release["name"] or release["tag_name"],
        "url": release["html_url"],
        "color": PINK,
        "description": notes(release.get("body"), release["html_url"]),
        "footer": {"text": "itrium.id/tall-order"},
    }
    if release.get("published_at"):
        embed["timestamp"] = release["published_at"]
    links = downloads(release.get("assets", []))
    if links:
        embed["fields"] = [{"name": "Download", "value": links}]
    payload = {
        "username": "Felterra: Tall Order",
        "avatar_url": ICON,
        "embeds": [embed],
        # Nobody is notified unless named here: never @everyone by accident.
        "allowed_mentions": {"parse": [], "roles": [ping_role] if ping_role else []},
    }
    if ping_role:
        payload["content"] = f"<@&{ping_role}> A new version is out."
    return payload


def send(payload, webhook):
    request = urllib.request.Request(webhook + "?wait=true", data=json.dumps(payload).encode(), method="POST",
                                     headers={"Content-Type": "application/json", "User-Agent": "felterra-tall-order"})
    try:
        with urllib.request.urlopen(request, timeout=30):
            pass
    except urllib.error.HTTPError as error:
        # The error body is Discord's explanation; the address itself is never shown.
        sys.exit(f"Discord refused the announcement ({error.code}): {error.read().decode(errors='replace')[:500]}")


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("release", help="a GitHub release object, as JSON")
    parser.add_argument("--ping-role", help="the Discord role to notify")
    parser.add_argument("--dry-run", action="store_true", help="print the message instead of sending it")
    arguments = parser.parse_args()
    with open(arguments.release) as file:
        release = json.load(file)
    payload = message(release, arguments.ping_role)
    if arguments.dry_run:
        print(json.dumps(payload, indent=2, ensure_ascii=False))
        return
    webhook = os.environ.get("DISCORD_RELEASES_WEBHOOK")
    if not webhook:
        sys.exit("DISCORD_RELEASES_WEBHOOK isn't set.")
    send(payload, webhook)
    print(f"Announced {embed_title(payload)} on Discord.")


def embed_title(payload):
    return payload["embeds"][0]["title"]


if __name__ == "__main__":
    main()
