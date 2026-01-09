# Migration to UV - Summary

## Changes Made

### 1. Updated `pyproject.toml`
- Added proper pytest configuration
- Set `pythonpath = ["tests/runtime"]` to allow tests to import `kcl_runtime` module
- Added test discovery patterns

### 2. Updated `Makefile`
- Changed `install-test-deps` to use `uv sync` instead of pip
- Updated `test-runtime` to use `uv run pytest tests/runtime -vv`
- Updated `test-grammar` to use `uv run pytest tests/grammar -n 5` with PATH set to find binaries

### 3. Status
- ✅ Runtime tests: **WORKING** - All tests pass with `make test-runtime`
- ⚠️ Grammar tests: **NEEDS FIX** - Tests can't find `libkcl` binary

## Fix for Grammar Tests

The `tests/grammar/test_grammar.py` file has a hardcoded reference to `libkcl` on line 117:
```python
kcl_command = ["libkcl", "run", TEST_FILE]
```

### Option 1: Run the patch script (Recommended)
```bash
chmod +x tmp/patch_test_grammar.sh
./tmp/patch_test_grammar.sh
```

This will automatically update the test file to search for the binary in the correct locations.

### Option 2: Manual changes to `tests/grammar/test_grammar.py`

Add this function after the imports (around line 20, before the `find_test_dirs` function):

```python
def _find_libkcl_binary() -> str:
    """Find the libkcl binary in expected locations"""
    test_dir = pathlib.Path(__file__).parent
    repo_root = test_dir.parent.parent

    # Check environment variable first
    kcl_bin = os.environ.get("KCL_BIN")
    if kcl_bin and os.path.isfile(kcl_bin):
        return kcl_bin

    # Search in expected build locations
    search_paths = [
        repo_root / "target" / "release" / "libkcl",
        repo_root / "target" / "debug" / "libkcl",
        repo_root / "target" / "release" / "kcl",
        repo_root / "target" / "debug" / "kcl",
    ]

    for path in search_paths:
        if path.is_file():
            return str(path)

    # Fall back to searching in PATH
    return "libkcl"


KCL_BINARY = _find_libkcl_binary()
```

Then change line 117 from:
```python
kcl_command = ["libkcl", "run", TEST_FILE]
```

To:
```python
kcl_command = [KCL_BINARY, "run", TEST_FILE]
```

### Option 3: Use environment variable (Quick test)
```bash
export KCL_BIN="$(pwd)/target/release/libkcl"
make test-grammar
```

## Testing

After applying the fix:
```bash
# Make sure you've built the project first
make build

# Run runtime tests
make test-runtime

# Run grammar tests
make test-grammar

# Or run all tests
make test && make test-runtime && make test-grammar
```

## Package Structure Notes

The following files should be created for proper Python package structure (though not strictly required for pytest):
- `tests/__init__.py`
- `tests/runtime/__init__.py`
- `tests/grammar/__init__.py`

These are optional but follow Python best practices.
