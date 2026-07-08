# ANSWERS
<!-- What the EXECUTOR writes to prove the code works. Every answer explains the
     actual code and cites file:line - "yes it works" would be rejected by
     guards/check_answers.py. -->

## T1: add slugify() to strutil.py
Q: What does `slugify("  Hello, World! ")` return and which part produces it?
A: Returns `hello-world` - `strutil.py:4` lowercases to `"  hello, world! "`, then
   `re.sub(r"[^a-z0-9]+", "-", ...)` on the same line turns every run of
   non-alphanumerics (spaces, comma, `! `) into one `-`, giving `-hello-world-`,
   and `return s.strip("-")` on `strutil.py:5` trims the ends -> `hello-world`.

Q: What does `slugify("")` return - which path handles empty without crashing?
A: Returns `""` - `strutil.py:4` uses `(text or "")`, so an empty/None input
   becomes `""`; `re.sub` on `""` yields `""` and `"".strip("-")` is `""`. No
   indexing, so nothing can raise.

Q: Why does `"a--b"` collapse to `a-b`?
A: The `+` in `[^a-z0-9]+` (strutil.py:4) is greedy, so the whole `--` run matches
   as ONE group and is replaced by a single `-`.

## T2: add tests for slugify
Q: Does `test_empty` exercise the empty branch or is it a tautology?
A: It exercises it - `tests/test_strutil.py:5` calls `slugify("")` which drives the
   `(text or "")` path in strutil.py:4; it would fail if that guard were removed
   and the function indexed the string.

Q: Which line would fail if `.strip("-")` were removed?
A: `test_punctuation` (tests/test_strutil.py:4) - without the strip,
   `slugify("  Hi, there! ")` returns `-hi-there-`, not `hi-there`, so that assert
   fails.
