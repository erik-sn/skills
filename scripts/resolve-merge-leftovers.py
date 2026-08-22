#!/usr/bin/env python3
"""Resolve leftover git merge conflicts with Anthropic Sonnet.

Leftovers are unmerged paths still present after mechanical ours/theirs.
Writes each resolved file to the working tree. The caller stages and commits.

Requires ANTHROPIC_API_KEY. Optional ANTHROPIC_MODEL (default claude-sonnet-4-6).
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
import urllib.error
import urllib.request

API_URL = "https://api.anthropic.com/v1/messages"
DEFAULT_MODEL = "claude-sonnet-4-6"
MAX_TOKENS = 16000

SYSTEM = """You resolve leftover git merge conflicts for a personal fork of mattpocock/skills.

Rules:
- Output only the resolved file contents. No markdown fence, no commentary.
- Preserve fork-only behaviour (overlays under skills/personal, FORK.md, fork scripts, Cursor rules).
- Upstream skill bodies under skills/engineering, skills/productivity, skills/misc, skills/in-progress, and skills/deprecated stay as upstream wrote them. If both sides edited one, keep the upstream (theirs) version.
- For add/add on a fork-only path, combine both sides: keep our fork policy and any new upstream sentences that do not contradict it.
"""


def git(*args: str) -> str:
    return subprocess.check_output(["git", *args], text=True, stderr=subprocess.DEVNULL)


def git_ok(*args: str) -> str | None:
    try:
        return git(*args)
    except subprocess.CalledProcessError:
        return None


def stage_blob(path: str, stage: str) -> str | None:
    return git_ok("show", f":{stage}:{path}")


def resolve_one(path: str, key: str, model: str) -> str:
    ours = stage_blob(path, "2") or ""
    theirs = stage_blob(path, "3") or ""
    base = stage_blob(path, "1") or ""
    user = (
        f"Path: {path}\n\n"
        f"--- BASE ---\n{base}\n"
        f"--- OURS (fork) ---\n{ours}\n"
        f"--- THEIRS (upstream) ---\n{theirs}\n"
    )
    body = json.dumps(
        {
            "model": model,
            "max_tokens": MAX_TOKENS,
            "system": SYSTEM,
            "messages": [{"role": "user", "content": user}],
        }
    ).encode()
    req = urllib.request.Request(
        API_URL,
        data=body,
        method="POST",
        headers={
            "Content-Type": "application/json",
            "x-api-key": key,
            "anthropic-version": "2023-06-01",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            payload = json.loads(resp.read().decode())
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode(errors="replace")
        raise SystemExit(f"Anthropic HTTP {exc.code} for {path}: {detail}") from exc
    parts = payload.get("content") or []
    text = "".join(p.get("text", "") for p in parts if p.get("type") == "text")
    if not text.strip():
        raise SystemExit(f"empty Anthropic response for {path}")
    return text


def main() -> int:
    key = os.environ.get("ANTHROPIC_API_KEY", "").strip()
    if not key:
        print("ANTHROPIC_API_KEY is empty", file=sys.stderr)
        return 1
    model = os.environ.get("ANTHROPIC_MODEL", DEFAULT_MODEL).strip() or DEFAULT_MODEL
    paths = sys.argv[1:]
    if not paths:
        print("no leftover paths", file=sys.stderr)
        return 1
    for path in paths:
        print(f"resolving leftover {path} with {model}")
        resolved = resolve_one(path, key, model)
        parent = os.path.dirname(path)
        if parent:
            os.makedirs(parent, exist_ok=True)
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(resolved)
            if not resolved.endswith("\n"):
                fh.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
