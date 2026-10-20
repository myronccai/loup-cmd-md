#!/usr/bin/env bash
# End-to-end tests: run the built binary and compare its standard output
# (byte for byte), and where given its standard error, and exit status with
# the expected ones. Every case runs in a fresh fixture tree under $TMP, and
# the tree is checked afterwards: md only ever touches paths under $TMP.
#
# usage: tests/e2e.sh BINARY

set -u
BIN=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
pass=0
fail=0

# check_file NAME STATUS EXPECTED_FILE [ARGS...]
# Runs BINARY ARGS... with standard input from the file named by $IN
# (default: /dev/null) and compares standard output with EXPECTED_FILE.
# If $WANT_ERR is set, standard error must equal it too.
check_file() {
    local name=$1 want_status=$2 want_file=$3
    shift 3
    "$BIN" "$@" < "${IN:-/dev/null}" > "$TMP/out" 2> "$TMP/err"
    local status=$?
    local err_ok=1
    if [ -n "${WANT_ERR+set}" ]; then
        printf '%s' "$WANT_ERR" > "$TMP/want_err"
        cmp -s "$TMP/want_err" "$TMP/err" || err_ok=0
    fi
    if [ "$status" -eq "$want_status" ] && cmp -s "$want_file" "$TMP/out" && [ "$err_ok" -eq 1 ]; then
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
        echo "FAIL: $name (exit $status, expected $want_status)"
        diff <(od -c "$want_file") <(od -c "$TMP/out") | sed 's/^/    /' | head -20
        if [ "$err_ok" -eq 0 ]; then
            diff <(od -c "$TMP/want_err") <(od -c "$TMP/err") | sed 's/^/    stderr /' | head -20
        fi
        sed 's/^/    stderr: /' "$TMP/err" | head -5
    fi
}

# check NAME STATUS EXPECTED_STDOUT [ARGS...]
# As check_file, with the expected output given as a string. Bash strings
# cannot hold NUL bytes; use check_file for output that contains them.
check() {
    local name=$1 want_status=$2
    printf '%s' "$3" > "$TMP/want"
    shift 3
    check_file "$name" "$want_status" "$TMP/want" "$@"
}

# check_both NAME STATUS EXPECTED_STDOUT EXPECTED_STDERR [ARGS...]
check_both() {
    local name=$1 want_status=$2 want_out=$3
    local WANT_ERR=$4
    shift 4
    check "$name" "$want_status" "$want_out" "$@"
}

# The fixture tree, rebuilt before every case.
W="$TMP/w"
reset() {
    cd "$TMP" && chmod -R u+w "$W" 2>/dev/null; rm -rf "$W"
    mkdir -p "$W/old/inner"
    printf 'f\n' > "$W/file.txt"
    ln -s nowhere "$W/dangling"
    cd "$W"
}

# The tree as one line per entry: `dir/`, `link->target` or `file=content`.
state() {
    (cd "$W" && find . -mindepth 1 | LC_ALL=C sort | while read -r p; do
        if [ -L "$p" ]; then echo "${p#./}->$(readlink "$p")"
        elif [ -d "$p" ]; then echo "${p#./}/"
        else echo "${p#./}=$(cat "$p")"; fi
    done)
}

# check_state NAME EXPECTED: the tree after the last case.
check_state() {
    local got
    got=$(state)
    if [ "$got" = "$2" ]; then
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
        echo "FAIL: $1 (tree)"
        diff <(echo "$2") <(echo "$got") | sed 's/^/    /'
    fi
}

# with LINE...: the starting tree plus the given entries, sorted.
START=$'dangling->nowhere\nfile.txt=f\nold/\nold/inner/'
with() {
    { echo "$START"; for line in "$@"; do echo "$line"; done; } | LC_ALL=C sort
}

