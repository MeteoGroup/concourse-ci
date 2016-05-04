#!/bin/bash

docker run --rm -ti --privileged --entrypoint /concourse-worker.sh \
    --env CONCOURSE_TSA_HOST \
    --env CONCOURSE_TSA_PORT \
    --env CONCOURSE_TSA_PUBKEY \
    --env CONCOURSE_WORKER_KEY \
    "$@" "meteogroup/concourse-ci"
