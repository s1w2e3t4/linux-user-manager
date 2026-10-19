
#!/usr/bin/env bash

set -u

# Project paths
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
REPORT_DIR="$PROJECT_DIR/reports"
LOG_DIR="$PROJECT_DIR/logs"
LOG_FILE="$LOG_DIR/user_manager.log"

# Create required directories
if ! mkdir -p "$REPORT_DIR" "$LOG_DIR"; then
    echo "Error: Could not create project directories."
    exit 1
fi

# Record application actions
log_action() {
    printf '[%s] %s\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG_FILE"
}

# Feature 1: Display current user information
show_user_info() {
    echo
    echo "===== CURRENT USER INFORMATION ====="
    printf 'Username: %s\n' "$(whoami)"
    echo "User and group IDs:"
    id
    printf 'Home directory: %s\n' "$HOME"
    printf 'Current directory: %s\n' "$PWD"
    printf 'Login shell: %s\n' "${SHELL:-Unknown}"
    echo "===================================="

    log_action "Viewed current user information"
}

# Feature 2: Inspect file or directory permissions
inspect_permissions() {
    local target

    echo
    read -r -p "Enter a file or directory path: " target

    if [[ -z "$target" ]]; then
        echo "Error: Path cannot be empty."
        log_action "Permission inspection failed: empty path"
        return
    fi

    if [[ ! -e "$target" && ! -L "$target" ]]; then
        echo "Error: File or directory does not exist."
        log_action "Permission inspection failed: path not found"
        return
    fi

    echo
    echo "===== PERMISSION DETAILS ====="

    if ! stat -c 'Name: %n' -- "$target"; then
        echo "Error: Could not inspect the specified path."
        log_action "Permission inspection failed: stat error"
        return
    fi

    stat -c 'Type: %F' -- "$target"
    stat -c 'Owner: %U' -- "$target"
    stat -c 'Group: %G' -- "$target"
    stat -c 'Permissions: %A (%a)' -- "$target"

    echo "=============================="

    log_action "Inspected file or directory permissions"
}

# Feature 3: Generate a user and group report
generate_report() {
    local report_file

    report_file="$REPORT_DIR/user_report_$(date '+%Y%m%d_%H%M%S').txt"

    if {
        echo "LINUX USER AND GROUP REPORT"
        echo "Generated: $(date)"
        echo
        echo "===== CURRENT USER ====="
        whoami
        id
        echo
        echo "===== SYSTEM USERS AND PRIMARY GROUPS ====="

        getent passwd |
            while IFS=: read -r username _ uid gid _ _ _; do
                printf 'User: %-20s UID: %-8s Primary GID: %s\n' \
                    "$username" "$uid" "$gid"
            done

        echo
        echo "===== CURRENT USER GROUPS ====="
        groups
    } > "$report_file"; then
        echo
        echo "Report generated successfully:"
        echo "$report_file"
        log_action "Generated user and group report"
    else
        echo "Error: Could not generate the report."
        log_action "Report generation failed"
        return 1
    fi
}


# Feature 4: Change file permissions safely
change_permissions() {
    local target mode current_mode confirmation

    echo
    echo "===== CHANGE FILE PERMISSIONS ====="
    read -r -p "Enter a file path: " target

    if [[ -z "$target" ]]; then
        echo "Error: Path cannot be empty."
        return
    fi

    if [[ ! -f "$target" ]]; then
        echo "Error: Please specify an existing regular file."
        log_action "Permission change rejected: invalid file"
        return
    fi

    if [[ ! -O "$target" ]]; then
        echo "Error: You must own the file to change its permissions."
        log_action "Permission change rejected: file not owned by current user"
        return
    fi

    current_mode="$(stat -c '%a' -- "$target")"

    echo "Current permissions: $current_mode"
    echo "Allowed modes: 600, 644, 700, 755"
    read -r -p "Enter the new permission mode: " mode

    case "$mode" in
        600|644|700|755) ;;
        *)
            echo "Error: Unsupported permission mode."
            log_action "Permission change rejected: invalid mode"
            return
            ;;
    esac

    echo
    echo "File: $target"
    echo "Current mode: $current_mode"
    echo "New mode: $mode"
    read -r -p "Apply this change? (yes/no): " confirmation

    if [[ "$confirmation" != "yes" ]]; then
        echo "Permission change cancelled."
        log_action "Permission change cancelled by user"
        return
    fi

    if chmod "$mode" -- "$target"; then
        local new_mode
        new_mode="$(stat -c '%a' -- "$target")"

        if [[ "$new_mode" == "$mode" ]]; then
            echo "Permissions updated successfully: $new_mode"
            log_action "Permission change completed successfully"
        else
            echo "Warning: Permission verification failed."
            log_action "Permission change verification failed"
        fi
    else
        echo "Error: Could not change permissions."
        log_action "Permission change failed"
    fi
}


# Main application menu
while true; do
    echo
    echo "======================================"
    echo " LINUX USER & PERMISSION MANAGER"
    echo "======================================"
    echo "1. View current user information"
    echo "2. Inspect file/directory permissions"
    echo "3. Generate user and group report"
    echo "4. Change file permission"
    echo "5. Exit"
    echo "======================================"

    read -r -p "Choose an option (1-5): " choice || {
        echo
        echo "Input ended. Exiting application."
        log_action "Application stopped: input ended"
        break
    }

    case "$choice" in
        1)
            show_user_info
            ;;
        2)
            inspect_permissions
            ;;
        3)
            generate_report
            ;;

        4)
            change_permissions
            ;;
        5)
            echo "Exiting Linux User Manager. Goodbye!"
            log_action "Exited the application"
            break
            ;;
        *)
            echo "Invalid option. Please enter a number from 1 to 4."
            ;;
    esac
done

