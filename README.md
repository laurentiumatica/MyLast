# mylast.sh & mylastb.sh

Command-line tools for viewing authentication logs and login history.

## NAME

**mylast.sh** - show listing of last logged in users  
**mylastb.sh** - show listing of failed login attempts

## SYNOPSIS

```bash
mylast.sh [-s since_date] [-t until_date] [-p at_date] [-n num_sessions] [file]
mylastb.sh [-s since_date] [-t until_date] [-p at_date] [-n num_sessions] [file]
```

## DESCRIPTION

`mylast.sh` searches through the authentication log file (or the file designated by the file argument) and displays a list of all users logged in (and out) since that file was created. 

`mylastb.sh` is the same as `mylast.sh`, except that by default it shows a log of failed login attempts.

## INSTALLATION

After downloading the scripts, you need to make them executable:

```bash
chmod +x mylast.sh
chmod +x mylastb.sh
```

Optionally, move them to a directory in your PATH:

```bash
sudo mv mylast.sh mylastb.sh /usr/local/bin/
```

## OPTIONS

| Option | Description |
|--------|-------------|
| `-s since_date` | Display sessions that started at or after `since_date`. The date can be specified in various formats recognized by `date(1)`, such as `"2026-01-10 10:00"` or `"yesterday"`. |
| `-t until_date` | Display sessions that started at or before `until_date`. The date can be specified in various formats recognized by `date(1)`. |
| `-p at_date` | Display sessions that were active at the specified date/time. For completed sessions, checks if the time falls within the session duration. For active sessions, checks if the session started before the specified time. |
| `-n num_sessions` | Limit the output to the specified number of most recent sessions. |
| `file` | Specifies the authentication log file to read. If not specified, defaults to `/var/log/auth.log` and archived files `/var/log/auth.log.{1-4}` including compressed `.gz` archives. |

## OUTPUT FORMAT

### mylast.sh
Each line of output contains the following fields:
- Username (8 characters)
- Terminal (12 characters)
- IP address (16 characters)
- Login time (day, month, date, time)
- Logout time or "still logged in"
- Session duration in format `(HH:MM)` or `(days+HH:MM)`

### mylastb.sh
Each line contains:
- Username (8 characters)
- Terminal (12 characters)
- IP address (16 characters)
- Attempt time (day, month, date, time)
- End time
- Duration (always `(00:00)` for failed attempts)

## FILES

| File | Description |
|------|-------------|
| `/var/log/auth.log` | Default authentication log file |
| `/var/log/auth.log.{1,2,3,4}` | Rotated authentication log files |
| `/var/log/auth.log.{1,2,3,4}.gz` | Compressed authentication log archives |

## EXAMPLES

```bash
# Display all login sessions from default log files
mylast.sh

# Display the 10 most recent login sessions
mylast.sh -n 10

# Display sessions that started between 8 AM and 6 PM on January 10, 2026
mylast.sh -s "2026-01-10 08:00" -t "2026-01-10 18:00"

# Display all sessions that were active at noon on January 10, 2026
mylast.sh -p "2026-01-10 12:00"

# Display sessions from a specific log file
mylast.sh auth.log.sample

# Display sessions from a compressed archive (automatically decompressed)
mylast.sh auth.log.1.gz

# Display the 20 most recent failed login attempts
mylastb.sh -n 20

# Display failed login attempts since midnight on January 9, 2026
mylastb.sh -s "2026-01-09 00:00"
```

## NOTES

- The scripts require `sudo` to read authentication log files or granted read permission
- Compressed `.gz` files are automatically decompressed transparently
- Sessions without a logout event are marked as "still logged in"
- Multiple concurrent sessions from the same user are distinguished by unique TTY identifiers (`pts/0`, `pts/1`, etc.)
- IP addresses missing from LOGIN events are recovered through PID correlation with corresponding ACCEPTED events

## EXIT STATUS

| Code | Description |
|------|-------------|
| `0` | Success |
| `1` | Invalid arguments, file not found, or other error |
