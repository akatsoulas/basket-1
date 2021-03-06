#!/bin/bash
# Needs DEIS_PROFILE, DEIS_APPLICATION, NEWRELIC_API_KEY and
# NEWRELIC_APP_NAME environment variables.
#
# To set them go to Job -> Configure -> Build Environment -> Inject
# passwords and Inject env variables
#

set -ex

BIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $BIN_DIR/set_git_env_vars.sh

DEIS_BIN="${DEIS_BIN:-deis}"

$DEIS_BIN pull "$DOCKER_IMAGE_TAG" -a $DEIS_APPLICATION
if [[ -n "$NEWRELIC_API_KEY" ]]; then
    curl -H "x-api-key:$NEWRELIC_API_KEY" \
         -d "deployment[app_name]=$NEWRELIC_APP_NAME" \
         -d "deployment[revision]=$GIT_COMMIT" \
         -d "deployment[user]=EE Jenkins" \
         https://api.newrelic.com/deployments.xml
fi

if [[ "$RUN_POST_DEPLOY" == 'true' ]]; then
    $DEIS_BIN run -a "$DEIS_APPLICATION" -- bin/post-deploy.sh
fi
