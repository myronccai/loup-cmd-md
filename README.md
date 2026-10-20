# loup-cmd-md

The Windows `md` (and `mkdir`) command recreated in
[Loup](https://code-craft.ai/references/loup): create directories, with any
missing ones on the way, using cmd's `\` paths, messages and ERRORLEVELs, on
Linux.

Part of the **loup-cmd** series of example applications: classic Linux and
Windows commands, and projects for each Loup execution mode, each in its own
repository under [myronccai](https://github.com/myronccai?tab=repositories&q=loup-cmd).
This one is `host.dual` Loup built as a native binary. It uses the shared
Windows code in [`source/win/`](source/win/) (switch parser, wildcard
matcher, path helpers, messages), copied from
[loup-cmd-type](https://github.com/myronccai/loup-cmd-type).

## Requirements

- [Loup Lite](https://github.com/code-craft-ai-company/loup-releases) 1.26.0
  or later; see [Installing Loup Lite](#installing-loup-lite).
- `make`, and `clang` 17 or later for the native build.

## Installing Loup Lite

This example is built and tested with **Loup Lite**, the free public build of
the Loup toolchain from [Code Craft AI](https://code-craft.ai), meant for
education and training. Code Craft AI publishes the official builds,
installers and signed checksums at
**<https://github.com/code-craft-ai-company/loup-releases>**, for Linux
(x86-64, arm64), macOS (Apple silicon, Intel) and Windows (x86-64).

Linux and macOS:

```sh
curl -fsSL https://github.com/code-craft-ai-company/loup-releases/releases/latest/download/loup-install.sh | sh
```

Windows (PowerShell):

```powershell
irm https://github.com/code-craft-ai-company/loup-releases/releases/latest/download/loup-install.ps1 | iex
```

The installer picks the archive for your machine, checks it against the
release's `SHA256SUMS`, unpacks it into `~/.loup`
(`%LOCALAPPDATA%\Programs\Loup` on Windows) and puts its `bin` directory on
your `PATH`; it needs no administrator rights. You get `loup`, the Stage0
compiler `loup-bootstrap` and the Wasm runtime `loup-launcher`. Open a new
shell and check:

```sh
loup --version             # loup 1.26.0 or later
```

CI installs the exact version it tests with, 1.26.0. To do the same:

```sh
curl -fsSL https://github.com/code-craft-ai-company/loup-releases/releases/download/v1.26.0/loup-install.sh | sh -s -- --version 1.26.0
```

To install by hand, download your platform's archive from the
[releases page](https://github.com/code-craft-ai-company/loup-releases/releases),
check it against `SHA256SUMS`, unpack it anywhere and add its `bin` directory to
`PATH`. The [loup-releases README](https://github.com/code-craft-ai-company/loup-releases#verify-a-download)
explains how to verify the Sigstore signature on `SHA256SUMS`.

Loup Lite leaves out Loup's cryptography library and the full set of Loup
packages; this example needs neither. The full release is at
<https://code-craft.ai/loup/download>, and commercial use of Loup needs a
license: <https://code-craft.ai/loup/license>.

## Usage

```sh
make build                     # native binary build/md, and build/mkdir (a symlink to it)
make ci                        # check, unit tests, build, end-to-end tests
make run ARGS="build/tmp/new"  # run from source with loup run
```

Quote operands that contain `\` so that the Linux shell passes them through.

```text
$ build/md 'demo\projects\loup\src'
$ find demo -type d | sort
demo
demo/projects
demo/projects/loup
demo/projects/loup/src
$ build/md 'demo\projects'; echo "ERRORLEVEL $?"
A subdirectory or file demo\projects already exists.
ERRORLEVEL 1
$ build/md 'demo\docs' 'demo\projects' 'demo\logs'; echo "ERRORLEVEL $?"
A subdirectory or file demo\projects already exists.
Error occurred while processing: demo\projects.
ERRORLEVEL 1
$ build/md 'demo\notes.txt\old'
The system cannot find the path specified.
$ build/md 'demo\*.bak'
The filename, directory name, or volume label syntax is incorrect.
$ build/mkdir 'demo\a\..\b'
$ ls demo
b
docs
logs
notes.txt
projects
$ build/md
The syntax of the command is incorrect.
$ build/md '/?'
Create directories.

MD path [path ...]
MKDIR is the same command.

  path  A directory to create, with \ or / between names. Missing
        directories on the way are created as well: MD a\b\c works
        when a does not exist yet.

A path that already exists is reported, and md goes on with the others.
$ build/md --version
md (loup-cmd-md) 0.1.0
```

`md path [path ...]` (`mkdir` is the same command)

- Each path is created with every missing directory on the way, as cmd does
  with command extensions enabled (the default). Success prints nothing.
- Operands accept `\` and `/`; separators at the end are ignored, and `.`
  and `name\..` are resolved by name first (`a\..\b` creates only `b`).
- A path that already exists, as a directory, a file or a dangling symbolic
  link: `A subdirectory or file X already exists.` (X as typed).
- A file on the way (`notes.txt\old`): `The system cannot find the path
  specified.`
- A name with `< > : " | ? *` or a control character, or an empty operand:
  `The filename, directory name, or volume label syntax is incorrect.` md
  does not expand wildcards.
- Anything else that stops the directory from being made (no write
  permission): `Access is denied.`
- With several operands, a failure is followed by `Error occurred while
  processing: X.` and md goes on with the next one.
- md has no switches: `/?` (or `-?`) anywhere prints a short help, every
  other argument (also `/X` or `-X`) is a directory name, and `--` ends
  switch parsing. `--help` and `--version` work as the only argument.

Messages go to standard error. Exit status (ERRORLEVEL): `0` if every
directory was created, `1` if any operand failed or none was given.

## Differences from the original

- `mkdir` is a symlink to the same binary (`build/mkdir`); both print `md`
  in `--version`.
- Names are case-sensitive on Linux: `md A` next to an existing `a` creates
  a second directory.
- Trailing dots and spaces in names are kept (Windows drops them), device
  names (`CON`, `NUL`, ...) are ordinary names, and there are no drive
  letters: a path that starts with `\` or `/` starts at the Linux root.
- Every failure other than the ones listed above is reported as `Access is
  denied.`: Loup 1.26.0's native `io.fs` reports no reason (its
  `createDir` fails silently, so md checks for the directory afterwards).
- `/?` prints a short help text of this recreation, not Windows' own.
  Messages end with LF, not CRLF.
- The roadmap planned an optional `windows-latest` CI job with this
  repository; the series decided on Linux-only CI (native Windows builds
  are a preview in Loup 1.26.0), so there is none.

## Layout

```text
source/main.loup               # entry point
source/appinfo.loup            # name, version, exit statuses
source/cli/args.loup           # md's switches (none) via win.switches
source/cli/usage.loup          # /? and --version text
source/cli/app.loup            # run(): parse, dispatch, exit status
source/commands/md.loup        # target_path(), check_operand(), make_directory(), run_md()
source/win/                    # shared Windows code: switches, wildcards, paths, messages
tests/*_test.loup              # unit tests (make test)
tests/e2e.sh                   # end-to-end tests of build/md and build/mkdir (make e2e)
specs/md/                      # requirements, design, tasks
```

[AGENTS.md](AGENTS.md) has every build and test command and the conventions
for changing the code.

## License

[MIT](LICENSE), copyright 2026 Code Craft AI LLC. The Loup skill in
[`skills/loup-programmer/`](skills/loup-programmer/) is copied from the Loup
project and is not covered by this license; it keeps the Loup project's terms.
