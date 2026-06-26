#!/bin/bash

source .env
echo "Attemping monthly backup..."

if [ -f "/home/joem_pcw/BACKUP_LOCK" ]; then
        echo "Yikes, monthly backup ran into its own lock!"
        exit 1
fi

touch /home/joem_pcw/BACKUP_LOCK

DOCKER_OUTPUT=$(docker run --rm \
        --env-file /home/joem_pcw/.env \
        -v unpoller-prom_victoria-metrics-data:/victoria-metrics-data \
        --network unpoller-prom_default victoriametrics/vmbackup \
        -storageDataPath=/victoria-metrics-data \
        -snapshot.createURL=http://victoriametrics:8428/snapshot/create \
        -customS3Endpoint=https://us-east-1.linodeobjects.com \
        -dst=s3://unpoller-backups-test/$(date '+%Y%m%d') \
        2>&1)

DOCKER_EXIT_STATUS=$?

if [ $DOCKER_EXIT_STATUS -eq 0 ]; then
        MESSAGE="✅ vmbackup (monthly) ran successfully at $(date -Iseconds)"
else
        MESSAGE="‼️ vmbackup (monthly) failed with status ${DOCKER_EXIT_STATUS} at $(date -Iseconds) \`\`\`${DOCKER_OUTPUT}\`\`\`"
fi

F_MESSAGE=$(jq -n --arg m "$MESSAGE" '{"blocks": [{"type": "section", "text": {"text": $m, "type": "mrkdwn"}}]}')

curl -X POST -H 'Content-type: application/json' --data "$F_MESSAGE" "$SLACK_WEBHOOK"

echo "Monthly backup attempt concluded, removing lock..."

rm /home/joem_pcw/BACKUP_LOCK

echo "Lock removed, be free..."
