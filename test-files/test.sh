#!/bin/sh -x
#
# Copyright 2016 MeteoGroup Deutschland GmbH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

cd "$HOME"

PIPELINE_NAME="`mktemp -u hello-test-XXXXXXXX`"
echo '--- Pipeline for test: `'"$PIPELINE_NAME"'`.'

echo '--- Log in:'
fly -tt login --username "$CONCOURSE_USER" --password "$CONCOURSE_PASSWORD" --concourse-url "$CONCOURSE_URL" || exit
echo '=== Ok.'
echo

echo '--- Setup pipeline:'
fly -tt set-pipeline --non-interactive --config /test-files/hello.yaml --pipeline "$PIPELINE_NAME" || exit
echo '=== Ok.'
echo

echo '--- Unpause pipeline:'
fly -tt unpause-pipeline --pipeline "$PIPELINE_NAME" || exit
echo '=== Ok.'
echo

echo '--- Trigger:'
fly -tt trigger-job --job "$PIPELINE_NAME/hello-world" || exit
echo '=== Ok.'
echo

echo '--- Watch:'
fly -tt watch --job "$PIPELINE_NAME/hello-world" | tee ~/job-output || exit
echo '=== Ok.'
echo

echo '--- Destroy pipeline:'
fly -tt destroy-pipeline --non-interactive --pipeline "$PIPELINE_NAME" || exit
echo '=== Ok.'
echo

echo '--- Verify pipeline output:'
tail -n2 ~/job-output > ~/job-output.tail || exit
printf "Hello, world!\r\r\nsucceeded\n" | diff -u /dev/stdin ~/job-output.tail || exit
echo '=== Ok.'
echo
