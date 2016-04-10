#!/bin/bash -x

docker run -ti --rm -v "$PWD/test-files:/test-files:ro" \
    ${CONCOURSE_USER:+--env "CONCOURSE_USER=$CONCOURSE_USER"} \
    ${CONCOURSE_PASSWORD:+--env "CONCOURSE_PASSWORD=$CONCOURSE_PASSWORD"} \
    ${CONCOURSE_HOST:+--env "CONCOURSE_HOST=$CONCOURSE_HOST"} \
    ${CONCOURSE_PORT:+--env "CONCOURSE_PORT=$CONCOURSE_PORT"} \
    busybox /test-files/setup.sh
