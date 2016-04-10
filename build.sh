#!/bin/bash -x

docker build --pull -t "${1:-meteogroup/concourse-ci}" .