WD=${W//\//\\}
exists() { echo "A subdirectory or file $1 already exists."; }
processing() { echo "Error occurred while processing: $1."; }
invalid='The filename, directory name, or volume label syntax is incorrect.'
nopath='The system cannot find the path specified.'

# Help and version; mkdir is the same program.
reset
"$BIN" '/?' > "$TMP/help" 2>&1
if [ "$(head -1 "$TMP/help")" = 'Create directories.' ]; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL: /? help"; fi
check      "-? among operands"  0 "$(cat "$TMP/help")"$'\n'     new '-?'
check_state "-? creates nothing" "$START"
check      "--help"             0 "$(cat "$TMP/help")"$'\n'     --help
check      "--version"          0 $'md (loup-cmd-md) 0.1.0\n'   --version

# Creating directories prints nothing.
reset; check_both "one directory" 0 '' ''                       new
check_state "one directory" "$(with new/)"
reset; check_both "intermediate directories" 0 '' ''            'a\b\c'
check_state "intermediate directories" "$(with a/ a/b/ a/b/c/)"
reset; check_both "slash separators" 0 '' ''                    a/b/
check_state "slash separators" "$(with a/ a/b/)"
reset; check_both "inside an existing one" 0 '' ''              'old\inner\x'
check_state "inside an existing one" "$(with old/inner/x/)"
reset; check_both "several operands" 0 '' ''                    one 'two\three' "$W/four"
check_state "several operands" "$(with one/ two/ two/three/ four/)"
reset; check_both "dot-dot by name" 0 '' ''                     'q\..\r' '.\s'
check_state "dot-dot by name" "$(with r/ s/)"
reset; check_both "unknown switch is a directory" 0 '' ''       -x
check_state "unknown switch is a directory" "$(with -x/)"
reset; check_both "-- ends switches" 0 '' ''                    -- -y
check_state "-- ends switches" "$(with -y/)"

# Already there: ERRORLEVEL 1, and the other operands are still created.
reset; check_both "existing directory" 1 '' "$(exists old)"$'\n'  old
check_state "existing directory" "$START"
reset; check_both "existing, typed with /" 1 '' "$(exists 'old\inner\')"$'\n' old/inner/
reset; check_both "existing file" 1 '' "$(exists file.txt)"$'\n'  file.txt
check_state "existing file" "$START"
reset; check_both "dangling link" 1 '' "$(exists dangling)"$'\n' dangling
reset; check_both "current directory" 1 '' "$(exists .)"$'\n'    .
reset; check_both "one of several exists" 1 '' \
    "$(exists old)"$'\n'"$(processing old)"$'\n'               new old 'x\y'
check_state "one of several exists" "$(with new/ x/ x/y/)"
reset; check_both "same name twice" 1 '' \
    "$(exists dup)"$'\n'"$(processing dup)"$'\n'               dup dup
check_state "same name twice" "$(with dup/)"
reset; check_both "absolute path shown as typed" 1 '' "$(exists "$WD\\old")"$'\n' "$W/old"

# Other errors.
reset; check_both "no operand"  1 '' $'The syntax of the command is incorrect.\n'
reset; check_both "file on the way" 1 '' "$nopath"$'\n'         'file.txt\sub'
check_state "file on the way" "$START"
reset; check_both "dangling link on the way" 1 '' "$nopath"$'\n' 'dangling\sub'
check_state "dangling link on the way" "$START"
reset; check_both "wildcard"    1 '' "$invalid"$'\n'            'new*'
reset; check_both "question mark" 1 '' "$invalid"$'\n'          'a\b?'
reset; check_both "colon"       1 '' "$invalid"$'\n'            'c:x'
reset; check_both "empty operand" 1 '' "$invalid"$'\n'          ''
reset; check_both "invalid among several" 1 '' \
    "$invalid"$'\n'"$(processing 'b|c')"$'\n'                  a 'b|c'
check_state "invalid among several" "$(with a/)"
if [ "$(id -u)" != 0 ]; then
    reset; chmod a-w old
    check_both "read-only parent" 1 '' $'Access is denied.\n'  'old\x'
    chmod u+w old
    check_state "read-only parent" "$START"
fi

# mkdir is md.
reset; BIN_MD=$BIN; BIN=$(dirname "$BIN")/mkdir
check_both "mkdir"              0 '' ''                         'm\n'
check_state "mkdir" "$(with m/ m/n/)"
check      "mkdir --version"    0 $'md (loup-cmd-md) 0.1.0\n'   --version
BIN=$BIN_MD

echo "e2e: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
