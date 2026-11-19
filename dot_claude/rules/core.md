# How I like to work

Short on purpose: these load into every session. The reasons are here so you can apply
them sensibly instead of mechanically.

## Code
- Prefer small, focused functions and files. Split a file once it mixes several concerns
  or grows past a few hundred lines; that makes review and parallel agents easier.
- Prefer returning new values over mutating inputs in place. Hidden mutation is the most
  common source of bugs in my data code. In-place is fine for clear performance reasons
  (large arrays, hot loops): say so in a comment.
- Validate at boundaries (CLI args, files, APIs, user input) and fail early with a message
  that says what was wrong. Inside the code, trust the types.
- Handle errors explicitly. Never swallow an exception silently, and don't add try/except
  just to make an error disappear.
- No secrets in code or in the dotfiles repo (it's public). Read them from env vars, `.env`
  files that git ignores, or KeePassXC.
- Before writing a helper, check whether the standard library, an existing dependency or a
  well-known package already does it.

## Changes and verification
- Match the scope I asked for. Mention adjacent problems you notice instead of fixing them
  unasked.
- After a behaviour change, run the relevant tests (or a quick real check) and report the
  actual result, including failures. Add or adjust tests for the behaviour you changed;
  coverage numbers matter less than testing the logic that can break.
- Use judgement on process: a one-line fix doesn't need a plan or a subagent; a multi-file
  feature benefits from a short plan first.

## Git
- Conventional commits: `feat|fix|refactor|docs|test|chore|perf|ci: <what and why>`. No AI
  attribution lines.
- Commit only when asked. Never force-push or rewrite pushed history without asking.

## Tools
- Shell commands go through `rtk` automatically (see RTK.md); nothing to do.
- For library APIs that change often (polars, pandas, numpy), check the installed version's
  docs or source rather than relying on memory.
