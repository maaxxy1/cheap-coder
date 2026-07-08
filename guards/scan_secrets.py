#!/usr/bin/env python3
"""Block the executor's diff if it exposes a secret. A cheap model will happily
paste a key it saw in the environment straight into a file. This scans the staged
+ unstaged diff against the base branch for common secret shapes.

Usage: python3 guards/scan_secrets.py [base_branch]   (default: main)
Exit 0 = clean. Exit 1 = a secret is in the diff - do NOT commit/merge.
"""
import re
import subprocess
import sys

PATTERNS = [
    (r"sk-[A-Za-z0-9_-]{20,}", "OpenAI/Anthropic-style key"),
    (r"sk-or-v1-[A-Za-z0-9]{20,}", "OpenRouter key"),
    (r"gh[pousr]_[A-Za-z0-9]{30,}", "GitHub token"),
    (r"AKIA[0-9A-Z]{16}", "AWS access key id"),
    (r"AIza[0-9A-Za-z_-]{30,}", "Google API key"),
    (r"xox[baprs]-[0-9A-Za-z-]{10,}", "Slack token"),
    (r"-----BEGIN [A-Z ]*PRIVATE KEY-----", "private key block"),
    (r"eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}", "JWT"),
    (r"(?i)(api[_-]?key|secret|token|password)\s*[=:]\s*['\"][^'\"]{12,}['\"]",
     "hardcoded credential assignment"),
]


def diff(base):
    try:
        if base == "--staged":
            # pre-commit hook mode: only the staged changes about to land.
            return subprocess.run(["git", "diff", "--cached", "-U0"],
                                  capture_output=True, text=True).stdout
        added = subprocess.run(
            ["git", "diff", f"{base}...HEAD", "-U0"],
            capture_output=True, text=True).stdout
        working = subprocess.run(
            ["git", "diff", "-U0"], capture_output=True, text=True).stdout
        return added + "\n" + working
    except Exception as e:
        print(f"  [WARN] could not read git diff: {e}")
        return ""


def main(base):
    text = diff(base)
    added_lines = [ln[1:] for ln in text.splitlines()
                   if ln.startswith("+") and not ln.startswith("+++")]
    hits = []
    for line in added_lines:
        for pat, label in PATTERNS:
            if re.search(pat, line):
                # Don't flag the .example placeholders / empty assignments.
                if 'KEY=""' in line or "example" in line.lower():
                    continue
                hits.append((label, line.strip()[:80]))
    if hits:
        print("SECRET SCAN FAILED - do not commit/merge:")
        for label, snippet in hits:
            print(f"  [BLOCK] {label}: {snippet}")
        return 1
    print("secret scan clean.")
    return 0


if __name__ == "__main__":
    base = sys.argv[1] if len(sys.argv) > 1 else "main"
    sys.exit(main(base))
