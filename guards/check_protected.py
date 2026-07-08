#!/usr/bin/env python3
"""Block the diff if it touches a protected path. The executor (a cheap model)
must never edit secrets, CI, infra, or the guard system itself. The `.protected`
file lists globs; anything the executor's diff touches that matches is a hard
stop.

Usage: python3 guards/check_protected.py [base_branch]   (default: main)
Exit 0 = clean. Exit 1 = a protected file was touched.
"""
import fnmatch
import os
import subprocess
import sys


def protected_globs():
    path = os.environ.get("PROTECTED_FILE", ".protected")
    if not os.path.exists(path):
        return []
    return [ln.strip() for ln in open(path)
            if ln.strip() and not ln.startswith("#")]


def changed(base):
    committed = subprocess.run(["git", "diff", "--name-only", f"{base}...HEAD"],
                               capture_output=True, text=True).stdout.split()
    working = subprocess.run(["git", "diff", "--name-only"],
                             capture_output=True, text=True).stdout.split()
    staged = subprocess.run(["git", "diff", "--name-only", "--cached"],
                            capture_output=True, text=True).stdout.split()
    return set(committed) | set(working) | set(staged)


def main(base):
    globs = protected_globs()
    if not globs:
        print("no .protected globs configured - skipping.")
        return 0
    files = changed(base)
    hits = [f for f in files if any(fnmatch.fnmatch(f, g) for g in globs)]
    if hits:
        print("PROTECTED FILES TOUCHED - do not commit/merge:")
        for f in sorted(hits):
            print(f"  [BLOCK] {f}")
        return 1
    print(f"protected check clean ({len(files)} files changed, none protected).")
    return 0


if __name__ == "__main__":
    base = sys.argv[1] if len(sys.argv) > 1 else "main"
    sys.exit(main(base))
