#!/bin/bash

# https://app.datadoghq.com/account/settings#agent/aws

if [ ! -z ${DD_API_KEY+x} ]; then
  echo "DD_API_KEY is set to ${DD_API_KEY}"
  bash -c "$(curl -L https://raw.githubusercontent.com/DataDog/dd-agent/master/packaging/datadog-agent/source/install_agent.sh)"
else
  echo "DD_API_KEY is unset"
fi

