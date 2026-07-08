"""Tests for the guards - the safety system must itself be verified, or the
'tough' claim is hollow. Each guard is exercised on pass and fail cases."""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
G = ROOT / "guards"


def run(script, *args):
    r = subprocess.run([sys.executable, str(G / script), *map(str, args)],
                       capture_output=True, text=True)
    return r.returncode, r.stdout + r.stderr


def write(tmp_path, name, text):
    p = tmp_path / name
    p.write_text(text)
    return p


# ---- check_plan ----------------------------------------------------------
TIGHT = """# PLAN
## Goal
Add a helper.
## Base branch
main
## Tasks
### T1: add x to a.py
- **files**: `a.py`
- **change**: append ```def x(): return 1```
- **test**: `python3 -m pytest -q`
- **accept**: `1 passed`
- **verify**: what does x() return and which line returns it?
## Final verification
- **command**: `python3 -m pytest -q`
- **accept**: `pass`
"""


def test_plan_accepts_tight(tmp_path):
    rc, _ = run("check_plan.py", write(tmp_path, "P.md", TIGHT))
    assert rc == 0


def test_plan_rejects_vague_change(tmp_path):
    bad = TIGHT.replace("append ```def x(): return 1```", "fix it as appropriate")
    rc, out = run("check_plan.py", write(tmp_path, "P.md", bad))
    assert rc == 1 and "vague" in out.lower()


def test_plan_rejects_missing_verify(tmp_path):
    bad = TIGHT.replace(
        "- **verify**: what does x() return and which line returns it?\n", "")
    rc, out = run("check_plan.py", write(tmp_path, "P.md", bad))
    assert rc == 1 and "verify" in out.lower()


def test_plan_rejects_no_tasks(tmp_path):
    bad = "# PLAN\n## Goal\nx\n## Base branch\nmain\n## Tasks\n## Final verification\n"
    rc, _ = run("check_plan.py", write(tmp_path, "P.md", bad))
    assert rc == 1


# ---- check_answers -------------------------------------------------------
def test_answers_accepts_code_cited(tmp_path):
    p = write(tmp_path, "P.md", "# PLAN\n### T1: x\n")
    a = write(tmp_path, "A.md",
              "## T1\nQ: empty?\nA: yes - a.py:4 uses `(text or '')` so it returns ''.\n")
    rc, _ = run("check_answers.py", p, a)
    assert rc == 0


def test_answers_rejects_handwavy(tmp_path):
    p = write(tmp_path, "P.md", "# PLAN\n### T1: x\n")
    a = write(tmp_path, "A.md", "## T1\nQ: empty?\nA: yes it works\n")
    rc, out = run("check_answers.py", p, a)
    assert rc == 1 and "hand-wavy" in out.lower()


def test_answers_rejects_missing_section(tmp_path):
    p = write(tmp_path, "P.md", "# PLAN\n### T1: x\n### T2: y\n")
    a = write(tmp_path, "A.md", "## T1\nQ: ?\nA: a.py:1 `return 1`\n")  # no T2
    rc, _ = run("check_answers.py", p, a)
    assert rc == 1


# ---- scan_secrets (needs a git repo) -------------------------------------
def _git_repo(tmp_path):
    subprocess.run(["git", "init", "-q"], cwd=tmp_path)
    subprocess.run(["git", "config", "user.email", "t@t.t"], cwd=tmp_path)
    subprocess.run(["git", "config", "user.name", "t"], cwd=tmp_path)
    return tmp_path


def _staged_scan(tmp_path):
    return subprocess.run(
        [sys.executable, str(G / "scan_secrets.py"), "--staged"],
        cwd=tmp_path, capture_output=True, text=True)


def test_secrets_blocks_a_key(tmp_path):
    repo = _git_repo(tmp_path)
    (repo / "c.py").write_text('KEY = "sk-or-v1-' + "a" * 40 + '"\n')
    subprocess.run(["git", "add", "c.py"], cwd=repo)
    r = _staged_scan(repo)
    assert r.returncode == 1 and "BLOCK" in r.stdout


def test_secrets_passes_clean(tmp_path):
    repo = _git_repo(tmp_path)
    (repo / "c.py").write_text("x = 1\n")
    subprocess.run(["git", "add", "c.py"], cwd=repo)
    r = _staged_scan(repo)
    assert r.returncode == 0


# ---- check_protected -----------------------------------------------------
def test_protected_blocks_env(tmp_path):
    repo = _git_repo(tmp_path)
    (repo / ".protected").write_text("*.env\n")
    (repo / "prod.env").write_text("SECRET=1\n")
    subprocess.run(["git", "add", "prod.env"], cwd=repo)
    r = subprocess.run(
        [sys.executable, str(G / "check_protected.py"), "--staged"],
        cwd=repo, capture_output=True, text=True,
        env={"PROTECTED_FILE": ".protected", "PATH": __import__("os").environ["PATH"]})
    assert r.returncode == 1 and "prod.env" in r.stdout
