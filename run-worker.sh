#!/bin/bash

docker run --rm -ti --privileged \
    -v /var/lib/concourse/work --entrypoint /concourse-worker.sh \
    ${CONCOURSE_TSA_HOST:+--env CONCOURSE_TSA_HOST="${CONCOURSE_TSA_HOST}"} \
    ${CONCOURSE_TSA_PORT:+--env CONCOURSE_TSA_PORT="${CONCOURSE_TSA_PORT}"} \
    ${CONCOURSE_TSA_PUBKEY:+--env CONCOURSE_TSA_PUBKEY="${CONCOURSE_TSA_PUBKEY}"} \
    ${CONCOURSE_WORKER_KEY:+--env CONCOURSE_WORKER_KEY="${CONCOURSE_WORKER_KEY}"} \
    "$@" "meteogroup/concourse-ci"
