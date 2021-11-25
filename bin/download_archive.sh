#!/usr/bin/env bash

# BUCKET=[VALUE] KEY=[VALUE] sh bin/download_archive.sh

filename=$(aws s3api head-object --bucket ${BUCKET} --key ${KEY} | jq -r '.Metadata.filename')

if [[ ${filename} =~ twitter-[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9a-z]{64}\.zip ]]; then
  aws s3 cp s3://${BUCKET}/${KEY} ${filename}
fi
