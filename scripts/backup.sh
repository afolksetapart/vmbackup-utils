#!/bin/bash

source /etc/vmbackup-utils/.env

BACKUP_TYPE=$1

if [ $BACKUP_TYPE = "hourly" ]; then
       TYPE_DIR="latest"
else
       TYPE_DIR=$(date '+%Y%m%d')
fi

echo "Attemping $BACKUP_TYPE vmbackup..."

exec 9>/etc/vmbackup-utils/vmbackup_lockfile
if ! flock -n 9; then
        echo "Could not acquire lock on vmbackup_lockfile, exiting..."
        exit 1
fi

DOCKER_OUTPUT=$(docker run --rm \
        --env-file /etc/vmbackup-utils/.env \
        -v $VMBACKUP_VOLUME:$VMBACKUP_STORAGE_DATA_PATH \
        --network $DOCKER_NETWORK victoriametrics/vmbackup \
        -storageDataPath=$VMBACKUP_STORAGE_DATA_PATH \
        -snapshot.createURL=$VMBACKUP_CREATE_URL \
        -customS3Endpoint=$S3_ENDPOINT \
        -dst=$S3_DIR/$TYPE_DIR \
        2>&1)

DOCKER_EXIT_STATUS=$?

if [ $DOCKER_EXIT_STATUS -eq 0 ]; then
        MESSAGE="✅ vmbackup ($BACKUP_TYPE) ran successfully at $(date -Iseconds)"
else
        MESSAGE="‼️ vmbackup ($BACKUP_TYPE) failed with status ${DOCKER_EXIT_STATUS} at $(date -Iseconds) \`\`\`${DOCKER_OUTPUT}\`\`\`"
fi

F_MESSAGE=$(jq -n --arg m "$MESSAGE" '{"blocks": [{"type": "section", "text": {"text": $m, "type": "mrkdwn"}}]}')

curl -X POST -H 'Content-type: application/json' --data "$F_MESSAGE" "$SLACK_WEBHOOK"

echo "$BACKUP_TYPE backup attempt concluded..."
