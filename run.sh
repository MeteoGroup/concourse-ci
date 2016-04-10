#!/bin/bash -x

docker run --rm -ti "${@:2}" "meteogroup/concourse-ci" ${@:1:1}
