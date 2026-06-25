#!/bin/bash

source .env
echo "Attemping hourly backup..."

if [ -f "/home/joem_pcw/BACKUP_LOCK" ]; then
        echo "Collision with monthly backup, exiting..."
        exit 1
fi

DOCKER_OUTPUT=$(docker run --rm \
        --env-file /home/joem_pcw/.env \
        -v unpoller-prom_victoria-metrics-data:/victoria-metrics-data \
        --network unpoller-prom_default victoriametrics/vmbackup \
        -storageDataPath=/victoria-metrics-data \
        -snapshot.createURL=http://victoriametrics:8428/snapshot/create \
        -customS3Endpoint=https://us-east-1.linodeobjects.com \
        -dst=s3://unpoller-backups-test/latest \
        2>&1)

DOCKER_EXIT_STATUS=$?

if [ $DOCKER_EXIT_STATUS -eq 0 ]; then
        MESSAGE="✅ vmbackup (hourly) ran successfully at $(date -Iseconds)"
else
        MESSAGE="‼️ vmbackup (hourly) failed with status ${DOCKER_EXIT_STATUS} at $(date -Iseconds) \`\`\`${DOCKER_OUTPUT}\`\`\`"
fi

F_MESSAGE=$(jq -n --arg m "$MESSAGE" '{"blocks": [{"type": "section", "text": {"text": $m, "type": "mrkdwn"}}]}')

curl -X POST -H 'Content-type: application/json' --data "$F_MESSAGE" "$SLACK_WEBHOOK"

echo "Hourly backup attempt concluded..."
