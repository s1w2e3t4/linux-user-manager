
# Linux User & Permission Manager

A Bash-based Linux administration tool for inspecting user information,
viewing file permissions, generating user/group reports, and changing
selected file permission modes safely.

## Features

- Display current username, user ID, groups, home directory, and shell.
- Inspect file ownership, group, type, and permission modes.
- Generate timestamped user and group reports.
- Change file permissions using approved numeric modes.
- Confirm permission changes before applying them.
- Verify updated permissions after changes.
- Log application actions and errors.
- Run automated tests for core functionality.

## Technologies

- Ubuntu Linux
- Bash scripting
- GNU core utilities (`stat`, `chmod`, `id`)
- Linux account utilities (`whoami`, `getent`, `groups`)
- Shell-based automated testing
- Git and GitHub (for version control and publishing)

## Project Structure

```text
linux-user-manager/
├── scripts/
│   └── user_manager.sh
├── reports/
├── logs/
│   └── user_manager.log
├── tests/
│   ├── test_user_manager.sh
│   └── fixtures/
│       └── sample.txt
└── README.md
```

## Requirements

- Ubuntu Linux or a compatible Linux distribution
- Bash
- GNU `stat` and `chmod`
- Standard Linux account utilities

## Installation

Clone the repository after publishing it on GitHub:

```bash
git clone YOUR_GITHUB_REPOSITORY_URL
cd linux-user-manager
```

Alternatively, if you already have the project locally, navigate
to its directory.

## Run the Application

Make the script executable:

```bash
chmod +x scripts/user_manager.sh
```

Start the application:

```bash
./scripts/user_manager.sh
```

## Menu Options

| Option | Description |
|---|---|
| 1 | View current user information |
| 2 | Inspect file or directory permissions |
| 3 | Generate a user and group report |
| 4 | Change file permissions |
| 5 | Exit |

## Example: Inspect Permissions

```bash
stat -c '%A (%a) %n' tests/fixtures/sample.txt
```

Example output:

```text
-rw-r--r-- (644) tests/fixtures/sample.txt
```

## Example: Change Permissions

The application supports these numeric modes:

| Mode | Description |
|---|---|
| 600 | Owner can read and write |
| 644 | Owner can read and write; others can read |
| 700 | Owner has full permissions |
| 755 | Owner has full permissions; others can read and execute |

The application asks for confirmation and verifies the resulting
permissions.

## Reports and Logs

Generated reports are saved in `reports/`.

Application activity is recorded in:

```text
logs/user_manager.log
```

View the activity log:

```bash
cat logs/user_manager.log
```

## Automated Tests

Run the test suite:

```bash
bash -n scripts/user_manager.sh
bash -n tests/test_user_manager.sh
./tests/test_user_manager.sh
```

The current test suite contains 13 automated checks covering menu
behavior, user information, permission inspection, report generation,
permission changes, cancellation, invalid modes, and directory rejection.

## Safety Notes

- Test permission changes on disposable files first.
- The application restricts permission changes to four predefined modes.
- The permission-changing feature checks that the current user owns
  the target file.
- Avoid running the application with elevated privileges unnecessarily.
- Review file paths carefully before confirming a permission change.

## Future Improvements

- More comprehensive automated tests.
- Improved error handling and permission validation.
- User and group administration with explicit safeguards.
- Better report formatting.
- Continuous integration using GitHub Actions.

## Author

Swetha Shree G S

## License

To be decided before public distribution.
