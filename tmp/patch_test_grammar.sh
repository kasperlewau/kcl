#!/usr/bin/env bash
set -euo pipefail

# This script patches test_grammar.py to find the libkcl binary correctly

TEST_FILE="tests/grammar/test_grammar.py"

if [[ ! -f "$TEST_FILE" ]]; then
    echo "Error: $TEST_FILE not found"
    exit 1
fi

# Create backup
cp "$TEST_FILE" "$TEST_FILE.backup"

# Apply the patch - add binary finder function after imports
sed -i '/^# Ruamel YAML instance/i\
\
def _find_libkcl_binary() -> str:\
    """Find the libkcl binary in expected locations"""\
    test_dir = pathlib.Path(__file__).parent\
    repo_root = test_dir.parent.parent\
\
    # Check environment variable first\
    kcl_bin = os.environ.get("KCL_BIN")\
    if kcl_bin and os.path.isfile(kcl_bin):\
        return kcl_bin\
\
    # Search in expected build locations\
    search_paths = [\
        repo_root / "target" / "release" / "libkcl",\
        repo_root / "target" / "debug" / "libkcl",\
        repo_root / "target" / "release" / "kcl",\
        repo_root / "target" / "debug" / "kcl",\
    ]\
\
    for path in search_paths:\
        if path.is_file():\
            return str(path)\
\
    # Fall back to searching in PATH\
    return "libkcl"\
\
\
KCL_BINARY = _find_libkcl_binary()\
' "$TEST_FILE"

# Replace hardcoded "libkcl" with KCL_BINARY variable
sed -i 's/kcl_command = \["libkcl", "run", TEST_FILE\]/kcl_command = [KCL_BINARY, "run", TEST_FILE]/' "$TEST_FILE"

echo "Patched $TEST_FILE successfully"
echo "Backup saved to $TEST_FILE.backup"
