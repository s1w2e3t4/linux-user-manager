
#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$PROJECT_DIR/scripts/user_manager.sh"

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

PASS_COUNT=0

assert_contains() {
    local output="$1"
    local expected="$2"
    local test_name="$3"

    if grep -Fq -- "$expected" <<< "$output"; then
        printf '[PASS] %s\n' "$test_name"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        printf '[FAIL] %s\n' "$test_name" >&2
        printf 'Expected: %s\n' "$expected" >&2
        exit 1
    fi
}

assert_mode() {
    local file="$1"
    local expected="$2"
    local test_name="$3"
    local actual

    actual="$(stat -c '%a' -- "$file")"

    if [[ "$actual" == "$expected" ]]; then
        printf '[PASS] %s\n' "$test_name"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        printf '[FAIL] %s (expected %s, got %s)\n' \
            "$test_name" "$expected" "$actual" >&2
        exit 1
    fi
}

if [[ ! -x "$APP" ]]; then
    echo "Error: Application is missing or not executable." >&2
    exit 1
fi

# Test 1: Menu
output="$(printf '5\n' | "$APP")"
assert_contains "$output" "LINUX USER & PERMISSION MANAGER" \
    "Application displays its menu"

# Test 2: Current user
output="$(printf '1\n5\n' | "$APP")"
assert_contains "$output" "Username: $(whoami)" \
    "Displays the current username"

# Test 3: Permission inspection
touch "$TEMP_DIR/sample.txt"
chmod 644 "$TEMP_DIR/sample.txt"

output="$(printf '2\n%s\n5\n' "$TEMP_DIR/sample.txt" | "$APP")"
assert_contains "$output" "Permissions: -rw-r--r-- (644)" \
    "Inspects file permissions"

# Test 4: Missing file
output="$(printf '2\n%s\n5\n' "$TEMP_DIR/missing.txt" | "$APP")"
assert_contains "$output" "File or directory does not exist." \
    "Handles a nonexistent path"

# Test 5: Invalid menu selection
output="$(printf '9\n5\n' | "$APP")"
assert_contains "$output" "Invalid option." \
    "Rejects invalid menu selections"

# Test 6: Report generation
output="$(printf '3\n5\n' | "$APP")"
assert_contains "$output" "Report generated successfully:" \
    "Generates a user and group report"

# Test 7: Change permissions successfully
output="$(printf '4\n%s\n600\nyes\n5\n' \
    "$TEMP_DIR/sample.txt" | "$APP")"

assert_contains "$output" "Permissions updated successfully: 600" \
    "Changes permissions after confirmation"
assert_mode "$TEMP_DIR/sample.txt" 600 \
    "Verifies changed permissions on disk"

# Test 8: Cancellation preserves permissions
output="$(printf '4\n%s\n644\nno\n5\n' \
    "$TEMP_DIR/sample.txt" | "$APP")"

assert_contains "$output" "Permission change cancelled." \
    "Allows permission changes to be cancelled"
assert_mode "$TEMP_DIR/sample.txt" 600 \
    "Cancellation preserves existing permissions"

# Test 9: Invalid permission mode
output="$(printf '4\n%s\n777\n5\n' \
    "$TEMP_DIR/sample.txt" | "$APP")"

assert_contains "$output" "Error: Unsupported permission mode." \
    "Rejects unsupported permission modes"
assert_mode "$TEMP_DIR/sample.txt" 600 \
    "Invalid mode leaves permissions unchanged"

# Test 10: Directories cannot be changed by this feature
output="$(printf '4\n%s\n600\n5\n' \
    "$TEMP_DIR" | "$APP")"

assert_contains "$output" \
    "Error: Please specify an existing regular file." \
    "Rejects directory targets"

printf '\nAll %d automated checks passed!\n' "$PASS_COUNT"
