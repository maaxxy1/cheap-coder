# PLAN

## Goal
Add a `slugify(text)` helper to `strutil.py` that lowercases, replaces runs of
non-alphanumerics with a single hyphen, and trims leading/trailing hyphens. Done
when the tests pass and the empty/edge cases are explained.

## Base branch
main

## Keep on Claude (do NOT hand to the executor)
- none (pure mechanical helper)

## Tasks

### T1: add slugify() to strutil.py
- **files**: `strutil.py`
- **change**: append exactly this function:
  ```python
  import re

  def slugify(text: str) -> str:
      s = re.sub(r"[^a-z0-9]+", "-", (text or "").lower())
      return s.strip("-")
  ```
- **test**: `python3 -m pytest tests/test_strutil.py -q`
- **accept**: `4 passed`
- **verify**: What does `slugify("  Hello, World! ")` return and which part of the
  regex/`strip` produces it? What does `slugify("")` return - which code path
  handles the empty input without crashing? Why does `"a--b"` collapse to `a-b`?

### T2: add tests for slugify
- **files**: `tests/test_strutil.py`
- **change**: create the file with exactly:
  ```python
  from strutil import slugify

  def test_basic(): assert slugify("Hello World") == "hello-world"
  def test_punctuation(): assert slugify("  Hi, there! ") == "hi-there"
  def test_empty(): assert slugify("") == ""
  def test_collapse(): assert slugify("a---b") == "a-b"
  ```
- **test**: `python3 -m pytest tests/test_strutil.py -q`
- **accept**: `4 passed`
- **verify**: Does `test_empty` actually exercise the empty branch, or is it a
  tautology? Which line would fail if the `.strip("-")` were removed?

## Final verification
- **command**: `python3 -m pytest -q`
- **accept**: `all pass`
