# SCOPE
<!-- What Claude writes AFTER interrogating you, before any code. -->

## Goal
Add a `slugify(text)` helper so we can turn titles into URL-safe slugs
("Hello, World!" -> "hello-world"). Done when it handles normal text, punctuation,
empty input, and repeated separators, with tests.

## Surfaces in play (existing vs new)
- `strutil.py` (existing module) - add one function.
- `tests/test_strutil.py` (new) - the tests.

## Intended behaviour (incl. empty / error / edge cases)
- Normal: "Hello World" -> "hello-world"
- Punctuation/spaces -> collapse to a single hyphen
- Empty/None input -> "" (must not crash)
- "a---b" -> "a-b" (no repeated hyphens)

## Constraints
- No new dependencies (stdlib `re` only). Touch only the two files above.

## Definition of done / how we verify
- `python3 -m pytest -q` is green.
- The empty-input and collapse cases are explained against the actual code.

## Keep on Claude (too subtle for the cheap executor)
- none. Pure mechanical helper - safe to hand down.

## Open questions still unanswered
- none.
