#!/usr/bin/env python3
"""Dependency-free scan for obvious committed secrets."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SKIP_DIRS = {".git", ".dart_tool", ".idea", "build", "coverage", "__pycache__", "reports"}
TEXT_SUFFIXES = {"", ".dart", ".json", ".kts", ".md", ".py", ".sh", ".yaml", ".yml"}
PATTERN = re.compile(
    "(" + "sk" + "_live_|" + "service_" + r"role\s*=|" + "SUPABASE_SERVICE_" + r"ROLE_KEY\s*=)",
    re.IGNORECASE,
)


def candidates():
    for path in ROOT.rglob("*"):
        if not path.is_file() or any(part in SKIP_DIRS for part in path.parts):
            continue
        if path.suffix.lower() in TEXT_SUFFIXES or path.name.startswith(".env"):
            yield path


def main() -> int:
    hits = []
    for path in candidates():
        try:
            text = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        for line_number, line in enumerate(text.splitlines(), 1):
            if PATTERN.search(line):
                hits.append(f"{path.relative_to(ROOT)}:{line_number}")
    if hits:
        print("ERROR: possible committed secret detected:")
        print("\n".join(hits))
        return 1
    print("REPOSITORY SECRET SCAN PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
