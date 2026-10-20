# Design: md

## Overview

`main()` passes `runtime.args()` to `cli.app.run`, which parses them with the
shared switch parser (`win.switches`, no switches declared), handles `/?`
and `--version`, and calls `commands.md.run_md`. `run_md` handles each
operand in turn with `make_directory`, which returns `""` or the message to
print, and prints the failures.

## Modules

| Module | Contents |
|---|---|
| `source/main.loup` | entry point: `run(runtime.args())` |
| `source/appinfo.loup` | name, version, summary, exit statuses (0 and 1) |
| `source/cli/args.loup` | `Options`, `md_switches()` (none), `parse_args` via `win.switches` |
| `source/cli/usage.loup` | `usage()` (this recreation's own short help), `version_line()` |
| `source/cli/app.loup` | `run()`: parse, help/version, run, exceptions to status 1 |
| `source/commands/md.loup` | `has_invalid_chars`, `target_path`, `entry_present`, `check_operand`, `make_directory`, `failure_lines`, `run_md` |
| `source/win/` | the shared Windows code: switches, wildcards, paths, messages |

`check_operand` decides before anything is created:

1. an empty operand or one with a character Windows rejects in names →
   the invalid-name message (md does not expand wildcards);
2. `target_path` turns the operand into an fs path: `\` → `/`, empty
   components dropped, `.` and `name/..` resolved by name;
3. the path is already there → `A subdirectory or file X already exists.`
   `entry_present` also finds a symbolic link that leads nowhere, which
   `exists` misses because it follows links: it looks the name up in the
   parent's `listDir`;
4. a prefix of the path is an entry but not a directory → the path message.

`make_directory` then calls `io.fs.createDir` (an `mkdir -p`) and checks the
result with `isDir`: the native `createDir` fails silently, while Stage0
throws `IoError`; both end in `Access is denied.`

## Differences from the original

- Names are case-sensitive on Linux: `md A` next to an existing `a` creates
  a second directory.
- Trailing dots and spaces in names are kept (Windows drops them), and
  device names (`CON`, `NUL`, ...) are ordinary names.
- No drive letters; a path starting with `\` or `/` starts at the root.
- Every failure that is not one of the cases above is `Access is denied.`
  (Loup 1.26.0's io.fs reports no reason).
- `/?` prints a short help text of this recreation, not Windows' own.
- `--version` and `--help` (alone) are series conventions.
- `mkdir` is a symbolic link to the same binary; both print `md` in
  `--version`.
- Messages end with LF, not CRLF.

## Error handling

Every failure is reported per operand and processing continues; the exit
status is 1 if any operand failed. An unexpected exception is printed on
standard error and gives status 1.

## Testing

- `tests/args_test.loup`: everything is a directory except `/?`; `--`.
- `tests/md_test.loup`: invalid characters, `target_path`, `check_operand`
  for new, existing and blocked paths, `make_directory`, `failure_lines`.
- `tests/app_test.loup`: exit statuses through `run()`.
- `tests/win_*_test.loup`: the shared Windows code.
- `tests/e2e.sh`: runs the native binary (and the `mkdir` link) in a fresh
  fixture tree under `$TMP` per case, compares standard output and standard
  error exactly and the resulting tree.
