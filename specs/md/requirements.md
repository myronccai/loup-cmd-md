# Requirements: md

## Introduction

`md` (also `mkdir`) is the cmd.exe built-in that creates directories. With
command extensions enabled, the default, it also creates every missing
directory on the way. This repository recreates it in Loup for Linux,
keeping Windows' operand syntax (`\` separators, `/?` help), messages and
ERRORLEVELs. It is the second Windows command in the loup-cmd series and
uses the shared Windows code in `source/win/`, copied from loup-cmd-type.

## Requirements

### Requirement 1: Create directories

**User Story:** As a cmd user, I want `md a\b\c` to create the whole path so
that I do not have to create each level myself.

#### Acceptance Criteria

1. WHEN md is given a path that does not exist, THE program SHALL create it,
   with every missing intermediate directory, print nothing and exit 0.
2. WHEN md is given several operands, THE program SHALL create them in
   command-line order.
3. THE program SHALL accept `\` and `/` as separators, ignore separators at
   the end, and resolve `.` and `name\..` by name before creating anything
   (`a\..\b` creates `b` only).
4. THE program SHALL check that each directory exists after creating it.

### Requirement 2: Errors

**User Story:** As a script author, I want Windows' messages and ERRORLEVELs
so that scripts written for cmd behave the same.

#### Acceptance Criteria

1. WHEN the path already exists as a directory, a file or any other entry
   (a symbolic link that leads nowhere), THE program SHALL print
   `A subdirectory or file X already exists.` with X as typed (separators
   shown as `\`).
2. WHEN something on the way is not a directory, THE program SHALL print
   `The system cannot find the path specified.`
3. WHEN an operand is empty or contains `< > : " | ? *` or a control
   character, THE program SHALL print
   `The filename, directory name, or volume label syntax is incorrect.`
4. WHEN the directory cannot be created for another reason (permissions),
   THE program SHALL print `Access is denied.`
5. WHEN an operand fails and md was given several, THE program SHALL follow
   the message with `Error occurred while processing: X.` and go on with the
   next operand.
6. WHEN no operand is given, THE program SHALL print
   `The syntax of the command is incorrect.`
7. THE program SHALL write messages to standard error and exit 1 if any
   operand failed, 0 otherwise.

### Requirement 3: Switches

**User Story:** As a cmd user, I want `md /?` to explain the command.

#### Acceptance Criteria

1. WHEN `/?` or `-?` appears among the arguments, THE program SHALL print a
   short help text and exit 0 without creating anything.
2. THE program SHALL treat every other argument, including `/X` and `-X`, as
   a directory name (md has no switches), and everything after `--` as a
   directory name.
3. WHEN `--version` is the only argument, THE program SHALL print
   `md (loup-cmd-md) 0.1.0`; `--help` alone SHALL print the help.
4. THE build SHALL also provide the command as `mkdir` (a symbolic link).
