#!/bin/bash

docker run --rm -ti --entrypoint /concourse-web.sh \
    --env CONCOURSE_URL \
    --env CONCOURSE_LOGIN \
    --env CONCOURSE_PASSWORD \
    --env CONCOURSE_GITHUB_AUTH_CLIENT_ID \
    --env CONCOURSE_GITHUB_AUTH_CLIENT_SECRET \
    --env CONCOURSE_GITHUB_AUTH_ORGANIZATION \
    --env CONCOURSE_GITHUB_AUTH_TEAM \
    --env CONCOURSE_GITHUB_AUTH_USER \
    --env CONCOURSE_PUBLICLY_VIEWABLE \
    --env CONCOURSE_WORKER_PUBKEY \
    --env CONCOURSE_DATA_SOURCE \
    "$@" "meteogroup/concourse-ci"
