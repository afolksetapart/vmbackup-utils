# vmbackup-utils
Utilities for Victoria Metrics "smart" backups 

## Usage

This script expects you are running Victoria Metrics via Docker, are backing
up to AWS compatible S3, and want to send Slack notifications based on
success or failure.

It also expects a backup type as `$1`, e.g. "hourly" or "monthly",
corresponding to S3_DIR, relative to official vmbackup "smart" backup
instructions.

It has no friendly error handling.

Clone this repo to `/etc`.
